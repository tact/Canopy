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
    resultsLimit: Int? = nil,
    qualityOfService: QualityOfService = .default
  ) async -> Result<[CanopyResultRecord], CKRecordError> {
    var startingPoint = QueryOperationStartingPoint.query(query)
    var records: [CKRecord] = []
    
    while true {
      let queryOperationResult = await performOneOperation(
        with: startingPoint,
        recordZoneID: recordZoneID,
        database: database,
        desiredKeys: desiredKeys,
        resultsLimit: resultsLimit,
        qualityOfService: qualityOfService
      )
      
      switch queryOperationResult {
      case let .error(error):
        return .failure(error)
      case let .records(newRecords):
        let ckRecords = records + newRecords
        return .success(ckRecords.map(\.canopyResultRecord))
      case let .recordsAndCursor(newRecords, cursor):
        guard !Task.isCancelled else {
          return .failure(.init(from: CKError(CKError.Code.operationCancelled)))
        }
        // If there was a results limit, just return the result even if there was a cursor
        if resultsLimit != nil {
          let ckRecords = records + newRecords
          return .success(ckRecords.map(\.canopyResultRecord))
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
    resultsLimit: Int? = nil,
    qualityOfService: QualityOfService = .userInitiated
  ) async -> QueryOperationResult {
    await withCheckedContinuation { continuation in
      var records: [CKRecord] = []
      var recordError: CKRecordError?
    
      let operation: CKQueryOperation
      switch startingPoint {
      case let .cursor(cursor):
        operation = CKQueryOperation(cursor: cursor)
      case let .query(query):
        operation = CKQueryOperation(query: query)
      }
      
      operation.zoneID = recordZoneID
      operation.desiredKeys = desiredKeys
      operation.qualityOfService = qualityOfService
      
      if let resultsLimit {
        operation.resultsLimit = resultsLimit
      }
      
      operation.recordMatchedBlock = { _, result in
        switch result {
        case let .failure(error):
          recordError = .init(from: error)
        case let .success(record):
          records.append(record)
        }
      }
      
      operation.queryResultBlock = { result in
        switch result {
        case let .success(cursor):
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
        case let .failure(error):
          continuation.resume(returning: .error(.init(from: error)))
        }
      }
      
      database.add(operation)
    }
  }
}
