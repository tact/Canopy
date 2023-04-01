import CloudKit
import CanopyTypes

extension ReplayingMockCKContainer {
  public struct PerShareParticipantResult: Codable {
    let lookupInfoArchive: CloudKitLookupInfoArchive
    let codableResult: CodableResult<CloudKitShareParticipantArchive, CKRecordError>
    
    public init(lookupInfo: CKUserIdentity.LookupInfo, result: Result<CKShare.Participant, Error>) {
      self.lookupInfoArchive = CloudKitLookupInfoArchive(lookupInfos: [lookupInfo])
      switch result {
      case .failure(let error): codableResult = .failure(CKRecordError(from: error))
      case .success(let participant): codableResult = .success(.init(shareParticipants: [participant]))
      }
    }
    
    public var result: Result<CKShare.Participant, Error> {
      switch codableResult {
      case .failure(let recordError): return .failure(recordError.ckError)
      case .success(let shareParticipantArchive): return .success(shareParticipantArchive.shareParticipants.first!)
      }
    }
  }
  
  public struct FetchShareParticipantsResult: Codable {
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
  
  public struct FetchShareParticipantsOperationResult: Codable {
    let perShareParticipantResults: [PerShareParticipantResult]
    let fetchShareParticipantsResult: FetchShareParticipantsResult
    
    public init(perShareParticipantResults: [PerShareParticipantResult], fetchShareParticipantsResult: FetchShareParticipantsResult) {
      self.perShareParticipantResults = perShareParticipantResults
      self.fetchShareParticipantsResult = fetchShareParticipantsResult
    }
  }
  
  internal func runFetchShareParticipantsOperation(
    _ operation: CKFetchShareParticipantsOperation,
    operationResult: FetchShareParticipantsOperationResult
  ) {
    for perShareParticipantResult in operationResult.perShareParticipantResults {
      operation.perShareParticipantResultBlock?(perShareParticipantResult.lookupInfoArchive.lookupInfos.first!, perShareParticipantResult.result)
    }
    operation.fetchShareParticipantsResultBlock?(operationResult.fetchShareParticipantsResult.result)
  }
}
