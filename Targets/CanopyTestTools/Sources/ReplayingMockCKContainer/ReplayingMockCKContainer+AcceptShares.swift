import CanopyTypes
import CloudKit

public extension ReplayingMockCKContainer {
  struct PerShareResult: Codable {
    let shareMetadataArchive: CloudKitShareMetadataArchive
    let codableResult: CodableResult<CloudKitShareArchive, CKRecordError>
    
    public init(metadata: CKShare.Metadata, result: Result<CKShare, Error>) {
      self.shareMetadataArchive = CloudKitShareMetadataArchive(shareMetadatas: [metadata])
      switch result {
      case let .failure(error): self.codableResult = .failure(CKRecordError(from: error))
      case let .success(share): self.codableResult = .success(.init(shares: [share]))
      }
    }
    
    public var result: Result<CKShare, Error> {
      switch codableResult {
      case let .failure(recordError): return .failure(recordError.ckError)
      case let .success(shareArchive): return .success(shareArchive.shares.first!)
      }
    }
  }
  
  struct AcceptSharesResult: Codable {
    let codableResult: CodableResult<CodableVoid, CKRecordError>
    
    public init(result: Result<Void, Error>) {
      switch result {
      case .success: self.codableResult = .success(CodableVoid())
      case let .failure(error): self.codableResult = .failure(CKRecordError(from: error))
      }
    }
    
    public var result: Result<Void, Error> {
      switch codableResult {
      case let .failure(recordError): return .failure(recordError.ckError)
      case .success: return .success(())
      }
    }
  }
  
  struct AcceptSharesOperationResult: Codable {
    let perShareResults: [PerShareResult]
    let acceptSharesResult: AcceptSharesResult
    
    public init(perShareResults: [PerShareResult], acceptSharesResult: AcceptSharesResult) {
      self.perShareResults = perShareResults
      self.acceptSharesResult = acceptSharesResult
    }
  }
  
  internal func runAcceptSharesOperation(
    _ operation: CKAcceptSharesOperation,
    operationResult: AcceptSharesOperationResult
  ) {
    for perShareResult in operationResult.perShareResults {
      operation.perShareResultBlock?(perShareResult.shareMetadataArchive.shareMetadatas.first!, perShareResult.result)
    }
    operation.acceptSharesResultBlock?(operationResult.acceptSharesResult.result)
  }
}
