import CanopyTypes
import CloudKit

actor CKContainerAPI: CKContainerAPIType {
  let container: CKContainerType
  var statusContinuation: AsyncStream<CKAccountStatus>.Continuation?
  
  init(container: CKContainerType, accountChangedSequence: CKAccountChangedSequence) {
    self.container = container
    Task {
      for await _ in accountChangedSequence {
        await emitStatus()
      }
    }
  }
  
  var accountStatusStream: Result<AsyncStream<CKAccountStatus>, CKContainerAPIError> {
    // I tried to have several streams, by creating a new one and capturing its continuation
    // into a set of continuations every time a stream is requested.
    // Got nondeterministic test results with multiple streams, so for now, only one stream.
    guard statusContinuation == nil else { return .failure(.onlyOneAccountStatusStreamSupported) }
    
    var cont: AsyncStream<CKAccountStatus>.Continuation!
    let stream = AsyncStream<CKAccountStatus> { cont = $0 }
    statusContinuation = cont
    Task {
      // Emit the first/current account status right when the stream is created.
      if let status = try? await accountStatus.get() {
        cont.yield(status)
      }
    }
    return .success(stream)
  }
  
  var userRecordID: Result<CKRecord.ID?, CKRecordError> {
    get async {
      await withCheckedContinuation { continuation in
        container.fetchUserRecordID { recordID, error in
          if let error {
            continuation.resume(returning: .failure(CKRecordError(from: error)))
          } else {
            continuation.resume(returning: .success(recordID))
          }
        }
      }
    }
  }
  
  var accountStatus: Result<CKAccountStatus, CanopyError> {
    get async {
      await withCheckedContinuation { continuation in
        container.accountStatus { accountStatus, error in
          if let error {
            continuation.resume(returning: .failure(CanopyError.accountError(from: error)))
          } else {
            continuation.resume(returning: .success(accountStatus))
          }
        }
      }
    }
  }
  
  private func emitStatus() async {
    guard let status = try? await accountStatus.get() else { return }
    statusContinuation?.yield(status)
  }
  
  nonisolated func fetchShareParticipants(
    with lookupInfos: [CKUserIdentity.LookupInfo],
    qos: QualityOfService
  ) async -> Result<[CKShare.Participant], CKRecordError> {
    await withCheckedContinuation { continuation in
      var participants: [CKShare.Participant] = []
      var recordError: CKRecordError?
      let fetchParticipantsOperation = CKFetchShareParticipantsOperation(userIdentityLookupInfos: lookupInfos)
      fetchParticipantsOperation.qualityOfService = qos
      
      fetchParticipantsOperation.perShareParticipantResultBlock = { _, result in
        switch result {
        case let .failure(error):
          recordError = CKRecordError(from: error)
        case let .success(participant):
          participants.append(participant)
        }
      }
      
      fetchParticipantsOperation.fetchShareParticipantsResultBlock = { result in
        switch result {
        case let .failure(error):
          continuation.resume(returning: .failure(CKRecordError(from: error)))
        case .success:
          if let recordError {
            continuation.resume(returning: .failure(recordError))
          } else {
            continuation.resume(returning: .success(participants))
          }
        }
      }
      
      container.add(fetchParticipantsOperation)
    }
  }
  
  nonisolated func acceptShares(with metadatas: [CKShare.Metadata], qos: QualityOfService) async -> Result<[CKShare], CKRecordError> {
    await withCheckedContinuation { continuation in
      var recordError: CKRecordError?
      var acceptedShares: [CKShare] = []
      
      let acceptSharesOperation = CKAcceptSharesOperation(shareMetadatas: metadatas)
      acceptSharesOperation.qualityOfService = qos
      
      acceptSharesOperation.perShareResultBlock = { _, result in
        switch result {
        case let .failure(error):
          recordError = CKRecordError(from: error)
        case let .success(acceptedShare):
          acceptedShares.append(acceptedShare)
        }
      }
      
      acceptSharesOperation.acceptSharesResultBlock = { result in
        switch result {
        case .success:
          if let recordError {
            // Be defensive. Fail the operation if there was at least one per-share error.
            continuation.resume(returning: .failure(recordError))
          } else {
            continuation.resume(returning: .success(acceptedShares))
          }
        case let .failure(error):
          continuation.resume(returning: .failure(CKRecordError(from: error)))
        }
      }
      container.add(acceptSharesOperation)
    }
  }
}
