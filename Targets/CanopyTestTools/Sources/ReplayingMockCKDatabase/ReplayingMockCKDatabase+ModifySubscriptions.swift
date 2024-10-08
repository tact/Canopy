import Canopy
import CloudKit

public extension ReplayingMockCKDatabase {
  struct SavedSubscriptionResult: Codable, Sendable {
    let subscriptionID: CKSubscription.ID
    let codableResult: CodableResult<CloudKitSubscriptionArchive, CKSubscriptionError>
    
    public init(subscriptionID: CKSubscription.ID, result: Result<CKSubscription, Error>) {
      self.subscriptionID = subscriptionID
      switch result {
      case let .success(subscription): self.codableResult = .success(CloudKitSubscriptionArchive(subscription: subscription))
      case let .failure(error): self.codableResult = .failure(CKSubscriptionError(from: error))
      }
    }

    var result: Result<CKSubscription, Error> {
      switch codableResult {
      case let .success(subscriptionArchive): return .success(subscriptionArchive.subscription)
      case let .failure(subscriptionError): return .failure(subscriptionError.ckError)
      }
    }
  }
  
  struct DeletedSubscriptionIDResult: Codable, Sendable {
    let subscriptionID: CKSubscription.ID
    let codableResult: CodableResult<CodableVoid, CKSubscriptionError>
    
    public init(subscriptionID: CKSubscription.ID, result: Result<Void, Error>) {
      self.subscriptionID = subscriptionID
      switch result {
      case .success: self.codableResult = .success(CodableVoid())
      case let .failure(error): self.codableResult = .failure(CKSubscriptionError(from: error))
      }
    }

    var result: Result<Void, Error> {
      switch codableResult {
      case .success: return .success(())
      case let .failure(subscriptionError): return .failure(subscriptionError.ckError)
      }
    }
  }
  
  struct ModifySubscriptionsResult: Codable, Sendable {
    let codableResult: CodableResult<CodableVoid, CKSubscriptionError>

    public init(result: Result<Void, Error>) {
      switch result {
      case .success: self.codableResult = .success(CodableVoid())
      case let .failure(error): self.codableResult = .failure(CKSubscriptionError(from: error))
      }
    }
    
    var result: Result<Void, Error> {
      switch codableResult {
      case .success: return .success(())
      case let .failure(subscriptionError): return .failure(subscriptionError.ckError)
      }
    }
  }
  
  struct ModifySubscriptionsOperationResult: Codable, Sendable {
    public let savedSubscriptionResults: [SavedSubscriptionResult]
    public let deletedSubscriptionIDResults: [DeletedSubscriptionIDResult]
    public let modifySubscriptionsResult: ModifySubscriptionsResult
    
    public init(savedSubscriptionResults: [SavedSubscriptionResult], deletedSubscriptionIDResults: [DeletedSubscriptionIDResult], modifySubscriptionsResult: ModifySubscriptionsResult) {
      self.savedSubscriptionResults = savedSubscriptionResults
      self.deletedSubscriptionIDResults = deletedSubscriptionIDResults
      self.modifySubscriptionsResult = modifySubscriptionsResult
    }
  }
  
  internal func runModifySubscriptionsOperation(
    _ operation: CKModifySubscriptionsOperation,
    operationResult: ModifySubscriptionsOperationResult
  ) {
    for savedSubscriptionsResult in operationResult.savedSubscriptionResults {
      operation.perSubscriptionSaveBlock?(savedSubscriptionsResult.subscriptionID, savedSubscriptionsResult.result)
    }
    for deletedSubscriptionIDResult in operationResult.deletedSubscriptionIDResults {
      operation.perSubscriptionDeleteBlock?(deletedSubscriptionIDResult.subscriptionID, deletedSubscriptionIDResult.result)
    }
    operation.modifySubscriptionsResultBlock?(operationResult.modifySubscriptionsResult.result)
  }
}
