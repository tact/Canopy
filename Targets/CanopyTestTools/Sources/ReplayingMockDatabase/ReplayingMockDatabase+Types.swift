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
  
  struct ModifyZonesOperationResult: Codable, Sendable {
    let result: CodableResult<ModifyZonesResult, CKRecordZoneError>
    public init(result: Result<ModifyZonesResult, CKRecordZoneError>) {
      switch result {
      case .success(let modifyResult): self.result = .success(modifyResult)
      case .failure(let error): self.result = .failure(error)
      }
    }
  }
  
  struct FetchZonesOperationResult: Codable, Sendable {
    let result: CodableResult<CloudKitRecordZoneArchive, CKRecordZoneError>
    public init(result: Result<[CKRecordZone], CKRecordZoneError>) {
      switch result {
      case .success(let zones): self.result = .success(.init(zones: zones))
      case .failure(let recordZoneError): self.result = .failure(recordZoneError)
      }
    }
  }
  
  struct ModifySubscriptionsOperationResult: Codable, Sendable {
    let result: CodableResult<ModifySubscriptionsResult, CKSubscriptionError>
    public init(result: Result<ModifySubscriptionsResult, CKSubscriptionError>) {
      switch result {
      case .success(let modifyResult): self.result = .success(modifyResult)
      case .failure(let error): self.result = .failure(error)
      }
    }
  }
  
  struct FetchDatabaseChangesOperationResult: Codable, Sendable {
    let result: CodableResult<FetchDatabaseChangesResult, CanopyError>
    public init(result: Result<FetchDatabaseChangesResult, CanopyError>) {
      switch result {
      case .success(let fetchResult): self.result = .success(fetchResult)
      case .failure(let error): self.result = .failure(error)
      }
    }
  }
  
  struct FetchZoneChangesOperationResult: Codable, Sendable {
    let result: CodableResult<FetchZoneChangesResult, CanopyError>
    public init(result: Result<FetchZoneChangesResult, CanopyError>) {
      switch result {
      case .success(let fetchResult): self.result = .success(fetchResult)
      case .failure(let error): self.result = .failure(error)
      }
    }
  }
}
