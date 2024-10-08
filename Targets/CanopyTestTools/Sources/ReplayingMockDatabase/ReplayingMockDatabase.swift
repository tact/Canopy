import Canopy
import CloudKit

public actor ReplayingMockDatabase: Sendable {
  public enum OperationResult: Codable, Sendable {
    case queryRecords(QueryRecordsOperationResult)
    case modifyRecords(ModifyRecordsOperationResult)
    case deleteRecords(ModifyRecordsOperationResult)
    case fetchRecords(FetchRecordsOperationResult)
    case modifyZones(ModifyZonesOperationResult)
    case fetchZones(FetchZonesOperationResult)
    case fetchAllZones(FetchZonesOperationResult)
    case modifySubscriptions(ModifySubscriptionsOperationResult)
    case fetchDatabaseChanges(FetchDatabaseChangesOperationResult)
    case fetchZoneChanges(FetchZoneChangesOperationResult)
  }
  
  private var operationResults: [OperationResult]
  
  /// Whether to sleep before each operation.
  private let sleepBeforeEachOperation: Float?
  
  /// How many operations were tun in this container.
  public private(set) var operationsRun = 0
  
  public init(
    operationResults: [OperationResult] = [],
    sleepBeforeEachOperation: Float? = nil
  ) {
    self.operationResults = operationResults
    self.sleepBeforeEachOperation = sleepBeforeEachOperation
  }
  
  private func sleepIfNeeded() async {
    if let sleepBeforeEachOperation {
      try? await Task.sleep(nanoseconds: UInt64(sleepBeforeEachOperation * Float(NSEC_PER_SEC)))
    }
  }
}

extension ReplayingMockDatabase: CKDatabaseAPIType {
  public func queryRecords(
    with query: CKQuery,
    in zoneID: CKRecordZone.ID?,
    resultsLimit: Int?,
    qos: QualityOfService
  ) async -> Result<[CanopyResultRecord], CKRecordError> {
    await sleepIfNeeded()
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
    await sleepIfNeeded()
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
    await sleepIfNeeded()
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
    await sleepIfNeeded()
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
    await sleepIfNeeded()
    let operationResult = operationResults.removeFirst()
    guard case let .modifyZones(result) = operationResult else {
      fatalError("Asked to modify zones without an available result or invalid result type. Likely a logic error on caller side")
    }
    operationsRun += 1
    switch result.result {
    case .success(let fetchResult):
      return .success(fetchResult)
    case .failure(let e):
      return .failure(e)
    }
  }
  
  public func fetchZones(
    with recordZoneIDs: [CKRecordZone.ID],
    qos: QualityOfService
  ) async -> Result<[CKRecordZone], CKRecordZoneError> {
    await sleepIfNeeded()
    let operationResult = operationResults.removeFirst()
    guard case let .fetchZones(result) = operationResult else {
      fatalError("Asked to fetch zones without an available result or invalid result type. Likely a logic error on caller side")
    }
    operationsRun += 1
    switch result.result {
    case .success(let zonesArchive):
      return .success(zonesArchive.zones)
    case .failure(let e):
      return .failure(e)
    }
  }
  
  public func fetchAllZones(
    qos: QualityOfService
  ) async -> Result<[CKRecordZone], CKRecordZoneError> {
    await sleepIfNeeded()
    let operationResult = operationResults.removeFirst()
    guard case let .fetchAllZones(result) = operationResult else {
      fatalError("Asked to fetch all zones without an available result or invalid result type. Likely a logic error on caller side")
    }
    operationsRun += 1
    switch result.result {
    case .success(let zonesArchive):
      return .success(zonesArchive.zones)
    case .failure(let e):
      return .failure(e)
    }
  }
  
  public func modifySubscriptions(
    saving subscriptionsToSave: [CKSubscription]?,
    deleting subscriptionIDsToDelete: [CKSubscription.ID]?,
    qos: QualityOfService
  ) async -> Result<ModifySubscriptionsResult, CKSubscriptionError> {
    await sleepIfNeeded()
    let operationResult = operationResults.removeFirst()
    guard case let .modifySubscriptions(result) = operationResult else {
      fatalError("Asked to modify subscriptions without an available result or invalid result type. Likely a logic error on caller side")
    }
    operationsRun += 1
    switch result.result {
    case .success(let fetchResult):
      return .success(fetchResult)
    case .failure(let e):
      return .failure(e)
    }
  }
  
  public func fetchDatabaseChanges(
    qos: QualityOfService
  ) async -> Result<FetchDatabaseChangesResult, CanopyError> {
    await sleepIfNeeded()
    let operationResult = operationResults.removeFirst()
    guard case let .fetchDatabaseChanges(result) = operationResult else {
      fatalError("Asked to fetch databse changes without an available result or invalid result type. Likely a logic error on caller side")
    }
    operationsRun += 1
    switch result.result {
    case .success(let changes):
      return .success(changes)
    case .failure(let e):
      return .failure(e)
    }
  }
  
  public func fetchZoneChanges(
    recordZoneIDs: [CKRecordZone.ID],
    fetchMethod: FetchZoneChangesMethod,
    qos: QualityOfService
  ) async -> Result<FetchZoneChangesResult, CanopyError> {
    await sleepIfNeeded()
    let operationResult = operationResults.removeFirst()
    guard case let .fetchZoneChanges(result) = operationResult else {
      fatalError("Asked to fetch zone changes without an available result or invalid result type. Likely a logic error on caller side")
    }
    operationsRun += 1
    switch result.result {
    case .success(let changes):
      return .success(changes)
    case .failure(let e):
      return .failure(e)
    }
  }
}
