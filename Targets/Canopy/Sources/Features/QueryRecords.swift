import CanopyTypes
import CloudKit
import Foundation

/// Query records from CloudKit, automatically handling multiple pages and cursors.
///
/// This is a light wrapper around CKQueryOperation, providing a simple async interface
/// and automatically handling paging and cursors, returning one complete set of records in the end.
///
/// To cancel any follow-up requests, cancel the enclosing task.
struct QueryRecords {

  enum QueryOperationStartingPoint {
    case query(CKQuery)
    case cursor(CKQueryOperation.Cursor)
  }
  
  enum QueryOperationResult {
    /// We got records, and there are no more records remaining to get, this is the final page.
    case records([CKRecord])
    
    /// We got records, and there are more to be obtained.
    case recordsAndCursor([CKRecord], CKQueryOperation.Cursor)
    
    /// There was an error getting the records.
    case error(CKRecordError)
  }

  public static func with(
    _ query: CKQuery,
    recordZoneID: CKRecordZone.ID?,
    database: CKDatabaseType,
    desiredKeys: [CKRecord.FieldKey]? = nil,
    qualityOfService: QualityOfService = .default
  ) async -> Result<[CKRecord], CKRecordError> {
    
    var startingPoint = QueryOperationStartingPoint.query(query)
    var records: [CKRecord] = []
    
    while true {

      let queryOperationResult = await performOneOperation(
        with: startingPoint,
        recordZoneID: recordZoneID,
        database: database,
        desiredKeys: desiredKeys,
        qualityOfService: qualityOfService
      )
      
      switch queryOperationResult {
      case .error(let error):
        return .failure(error)
      case .records(let newRecords):
        return .success(records + newRecords)
      case .recordsAndCursor(let newRecords, let cursor):
        guard !Task.isCancelled else {
          return .failure(.init(from: CKError(CKError.Code.operationCancelled)))
        }
        startingPoint = QueryOperationStartingPoint.cursor(cursor)
        records += newRecords
      }
    }
  }
  
  private static func performOneOperation(
    with startingPoint: QueryOperationStartingPoint,
    recordZoneID: CKRecordZone.ID?,
    database: CKDatabaseType,
    desiredKeys: [CKRecord.FieldKey]? = nil,
    qualityOfService: QualityOfService = .userInitiated
  ) async -> QueryOperationResult {
    
    await withCheckedContinuation { continuation in
      var records: [CKRecord] = []
      var recordError: CKRecordError?
    
      let operation: CKQueryOperation
      switch startingPoint {
      case .cursor(let cursor):
        operation = CKQueryOperation(cursor: cursor)
      case .query(let query):
        operation = CKQueryOperation(query: query)
      }
      
      operation.zoneID = recordZoneID
      operation.desiredKeys = desiredKeys
      operation.qualityOfService = qualityOfService
      
      operation.recordMatchedBlock = { recordId, result in
        switch result {
        case .failure(let error):
          recordError = .init(from: error)
        case .success(let record):
          records.append(record)
        }
      }
      
      operation.queryResultBlock = { result in
        switch result {
        case .success(let cursor):
          // Be defensive: if there was a record error, fail the whole request with that.
          if let recordError {
            continuation.resume(returning: .error(recordError))
            return
          }
          if let cursor {
            continuation.resume(returning: .recordsAndCursor(records, cursor))
          } else {
            continuation.resume(returning: .records(records))
          }
        case .failure(let error):
          continuation.resume(returning: .error(.init(from: error)))
        }
      }
      
      database.add(operation)
    }
  }
}
