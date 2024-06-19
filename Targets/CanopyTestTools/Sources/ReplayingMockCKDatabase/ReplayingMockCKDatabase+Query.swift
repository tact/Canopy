import CanopyTypes
import CloudKit

// Types and functionality for CKQueryOperation results.
public extension ReplayingMockCKDatabase {
  /// Result for one record. recordMatchedBlock is called with this. Also used by ReplayingMockCKDatabase+Fetch.
  struct QueryRecordResult: Codable, Sendable {
    let recordIDArchive: CloudKitRecordIDArchive
    let codableResult: CodableResult<CloudKitRecordArchive, CKRecordError>
    
    public init(recordID: CKRecord.ID, result: Result<CKRecord, Error>) {
      self.recordIDArchive = CloudKitRecordIDArchive(recordIDs: [recordID])
      switch result {
      case let .success(record): self.codableResult = .success(CloudKitRecordArchive(records: [record]))
      case let .failure(error): self.codableResult = .failure(CKRecordError(from: error))
      }
    }
    
    var recordID: CKRecord.ID {
      recordIDArchive.recordIDs.first!
    }
    
    var result: Result<CKRecord, Error> {
      switch codableResult {
      case let .success(recordArchive): return .success(recordArchive.records.first!)
      case let .failure(error): return .failure(error.ckError)
      }
    }
  }

  /// Record for the whole query. queryResultBlock is called with this.
  struct QueryResult: Codable, Sendable {
    let codableResult: CodableResult<CloudKitCursorArchive?, CKRecordError>
    
    public init(result: Result<CKQueryOperation.Cursor?, Error>) {
      switch result {
      case let .success(maybeCursor):
        self.codableResult = .success(CloudKitCursorArchive(cursor: maybeCursor))
      case let .failure(error):
        self.codableResult = .failure(CKRecordError(from: error))
      }
    }
    
    var result: Result<CKQueryOperation.Cursor?, Error> {
      switch codableResult {
      case let .success(archive):
        if let archive {
          return .success(archive.cursor)
        } else {
          return .success(nil)
        }
      case let .failure(error): return .failure(error.ckError)
      }
    }
  }
  
  struct QueryOperationResult: Codable, Sendable {
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
