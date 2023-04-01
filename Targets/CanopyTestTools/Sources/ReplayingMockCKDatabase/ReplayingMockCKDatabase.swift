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
    case (.modify(let modifyOperationResult), (let modifyOperation as CKModifyRecordsOperation)):
      runModifyOperation(modifyOperation, operationResult: modifyOperationResult)
    case (.query(let queryOperationResult), (let queryOperation as CKQueryOperation)):
      await runQueryOperation(queryOperation, operationResult: queryOperationResult, sleep: sleep)
    case (.fetch(let fetchOperationResult), (let fetchOperation as CKFetchRecordsOperation)):
      runFetchOperation(fetchOperation, operationResult: fetchOperationResult)
    case (.modifyZones(let modifyZonesOperationResult), (let modifyZonesOperation as CKModifyRecordZonesOperation)):
      runModifyZonesOperation(modifyZonesOperation, operationResult: modifyZonesOperationResult)
    case (.fetchZones(let fetchZonesOperationResult), (let fetchZonesOperation as CKFetchRecordZonesOperation)):
      runFetchZonesOperation(fetchZonesOperation, operationResult: fetchZonesOperationResult)
    case (.modifySubscriptions(let modifySubscriptionsOperationResult), (let modifySubscriptionsOperation as CKModifySubscriptionsOperation)):
      runModifySubscriptionsOperation(modifySubscriptionsOperation, operationResult: modifySubscriptionsOperationResult)
    case (.fetchDatabaseChanges(let fetchDatabaseChangesOperationResult), (let fetchDatabaseChangesOperation as CKFetchDatabaseChangesOperation)):
      await runFetchDatabaseChangesOperation(
        fetchDatabaseChangesOperation,
        operationResult: fetchDatabaseChangesOperationResult,
        sleep: sleep)
    case (.fetchZoneChanges(let fetchZoneChangesOperationResult), (let fetchZoneChangesOperation as CKFetchRecordZoneChangesOperation)):
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
  nonisolated public var debugDescription: String { "ReplayingMockCKDatabase" }
  
  nonisolated public var databaseScope: CKDatabase.Scope { scope }
  
  nonisolated public func add(_ operation: CKDatabaseOperation) {
    Task {
      await privateAdd(operation)
    }
  }
}
