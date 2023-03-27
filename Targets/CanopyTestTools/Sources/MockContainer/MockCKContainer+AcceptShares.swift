import CanopyTypes
import CloudKit

extension MockCKContainer {
  
  public struct PerShareResult: Codable {
    let shareMetadataArchive: CloudKitShareMetadataArchive
    let codableResult: CodableResult<CloudKitShareArchive, CKRecordError>
    
    public init(metadata: CKShare.Metadata, result: Result<CKShare, Error>) {
      self.shareMetadataArchive = CloudKitShareMetadataArchive(shareMetadatas: [metadata])
      switch result {
      case .failure(let error): codableResult = .failure(CKRecordError(from: error))
      case .success(let share): codableResult = .success(.init(shares: [share]))
      }
    }
    
    public var result: Result<CKShare, Error> {
      switch codableResult {
      case .failure(let recordError): return .failure(recordError.ckError)
      case .success(let shareArchive): return .success(shareArchive.shares.first!)
      }
    }
  }
  
  public struct AcceptSharesResult: Codable {
    let codableResult: CodableResult<CodableVoid, CKRecordError>
    
    public init(result: Result<Void, Error>) {
      switch result {
      case .success: codableResult = .success(CodableVoid())
      case .failure(let error): codableResult = .failure(CKRecordError(from: error))
      }
    }
    
    public var result: Result<Void, Error> {
      switch codableResult {
      case .failure(let recordError): return .failure(recordError.ckError)
      case .success: return .success(())
      }
    }
  }
  
  public struct AcceptSharesOperationResult: Codable {
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
