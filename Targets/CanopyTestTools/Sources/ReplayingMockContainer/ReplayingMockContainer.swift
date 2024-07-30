import CanopyTypes
import CloudKit

public actor ReplayingMockContainer {
//  public enum OperationResult: Codable, Sendable {
//    case userRecordID(ReplayingMockCKContainer.UserRecordIDResult)
//    case accountStatus(ReplayingMockCKContainer.AccountStatusResult)
//    case fetchShareParticipants(ReplayingMockCKContainer.FetchShareParticipantsOperationResult)
//    case acceptShares(ReplayingMockCKContainer.AcceptSharesOperationResult)
//  }
//  
//  
//  private var operationResults: [OperationResult]
//  
//  public init(
//    operationResults: [ReplayingMockCKContainer.OperationResult] = []
//  ) {
//    self.operationResults = operationResults
//  }
}

extension ReplayingMockContainer: CKContainerAPIType {
  public var userRecordID: Result<CKRecord.ID?, CanopyTypes.CKRecordError> {
    get async {
      fatalError("Not implemented")
    }
  }
  
  public var accountStatus: Result<CKAccountStatus, CanopyTypes.CanopyError> {
    get async {
      fatalError("Not implemented")
    }
  }
  
  public var accountStatusStream: Result<AsyncStream<CKAccountStatus>, CKContainerAPIError> {
    get async {
      fatalError("Not implemented")
    }
  }
  
  public func acceptShares(
    with metadatas: [CKShare.Metadata],
    qos: QualityOfService
  ) async -> Result<[CKShare], CKRecordError> {
    fatalError("Not implemented")
  }
  
  public func fetchShareParticipants(
    with lookupInfos: [CKUserIdentity.LookupInfo],
    qos: QualityOfService
  ) async -> Result<[CKShare.Participant], CKRecordError> {
    fatalError("Not implemented")
  }
}
