import CanopyTypes
import CloudKit
import Foundation

/// Mock of CKDatabase, suitable for running CKModifyOperation tests.
public actor ReplayingMockCKDatabase {
  /// How many `add` calls were made to this database.
  public private(set) var operationsRun = 0
  
  let scope: CKDatabase.Scope
  
  /// Whether to sleep in the operations where sleep has been enabled.
  let sleep: Float?
  
  public enum OperationResult: Codable {
    case modify(ModifyOperationResult)
    case query(QueryOperationResult)
    case fetch(FetchOperationResult)
    case modifyZones(ModifyZonesOperationResult)
    case fetchZones(FetchZonesOperationResult)
    case modifySubscriptions(ModifySubscriptionsOperationResult)
    case fetchDatabaseChanges(FetchDatabaseChangesOperationResult)
    case fetchZoneChanges(FetchZoneChangesOperationResult)
  }
  
  var operationResults: [OperationResult]
  
  public init(
    operationResults: [OperationResult] = [],
    scope: CKDatabase.Scope = .private,
    sleep: Float? = nil
  ) {
    self.operationResults = operationResults
    self.scope = scope
    self.sleep = sleep
  }
  
  func privateAdd(_ operation: CKDatabaseOperation) async {
    guard let operationResult = operationResults.first else {
      fatalError("Asked to run operation without an available result. Operation: \(operation)")
    }
    operationResults.removeFirst()
    operationsRun += 1
    
    switch (operationResult, operation) {
    case let (.modify(modifyOperationResult), modifyOperation as CKModifyRecordsOperation):
      runModifyOperation(modifyOperation, operationResult: modifyOperationResult)
    case let (.query(queryOperationResult), queryOperation as CKQueryOperation):
      await runQueryOperation(queryOperation, operationResult: queryOperationResult, sleep: sleep)
    case let (.fetch(fetchOperationResult), fetchOperation as CKFetchRecordsOperation):
      runFetchOperation(fetchOperation, operationResult: fetchOperationResult)
    case let (.modifyZones(modifyZonesOperationResult), modifyZonesOperation as CKModifyRecordZonesOperation):
      runModifyZonesOperation(modifyZonesOperation, operationResult: modifyZonesOperationResult)
    case let (.fetchZones(fetchZonesOperationResult), fetchZonesOperation as CKFetchRecordZonesOperation):
      runFetchZonesOperation(fetchZonesOperation, operationResult: fetchZonesOperationResult)
    case let (.modifySubscriptions(modifySubscriptionsOperationResult), modifySubscriptionsOperation as CKModifySubscriptionsOperation):
      runModifySubscriptionsOperation(modifySubscriptionsOperation, operationResult: modifySubscriptionsOperationResult)
    case let (.fetchDatabaseChanges(fetchDatabaseChangesOperationResult), fetchDatabaseChangesOperation as CKFetchDatabaseChangesOperation):
      await runFetchDatabaseChangesOperation(
        fetchDatabaseChangesOperation,
        operationResult: fetchDatabaseChangesOperationResult,
        sleep: sleep
      )
    case let (.fetchZoneChanges(fetchZoneChangesOperationResult), fetchZoneChangesOperation as CKFetchRecordZoneChangesOperation):
      await runFetchZoneChangesOperation(
        fetchZoneChangesOperation,
        operationResult: fetchZoneChangesOperationResult,
        sleep: sleep
      )
    default:
      fatalError("Dequeued operation and result do not match. Result: \(operationResult), operation: \(operation)")
    }
  }
}

extension ReplayingMockCKDatabase: CKDatabaseType {
  public nonisolated var debugDescription: String { "ReplayingMockCKDatabase" }
  
  public nonisolated var databaseScope: CKDatabase.Scope { scope }
  
  public nonisolated func add(_ operation: CKDatabaseOperation) {
    Task {
      await privateAdd(operation)
    }
  }
}
