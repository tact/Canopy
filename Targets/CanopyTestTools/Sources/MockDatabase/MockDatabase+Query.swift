import CloudKit
import CanopyTypes

// Types and functionality for CKQueryOperation results.
extension MockDatabase {
  /// Result for one record. recordMatchedBlock is called with this. Also used by MockDatabase+Fetch.
  public struct QueryRecordResult: Codable {
    
    let recordIDArchive: CloudKitRecordIDArchive
    let codableResult: CodableResult<CloudKitRecordArchive, CKRecordError>
    
    public init(recordID: CKRecord.ID, result: Result<CKRecord, Error>) {
      self.recordIDArchive = CloudKitRecordIDArchive(recordIDs: [recordID])
      switch result {
      case .success(let record): codableResult = .success(CloudKitRecordArchive(records: [record]))
      case .failure(let error): codableResult = .failure(CKRecordError(from: error))
      }
    }
    
    var recordID: CKRecord.ID {
      recordIDArchive.recordIDs.first!
    }
    
    var result: Result<CKRecord, Error> {
      switch codableResult {
      case .success(let recordArchive): return .success(recordArchive.records.first!)
      case .failure(let error): return .failure(error.ckError)
      }
    }
  }

  /// Record for the whole query. queryResultBlock is called with this.
  public struct QueryResult: Codable {
    let codableResult: CodableResult<CloudKitCursorArchive?, CKRecordError>
    
    public init(result: Result<CKQueryOperation.Cursor?, Error>) {
      switch result {
      case .success(let maybeCursor):
        codableResult = .success(CloudKitCursorArchive(cursor: maybeCursor))
      case .failure(let error):
        codableResult = .failure(CKRecordError(from: error))
      }
    }
    
    var result: Result<CKQueryOperation.Cursor?, Error> {
      switch codableResult {
      case .success(let archive):
        if let archive {
          return .success(archive.cursor)
        } else {
          return .success(nil)
        }
      case .failure(let error): return .failure(error.ckError)
      }
    }
  }
  
  public struct QueryOperationResult: Codable {
    public let queryRecordResults: [QueryRecordResult]
    public let queryResult: QueryResult
    
    public init(queryRecordResults: [QueryRecordResult], queryResult: QueryResult) {
      self.queryRecordResults = queryRecordResults
      self.queryResult = queryResult
    }
  }
  
  internal func runQueryOperation(
    _ operation: CKQueryOperation,
    operationResult: QueryOperationResult,
    sleep: Float?
  ) async {
    for recordResult in operationResult.queryRecordResults {
      operation.recordMatchedBlock?(recordResult.recordID, recordResult.result)
    }
    if let sleep {
      try? await Task.sleep(nanoseconds: UInt64(sleep * Float(NSEC_PER_SEC)))
    }
    operation.queryResultBlock?(operationResult.queryResult.result)
  }
}
