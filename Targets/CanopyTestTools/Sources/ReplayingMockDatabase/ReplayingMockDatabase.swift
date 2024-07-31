import CanopyTypes
import CloudKit

public actor ReplayingMockDatabase: Codable, Sendable {
  public enum OperationResult: Codable, Sendable {
    case queryRecords(QueryRecordsOperationResult)
    case modifyRecords(ModifyRecordsOperationResult)
    case deleteRecords(ModifyRecordsOperationResult)
    case fetchRecords(FetchRecordsOperationResult)
  }
  
  private var operationResults: [OperationResult]
  
  /// How many operations were tun in this container.
  public private(set) var operationsRun = 0
  
  public init(
    operationResults: [OperationResult] = []
  ) {
    self.operationResults = operationResults
  }
}

extension ReplayingMockDatabase: CKDatabaseAPIType {
  public func queryRecords(
    with query: CKQuery,
    in zoneID: CKRecordZone.ID?,
    resultsLimit: Int?,
    qos: QualityOfService
  ) async -> Result<[CanopyResultRecord], CKRecordError> {
    let operationResult = operationResults.removeFirst()
    guard case let .queryRecords(result) = operationResult else {
      fatalError("Asked to query records without an available result or invalid result type. Likely a logic error on caller side")
    }
    operationsRun += 1
    switch result.result {
    case .success(let records):
      return .success(records)
    case .failure(let e):
      return .failure(e)
    }
  }
  
  public func modifyRecords(
    saving recordsToSave: [CKRecord]?,
    deleting recordIDsToDelete: [CKRecord.ID]?,
    perRecordProgressBlock: PerRecordProgressBlock?,
    qos: QualityOfService
  ) async -> Result<ModifyRecordsResult, CKRecordError> {
    let operationResult = operationResults.removeFirst()
    guard case let .modifyRecords(result) = operationResult else {
      fatalError("Asked to modify records without an available result or invalid result type. Likely a logic error on caller side")
    }
    operationsRun += 1
    switch result.result {
    case .success(let records):
      return .success(records)
    case .failure(let e):
      return .failure(e)
    }
  }
  
  public func deleteRecords(
    with query: CKQuery,
    in zoneID: CKRecordZone.ID?,
    qos: QualityOfService
  ) async -> Result<ModifyRecordsResult, CKRecordError> {
    let operationResult = operationResults.removeFirst()
    guard case let .deleteRecords(result) = operationResult else {
      fatalError("Asked to delete records without an available result or invalid result type. Likely a logic error on caller side")
    }
    operationsRun += 1
    switch result.result {
    case .success(let records):
      return .success(records)
    case .failure(let e):
      return .failure(e)
    }
  }
  
  public func fetchRecords(
    with recordIDs: [CKRecord.ID],
    desiredKeys: [CKRecord.FieldKey]?,
    perRecordIDProgressBlock: PerRecordIDProgressBlock?,
    qos: QualityOfService
  ) async -> Result<FetchRecordsResult, CKRecordError> {
    let operationResult = operationResults.removeFirst()
    guard case let .fetchRecords(result) = operationResult else {
      fatalError("Asked to fetch records without an available result or invalid result type. Likely a logic error on caller side")
    }
    operationsRun += 1
    switch result.result {
    case .success(let fetchResult):
      return .success(fetchResult)
    case .failure(let e):
      return .failure(e)
    }
  }
  
  public func modifyZones(
    saving recordZonesToSave: [CKRecordZone]?,
    deleting recordZoneIDsToDelete: [CKRecordZone.ID]?,
    qos: QualityOfService
  ) async -> Result<ModifyZonesResult, CKRecordZoneError> {
    fatalError("Not implemented")
  }
  
  public func fetchZones(
    with recordZoneIDs: [CKRecordZone.ID],
    qos: QualityOfService
  ) async -> Result<[CKRecordZone], CKRecordZoneError> {
    fatalError("Not implemented")
  }
  
  public func fetchAllZones(
    qos: QualityOfService
  ) async -> Result<[CKRecordZone], CKRecordZoneError> {
    fatalError("Not implemented")
  }
  
  public func modifySubscriptions(
    saving subscriptionsToSave: [CKSubscription]?,
    deleting subscriptionIDsToDelete: [CKSubscription.ID]?,
    qos: QualityOfService
  ) async -> Result<ModifySubscriptionsResult, CKSubscriptionError> {
    fatalError("Not implemented")
  }
  
  public func fetchDatabaseChanges(
    qos: QualityOfService
  ) async -> Result<FetchDatabaseChangesResult, CanopyError> {
    fatalError("Not implemented")
  }
  
  public func fetchZoneChanges(
    recordZoneIDs: [CKRecordZone.ID],
    fetchMethod: FetchZoneChangesMethod,
    qos: QualityOfService
  ) async -> Result<FetchZoneChangesResult, CanopyError> {
    fatalError("Not implemented")
  }
}
