import Canopy
import CloudKit

public extension ReplayingMockCKContainer {
  struct PerShareParticipantResult: Codable, Sendable {
    let lookupInfoArchive: CloudKitLookupInfoArchive
    let codableResult: CodableResult<CloudKitShareParticipantArchive, CKRecordError>
    
    public init(lookupInfo: CKUserIdentity.LookupInfo, result: Result<CKShare.Participant, Error>) {
      self.lookupInfoArchive = CloudKitLookupInfoArchive(lookupInfos: [lookupInfo])
      switch result {
      case let .failure(error): self.codableResult = .failure(CKRecordError(from: error))
      case let .success(participant): self.codableResult = .success(.init(shareParticipants: [participant]))
      }
    }
    
    public var result: Result<CKShare.Participant, Error> {
      switch codableResult {
      case let .failure(recordError): return .failure(recordError.ckError)
      case let .success(shareParticipantArchive): return .success(shareParticipantArchive.shareParticipants.first!)
      }
    }
  }
  
  struct FetchShareParticipantsResult: Codable, Sendable {
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
  
  struct FetchShareParticipantsOperationResult: Codable, Sendable {
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
