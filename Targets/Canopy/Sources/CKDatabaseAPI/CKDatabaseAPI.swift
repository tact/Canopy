import CanopyTypes
import CloudKit
import Foundation
import os.log
import Semaphore

actor CKDatabaseAPI: CKDatabaseAPIType {
  private let database: CKDatabaseType
  private let databaseScope: CKDatabase.Scope
  internal let settingsProvider: () async -> CanopySettingsType
  private let tokenStore: TokenStoreType
  private let fetchDatabaseChangesSemaphore = AsyncSemaphore(value: 1)
  private let fetchZoneChangesSemaphore = AsyncSemaphore(value: 1)
  private let logger = Logger(subsystem: "Canopy", category: "CloudKitSyncAPI")

  init(
    database: CKDatabaseType,
    databaseScope: CKDatabase.Scope,
    settingsProvider: @escaping @Sendable () async -> CanopySettingsType = { CanopySettings() },
    tokenStore: TokenStoreType
  ) {
    self.database = database
    self.databaseScope = databaseScope
    self.settingsProvider = settingsProvider
    self.tokenStore = tokenStore
  }
  
  func modifyRecords(
    saving recordsToSave: [CKRecord]?,
    deleting recordIDsToDelete: [CKRecord.ID]?,
    perRecordProgressBlock: PerRecordProgressBlock?,
    qos: QualityOfService
  ) async -> Result<ModifyRecordsResult, CKRecordError> {
    let settings = await settingsProvider()
    let modifyRecordsBehavior = await settings.modifyRecordsBehavior
    switch modifyRecordsBehavior {
    case let .regular(delay):
      if let delay {
        try? await Task.sleep(nanoseconds: UInt64(delay * Double(NSEC_PER_SEC)))
      }
    case let .simulatedFail(delay), let .simulatedFailWithPartialErrors(delay):
      if let delay {
        try? await Task.sleep(nanoseconds: UInt64(delay * Double(NSEC_PER_SEC)))
      }
      
      let includePartialErrors: Bool
      if case .simulatedFailWithPartialErrors = modifyRecordsBehavior {
        includePartialErrors = true
      } else {
        includePartialErrors = false
      }
      
      return .failure(
        randomCKRecordError(
          codes: CKRecordError.retriableErrors,
          saving: recordsToSave,
          deleting: recordIDsToDelete,
          includePartialErrors: includePartialErrors
        )
      )
    }
    
    return await ModifyRecords.with(
      recordsToSave: recordsToSave,
      recordIDsToDelete: recordIDsToDelete,
      perRecordProgressBlock: perRecordProgressBlock,
      database: database,
      qualityOfService: qos,
      autoBatchToSmallerWhenLimitExceeded: settings.autoBatchTooLargeModifyOperations,
      autoRetryForRetriableErrors: settings.autoRetryForRetriableErrors
    )
  }

  func queryRecords(
    with query: CKQuery,
    in zoneID: CKRecordZone.ID?,
    resultsLimit: Int?,
    qos: QualityOfService
  ) async -> Result<[CKRecord], CKRecordError> {
    await QueryRecords.with(
      query,
      recordZoneID: zoneID,
      database: database,
      resultsLimit: resultsLimit,
      qualityOfService: qos
    )
  }
  
  func deleteRecords(
    with query: CKQuery,
    in zoneID: CKRecordZone.ID?,
    qos: QualityOfService
  ) async -> Result<ModifyRecordsResult, CKRecordError> {
    let recordsResult = await QueryRecords.with(
      query,
      recordZoneID: zoneID,
      database: database,
      desiredKeys: [],
      qualityOfService: qos
    )
    
    switch recordsResult {
    case let .success(records):
      guard !records.isEmpty else {
        return .success(.init(savedRecords: [], deletedRecordIDs: []))
      }
      
      let recordIDs = records.map(\.recordID)
      return await modifyRecords(
        saving: nil,
        deleting: recordIDs,
        perRecordProgressBlock: nil,
        qualityOfService: qos
      )
    case let .failure(error):
      return .failure(error)
    }
  }

  func fetchRecords(
    with recordIDs: [CKRecord.ID],
    desiredKeys: [CKRecord.FieldKey]?,
    perRecordIDProgressBlock: PerRecordIDProgressBlock?,
    qos: QualityOfService
  ) async -> Result<FetchRecordsResult, CKRecordError> {
    await withCheckedContinuation { continuation in
      var foundRecords: [CKRecord] = []
      var notFoundRecordIDs: [CKRecord.ID] = []
      var recordError: CKRecordError?

      let fetchRecordsOperation = CKFetchRecordsOperation(recordIDs: recordIDs)
      fetchRecordsOperation.perRecordProgressBlock = perRecordIDProgressBlock
      fetchRecordsOperation.qualityOfService = qos
      fetchRecordsOperation.desiredKeys = desiredKeys

      fetchRecordsOperation.perRecordResultBlock = { recordId, result in
        switch result {
        case let .failure(error):
          if let error = error as? CKError, error.code == .unknownItem {
            // The query otherwise succeeded, but the record was not found based on the ID.
            // Note it as such.
            notFoundRecordIDs.append(recordId)
          } else {
            // There was another kind of error. This will fail the whole request.
            recordError = .init(from: error)
          }
        case let .success(record):
          foundRecords.append(record)
        }
      }
      
      fetchRecordsOperation.fetchRecordsResultBlock = { result in
        switch result {
        case .success:
          if let recordError {
            // Consider the fetch failed if fetching at least one record failed
            continuation.resume(returning: .failure(recordError))
          } else {
            continuation.resume(
              returning: .success(
                .init(
                  foundRecords: foundRecords,
                  notFoundRecordIDs: notFoundRecordIDs
                )
              )
            )
          }
        case let .failure(error):
          continuation.resume(returning: .failure(.init(from: error)))
        }
      }
      
      database.add(fetchRecordsOperation)
    }
  }

  func modifyZones(
    saving recordZonesToSave: [CKRecordZone]?,
    deleting recordZoneIDsToDelete: [CKRecordZone.ID]?,
    qos: QualityOfService
  ) async -> Result<ModifyZonesResult, CKRecordZoneError> {
    await withCheckedContinuation { continuation in
      let zoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: recordZonesToSave, recordZoneIDsToDelete: recordZoneIDsToDelete)
      zoneOperation.qualityOfService = qos
      
      var savedZones: [CKRecordZone] = []
      var deletedZoneIDs: [CKRecordZone.ID] = []
      var recordZoneError: CKRecordZoneError?
      
      zoneOperation.perRecordZoneSaveBlock = { _, result in
        switch result {
        case let .failure(error):
          recordZoneError = CKRecordZoneError(from: error)
        case let .success(zone):
          savedZones.append(zone)
        }
      }
      
      zoneOperation.perRecordZoneDeleteBlock = { zoneId, result in
        switch result {
        case let .failure(error):
          recordZoneError = CKRecordZoneError(from: error)
        case .success:
          deletedZoneIDs.append(zoneId)
        }
      }
      
      zoneOperation.modifyRecordZonesResultBlock = { result in
        switch result {
        case let .failure(error):
          continuation.resume(returning: .failure(CKRecordZoneError(from: error)))
        case .success:
          if let recordZoneError {
            // Consider whole operation failed if at least one modification or deletion failed
            // Return the first error indicating the failure
            continuation.resume(returning: .failure(recordZoneError))
          } else {
            continuation.resume(returning: .success(.init(savedZones: savedZones, deletedZoneIDs: deletedZoneIDs)))
          }
        }
      }
            
      database.add(zoneOperation)
    }
  }

  private enum FetchZonesType {
    case allZones
    case zoneIDs([CKRecordZone.ID])
  }
  
  func fetchZones(
    with recordZoneIDs: [CKRecordZone.ID], qos: QualityOfService
  ) async -> Result<[CKRecordZone], CKRecordZoneError> {
    await fetchZones(type: .zoneIDs(recordZoneIDs), qualityOfService: qos)
  }
  
  func fetchAllZones(
    qos: QualityOfService
  ) async -> Result<[CKRecordZone], CKRecordZoneError> {
    await fetchZones(type: .allZones, qualityOfService: qos)
  }

  private func fetchZones(
    type: FetchZonesType, qualityOfService: QualityOfService
  ) async -> Result<[CKRecordZone], CKRecordZoneError> {
    await withCheckedContinuation { continuation in
      let zoneOperation: CKFetchRecordZonesOperation
      switch type {
      case .allZones:
        zoneOperation = CKFetchRecordZonesOperation.fetchAllRecordZonesOperation()
      case let .zoneIDs(zoneIDs):
        zoneOperation = CKFetchRecordZonesOperation(recordZoneIDs: zoneIDs)
      }
      zoneOperation.qualityOfService = qualityOfService
      
      var zones: [CKRecordZone] = []
      var recordZoneError: CKRecordZoneError?
      
      zoneOperation.perRecordZoneResultBlock = { _, result in
        switch result {
        case let .success(zone):
          zones.append(zone)
        case let .failure(error):
          recordZoneError = CKRecordZoneError(from: error)
        }
      }
      
      zoneOperation.fetchRecordZonesResultBlock = { result in
        switch result {
        case .success:
          // if there was at least one error, treat the whole fetch as failed
          if let recordZoneError {
            continuation.resume(returning: .failure(recordZoneError))
          } else {
            continuation.resume(returning: .success(zones))
          }
        case let .failure(error):
          continuation.resume(returning: .failure(CKRecordZoneError(from: error)))
        }
      }
      
      database.add(zoneOperation)
    }
  }
  
  func modifySubscriptions(
    saving subscriptionsToSave: [CKSubscription]?,
    deleting subscriptionIDsToDelete: [CKSubscription.ID]?,
    qos: QualityOfService
  ) async -> Result<ModifySubscriptionsResult, CKSubscriptionError> {
    await withCheckedContinuation { continuation in
      let subscriptionOperation = CKModifySubscriptionsOperation(subscriptionsToSave: subscriptionsToSave, subscriptionIDsToDelete: subscriptionIDsToDelete)
      subscriptionOperation.qualityOfService = qos
      
      var savedSubscriptions: [CKSubscription] = []
      var deletedSubscriptionIDs: [CKSubscription.ID] = []
      var subscriptionError: CKSubscriptionError?
            
      subscriptionOperation.perSubscriptionSaveBlock = { _, result in
        switch result {
        case let .failure(error):
          subscriptionError = CKSubscriptionError(from: error)
        case let .success(subscription):
          savedSubscriptions.append(subscription)
        }
      }
      
      subscriptionOperation.perSubscriptionDeleteBlock = { subscriptionId, result in
        switch result {
        case let .failure(error):
          subscriptionError = CKSubscriptionError(from: error)
        case .success:
          deletedSubscriptionIDs.append(subscriptionId)
        }
      }
      
      subscriptionOperation.modifySubscriptionsResultBlock = { result in
        switch result {
        case let .failure(error):
          continuation.resume(returning: .failure(CKSubscriptionError(from: error)))
        case .success:
          if let subscriptionError {
            // Fail the whole operation if one request failed
            continuation.resume(returning: .failure(subscriptionError))
          } else {
            continuation.resume(
              returning: .success(
                .init(
                  savedSubscriptions: savedSubscriptions,
                  deletedSubscriptionIDs: deletedSubscriptionIDs
                )
              )
            )
          }
        }
      }
      database.add(subscriptionOperation)
    }
  }

  func fetchDatabaseChanges(
    qos: QualityOfService
  ) async -> Result<FetchDatabaseChangesResult, CanopyError> {
    await fetchDatabaseChangesSemaphore.wait()
    defer { fetchDatabaseChangesSemaphore.signal() }
    
    let databaseScope = self.databaseScope
    let fetchDatabaseChangesBehavior = await settingsProvider().fetchDatabaseChangesBehavior
    switch fetchDatabaseChangesBehavior {
    case let .regular(delay):
      if let delay {
        try? await Task.sleep(nanoseconds: UInt64(delay * Double(NSEC_PER_SEC)))
        break
      }
    case let .simulatedFail(delay), let .simulatedFailWithPartialErrors(delay):
      if let delay {
        try? await Task.sleep(nanoseconds: UInt64(delay * Double(NSEC_PER_SEC)))
      }
      return .failure(
        CanopyError.ckRequestError(
          randomCKRequestError(
            codes: CKRequestError.retriableErrors
          )
        )
      )
    }
    
    let database = database
    let tokenStore = tokenStore
    let token = await tokenStore.tokenForDatabaseScope(databaseScope)

    return await withCheckedContinuation { continuation in
      var changedRecordZoneIDs: [CKRecordZone.ID] = []
      var deletedRecordZoneIDs: [CKRecordZone.ID] = []
      var purgedRecordZoneIDs: [CKRecordZone.ID] = []
      
      let changesOperation = CKFetchDatabaseChangesOperation(previousServerChangeToken: token)
      changesOperation.qualityOfService = qos
      changesOperation.fetchAllChanges = true
      
      changesOperation.recordZoneWithIDChangedBlock = { recordZoneID in
        changedRecordZoneIDs.append(recordZoneID)
      }

      changesOperation.recordZoneWithIDWasDeletedBlock = { recordZoneID in
        // This currently doesn’t delete the locally stored server change token
        // for this zone. Should it do that?
        // Feels like keeping the token around is more correct.
        deletedRecordZoneIDs.append(recordZoneID)
      }

      changesOperation.recordZoneWithIDWasPurgedBlock = { recordZoneID in
        purgedRecordZoneIDs.append(recordZoneID)
      }

      changesOperation.fetchDatabaseChangesResultBlock = { result in
        switch result {
        case let .failure(error):
          let requestError = CanopyError(from: error)
          if requestError == .ckChangeTokenExpired {
            // As per documentation if we get this error we should delete our cached token.
            // From CK header: “If the server returns a `CKError.changeTokenExpired` error,
            // the `previousServerChangeToken` value was too old and the client
            // should toss its local cache and re-fetch the changes in this record zone
            // starting with a nil `previousServerChangeToken`.
            //
            // We don’t re-run the operation automatically, because the caller may also
            // want to clear or change its local state in this case.
            Task {
              await tokenStore.storeToken(nil, forDatabaseScope: databaseScope)
              continuation.resume(returning: .failure(requestError))
            }
          } else {
            continuation.resume(returning: .failure(requestError))
          }
        case let .success((token, _)):
          // We assume moreComing to be false, because we specified fetchAllChanges = true above.
          Task { [changedRecordZoneIDs, deletedRecordZoneIDs, purgedRecordZoneIDs] in
            await tokenStore.storeToken(token, forDatabaseScope: databaseScope)
            continuation.resume(
              returning: .success(
                .init(
                  changedRecordZoneIDs: changedRecordZoneIDs,
                  deletedRecordZoneIDs: deletedRecordZoneIDs,
                  purgedRecordZoneIDs: purgedRecordZoneIDs
                )
              )
            )
          }
        }
      }
      database.add(changesOperation)
    }
  }

  func fetchZoneChanges(
    recordZoneIDs: [CKRecordZone.ID],
    fetchMethod: FetchZoneChangesMethod,
    qos: QualityOfService
  ) async -> Result<FetchZoneChangesResult, CanopyError> {
    await fetchZoneChangesSemaphore.wait()
    defer { fetchZoneChangesSemaphore.signal() }
    
    let fetchZoneChangesBehavior = await settingsProvider().fetchZoneChangesBehavior
    switch fetchZoneChangesBehavior {
    case let .regular(delay):
      if let delay {
        try? await Task.sleep(nanoseconds: UInt64(delay * Double(NSEC_PER_SEC)))
        break
      }
    case let .simulatedFail(delay), let .simulatedFailWithPartialErrors(delay):
      if let delay {
        try? await Task.sleep(nanoseconds: UInt64(delay * Double(NSEC_PER_SEC)))
      }
      return .failure(
        CanopyError.ckRequestError(
          randomCKRequestError(
            codes: CKRequestError.retriableErrors
          )
        )
      )
    }

    let db = database
    let tokenStore = tokenStore

    typealias ZoneConfiguration = CKFetchRecordZoneChangesOperation.ZoneConfiguration

    let configurations = await withTaskGroup(
      of: (CKRecordZone.ID, ZoneConfiguration).self,
      returning: [CKRecordZone.ID: ZoneConfiguration].self
    ) { group in
      
      for zoneID in recordZoneIDs {
        group.addTask {
          let token = await tokenStore.tokenForRecordZoneID(zoneID)
          return (
            zoneID,
            ZoneConfiguration(
              previousServerChangeToken: token,
              resultsLimit: nil,
              desiredKeys: fetchMethod.desiredKeys
            )
          )
        }
      }
      
      var results: [CKRecordZone.ID: ZoneConfiguration] = [:]
      for await result in group {
        results[result.0] = result.1
      }
      return results
    }
        
    return await withCheckedContinuation { continuation in

      var records: [CKRecord] = []
      var deleted: [DeletedCKRecord] = []
      var recordError: CKRecordError?
      var zoneError: CKRecordZoneError?
      var zoneTokens: [CKRecordZone.ID: CKServerChangeToken] = [:]
      var zoneIDWithExpiredToken: CKRecordZone.ID?
      
      let changesOperation = CKFetchRecordZoneChangesOperation(recordZoneIDs: recordZoneIDs, configurationsByRecordZoneID: configurations)
      changesOperation.qualityOfService = qos
      changesOperation.fetchAllChanges = true // will send repeated requests until all changes fetched
      
      changesOperation.recordWasChangedBlock = { _, result in
        switch result {
        case let .failure(error):
          recordError = CKRecordError(from: error)
        case let .success(record):
          // Save some memory if we are only fetching tokens, since we won’t use the results in that case
          records.append(record)
        }
      }

      changesOperation.recordWithIDWasDeletedBlock = { recordID, recordType in
        deleted.append(DeletedCKRecord(recordID: recordID, recordType: recordType))
      }

      changesOperation.recordZoneFetchResultBlock = { zoneID, result in
        switch result {
        case let .failure(error):
          if zoneError == nil {
            // If a zone error isn’t already captured, capture and run the error handling logic.
            
            // As per documentation if we get this error we shoudl delete our cached token
            if let ckError = error as? CKError, ckError.code == .changeTokenExpired {
              zoneIDWithExpiredToken = zoneID
            }
            zoneError = CKRecordZoneError(from: error)
          }
        case let .success((serverChangeToken, _, _)):
          zoneTokens[zoneID] = serverChangeToken
        }
      }
      
      changesOperation.fetchRecordZoneChangesResultBlock = { result in
        switch result {
        case let .failure(error):
          continuation.resume(returning: .failure(CanopyError(from: error)))
        case .success:
          if let recordError {
            // There was an error with one of the records. Return it as error, failing the whole operation.
            continuation.resume(returning: .failure(.ckRecordError(recordError)))
          } else if let zoneError {
            // There was an error with one of the zones. Return it as error, failing the whole operation.
            Task { [zoneIDWithExpiredToken] in
              if let zoneIDWithExpiredToken {
                await tokenStore.storeToken(nil, forRecordZoneID: zoneIDWithExpiredToken)
              }
              continuation.resume(returning: .failure(.ckRecordZoneError(zoneError)))
            }
          } else {
            // No errors. Store the updated tokens and return results.
            Task { [zoneTokens, records, deleted] in
              for (zoneID, token) in zoneTokens {
                await tokenStore.storeToken(token, forRecordZoneID: zoneID)
              }
              switch fetchMethod {
              case .changeTokenOnly:
                continuation.resume(returning: .success(FetchZoneChangesResult.empty))
              case .changeTokenAndAllData, .changeTokenAndSpecificKeys:
                continuation.resume(
                  returning: .success(
                    .init(
                      records: records,
                      deletedRecords: deleted
                    )
                  )
                )
              }
            }
          }
        }
      }
      db.add(changesOperation)
    }
  }
}
