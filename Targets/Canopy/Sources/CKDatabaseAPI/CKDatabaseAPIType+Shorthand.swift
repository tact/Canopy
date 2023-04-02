import CloudKit

/// Shorthand versions of the functions with default parameter values.
public extension CKDatabaseAPIType {
  func fetchRecords(
    with recordIDs: [CKRecord.ID],
    desiredKeys: [CKRecord.FieldKey]? = nil,
    perRecordIDProgressBlock: PerRecordIDProgressBlock? = nil,
    qualityOfService: QualityOfService = .default
  ) async -> Result<FetchRecordsResult, CKRecordError> {
    await fetchRecords(
      with: recordIDs,
      desiredKeys: desiredKeys,
      perRecordIDProgressBlock: perRecordIDProgressBlock,
      qualityOfService: qualityOfService
    )
  }
  
  func queryRecords(
    with query: CKQuery,
    in zoneID: CKRecordZone.ID?,
    qualityOfService: QualityOfService = .default
  ) async -> Result<[CKRecord], CKRecordError> {
    await queryRecords(
      with: query,
      in: zoneID,
      qualityOfService: qualityOfService
    )
  }
  
  func modifyRecords(
    saving recordsToSave: [CKRecord]? = nil,
    deleting recordIDsToDelete: [CKRecord.ID]? = nil,
    perRecordProgressBlock: PerRecordProgressBlock? = nil,
    qualityOfService: QualityOfService = .default
  ) async -> Result<ModifyRecordsResult, CKRecordError> {
    await modifyRecords(
      saving: recordsToSave,
      deleting: recordIDsToDelete,
      perRecordProgressBlock: perRecordProgressBlock,
      qualityOfService: qualityOfService
    )
  }
  
  func deleteRecords(
    with query: CKQuery,
    in zoneID: CKRecordZone.ID?,
    qualityOfService: QualityOfService = .default
  ) async -> Result<ModifyRecordsResult, CKRecordError> {
    await deleteRecords(
      with: query,
      in: zoneID,
      qualityOfService: qualityOfService
    )
  }

  func modifyZones(
    saving recordZonesToSave: [CKRecordZone]? = nil,
    deleting recordZoneIDsToDelete: [CKRecordZone.ID]? = nil,
    qualityOfService: QualityOfService = .default
  ) async -> Result<ModifyZonesResult, CKRecordZoneError> {
    await modifyZones(
      saving: recordZonesToSave,
      deleting: recordZoneIDsToDelete,
      qualityOfService: qualityOfService
    )
  }

  func fetchZones(
    with recordZoneIDs: [CKRecordZone.ID],
    qualityOfService: QualityOfService = .default
  ) async -> Result<[CKRecordZone], CKRecordZoneError> {
    await fetchZones(
      with: recordZoneIDs,
      qualityOfService: qualityOfService
    )
  }
  
  func fetchAllZones(
    qualityOfService: QualityOfService = .default
  ) async -> Result<[CKRecordZone], CKRecordZoneError> {
    await fetchAllZones(qualityOfService: qualityOfService)
  }
  
  func modifySubscriptions(
    saving subscriptionsToSave: [CKSubscription]? = nil,
    deleting subscriptionIDsToDelete: [CKSubscription.ID]? = nil,
    qualityOfService: QualityOfService = .default
  ) async -> Result<ModifySubscriptionsResult, CKSubscriptionError> {
    await modifySubscriptions(
      saving: subscriptionsToSave,
      deleting: subscriptionIDsToDelete,
      qualityOfService: qualityOfService
    )
  }
  
  func fetchDatabaseChanges(
    qualityOfService: QualityOfService = .default
  ) async -> Result<FetchDatabaseChangesResult, CanopyError> {
    await fetchDatabaseChanges(qualityOfService: qualityOfService)
  }

  func fetchZoneChanges(
    recordZoneIDs: [CKRecordZone.ID],
    fetchMethod: FetchZoneChangesMethod = .changeTokenAndAllData,
    qualityOfService: QualityOfService = .default
  ) async -> Result<FetchZoneChangesResult, CanopyError> {
    await fetchZoneChanges(
      recordZoneIDs: recordZoneIDs,
      fetchMethod: fetchMethod,
      qualityOfService: qualityOfService
    )
  }
}
