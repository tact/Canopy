import CanopyTypes
import CloudKit

public actor ReplayingMockContainer: Codable, Sendable {
  public enum OperationResult: Codable, Sendable {
    case userRecordID(UserRecordIDResult)
    case accountStatus(AccountStatusResult)
    case accountStatusStream(AccountStatusStreamResult)
    case fetchShareParticipants(FetchShareParticipantsResult)
    case acceptShares(AcceptSharesResult)
  }
    
  private var operationResults: [OperationResult]
  
  /// How many operations were tun in this container.
  public private(set) var operationsRun = 0
  
  public init(
    operationResults: [OperationResult] = []
  ) {
    self.operationResults = operationResults
  }
}

extension ReplayingMockContainer: CKContainerAPIType {
  public var userRecordID: Result<CKRecord.ID?, CKRecordError> {
    get async {
      let operationResult = operationResults.removeFirst()
      guard case let .userRecordID(result) = operationResult else {
        fatalError("Asked to fetch user record ID without an available result or invalid result type. Likely a logic error on caller side")
      }
      operationsRun += 1
      if let error = result.recordError {
        return .failure(error)
      } else {
        return .success(result.userRecordIDArchive!.recordIDs.first!)
      }
    }
  }
  
  public var accountStatus: Result<CKAccountStatus, CanopyError> {
    get async {
      let operationResult = operationResults.removeFirst()
      guard case let .accountStatus(result) = operationResult else {
        fatalError("Asked for account status without an available result or invalid result type. Likely a logic error on caller side")
      }
      operationsRun += 1
      if let error = result.canopyError {
        return .failure(error)
      } else {
        guard let status = CKAccountStatus(rawValue: result.statusValue) else {
          fatalError("Could not recreate CKAccountStatus from value \(result.statusValue)")
        }
        return .success(status)
      }
    }
  }
  
  public var accountStatusStream: Result<AsyncStream<CKAccountStatus>, CKContainerAPIError> {
    get async {
      let operationResult = operationResults.removeFirst()
      guard case let .accountStatusStream(result) = operationResult else {
        fatalError("Asked for account status stream without an available result or invalid result type. Likely a logic error on caller side")
      }
      operationsRun += 1
      if let error = result.error {
        return .failure(error)
      } else {
        var statusesIterator = result.statusValues.makeIterator()
        return .success(AsyncStream(unfolding: {
          guard let next = statusesIterator.next() else { return nil }
          return CKAccountStatus(rawValue: next)!
        }))
      }
    }
  }
  
  public func acceptShares(
    with metadatas: [CKShare.Metadata],
    qos: QualityOfService
  ) async -> Result<[CKShare], CKRecordError> {
    let operationResult = operationResults.removeFirst()
    guard case let .acceptShares(result) = operationResult else {
      fatalError("Asked to fetch user record ID without an available result or invalid result type. Likely a logic error on caller side")
    }
    operationsRun += 1
    switch result.result {
    case .success(let recordArchive):
      return .success(recordArchive.shares)
    case .failure(let e):
      return .failure(e)
    }
  }
  
  public func fetchShareParticipants(
    with lookupInfos: [CKUserIdentity.LookupInfo],
    qos: QualityOfService
  ) async -> Result<[CKShare.Participant], CKRecordError> {
    let operationResult = operationResults.removeFirst()
    guard case let .fetchShareParticipants(result) = operationResult else {
      fatalError("Asked to fetch user record ID without an available result or invalid result type. Likely a logic error on caller side")
    }
    operationsRun += 1
    switch result.result {
    case .success(let participantArchive):
      return .success(participantArchive.shareParticipants)
    case .failure(let e):
      return .failure(e)
    }
  }
}
