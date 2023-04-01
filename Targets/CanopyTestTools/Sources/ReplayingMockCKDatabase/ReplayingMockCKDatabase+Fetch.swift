import CloudKit
import CanopyTypes

extension ReplayingMockCKDatabase {
  
  public struct FetchResult: Codable {
    let codableResult: CodableResult<CodableVoid, CKRecordError>
    
    public init(result: Result<Void, Error>) {
      switch result {
      case .success: codableResult = .success(CodableVoid())
      case .failure(let error): codableResult = .failure(CKRecordError(from: error))
      }
    }
    
    var result: Result<Void, Error> {
      switch codableResult {
      case .success: return .success(())
      case .failure(let error): return .failure(error.ckError)
      }
    }
  }
  public struct FetchOperationResult: Codable {
    public let fetchRecordResults: [QueryRecordResult]
    public let fetchResult: FetchResult
    
    public init(fetchRecordResults: [QueryRecordResult], fetchResult: FetchResult) {
      self.fetchRecordResults = fetchRecordResults
      self.fetchResult = fetchResult
    }
  }
  
  internal func runFetchOperation(
    _ operation: CKFetchRecordsOperation,
    operationResult: FetchOperationResult
  ) {
    for recordResult in operationResult.fetchRecordResults {
      operation.perRecordResultBlock?(recordResult.recordID, recordResult.result)
    }
    operation.fetchRecordsResultBlock?(operationResult.fetchResult.result)
  }
}
