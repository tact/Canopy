import CanopyTypes
import CloudKit

public extension ReplayingMockDatabase {
  struct QueryRecordsOperationResult: Codable, Sendable {
    let result: CodableResult<[CanopyResultRecord], CKRecordError>
    public init(result: Result<[CanopyResultRecord], CKRecordError>) {
      switch result {
      case .success(let records): self.result = .success(records)
      case .failure(let error): self.result = .failure(error)
      }
    }
  }
  
  struct ModifyRecordsOperationResult: Codable, Sendable {
    let result: CodableResult<ModifyRecordsResult, CKRecordError>
    public init(result: Result<ModifyRecordsResult, CKRecordError>) {
      switch result {
      case .success(let modifyResult): self.result = .success(modifyResult)
      case .failure(let error): self.result = .failure(error)
      }
    }
  }
  
  struct FetchRecordsOperationResult: Codable, Sendable {
    let result: CodableResult<FetchRecordsResult, CKRecordError>
    public init(result: Result<FetchRecordsResult, CKRecordError>) {
      switch result {
      case .success(let fetchResult): self.result = .success(fetchResult)
      case .failure(let error): self.result = .failure(error)
      }
    }
  }
}
