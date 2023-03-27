import CloudKit
import CanopyTypes

extension MockDatabase {
  
  public struct SavedSubscriptionResult: Codable {
    let subscriptionID: CKSubscription.ID
    let codableResult: CodableResult<CloudKitSubscriptionArchive, CKSubscriptionError>
    
    public init(subscriptionID: CKSubscription.ID, result: Result<CKSubscription, Error>) {
      self.subscriptionID = subscriptionID
      switch result {
      case .success(let subscription): codableResult = .success(CloudKitSubscriptionArchive(subscription: subscription))
      case .failure(let error): codableResult = .failure(CKSubscriptionError(from: error))
      }
    }

    var result: Result<CKSubscription, Error> {
      switch codableResult {
      case .success(let subscriptionArchive): return .success(subscriptionArchive.subscription)
      case .failure(let subscriptionError): return .failure(subscriptionError.ckError)
      }
    }

  }
  
  public struct DeletedSubscriptionIDResult: Codable {
    let subscriptionID: CKSubscription.ID
    let codableResult: CodableResult<CodableVoid, CKSubscriptionError>
    
    public init(subscriptionID: CKSubscription.ID, result: Result<Void, Error>) {
      self.subscriptionID = subscriptionID
      switch result {
      case .success: codableResult = .success(CodableVoid())
      case .failure(let error): codableResult = .failure(CKSubscriptionError(from: error))
      }
    }

    var result: Result<Void, Error> {
      switch codableResult {
      case .success: return .success(())
      case .failure(let subscriptionError): return .failure(subscriptionError.ckError)
      }
    }
  }
  
  public struct ModifySubscriptionsResult: Codable {
    let codableResult: CodableResult<CodableVoid, CKSubscriptionError>

    public init(result: Result<Void, Error>) {
      switch result {
      case .success: codableResult = .success(CodableVoid())
      case .failure(let error): codableResult = .failure(CKSubscriptionError(from: error))
      }
    }
    
    var result: Result<Void, Error> {
      switch codableResult {
      case .success: return .success(())
      case .failure(let subscriptionError): return .failure(subscriptionError.ckError)
      }
    }
  }
  
  public struct ModifySubscriptionsOperationResult: Codable {
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
