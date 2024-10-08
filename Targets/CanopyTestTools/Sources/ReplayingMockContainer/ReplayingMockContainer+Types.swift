import Canopy
import CloudKit

public extension ReplayingMockContainer {
  struct UserRecordIDResult: Codable, Sendable {
    let userRecordIDArchive: CloudKitRecordIDArchive?
    let recordError: CKRecordError?
    
    public init(userRecordID: CKRecord.ID? = nil, error: CKRecordError? = nil) {
      if let userRecordID {
        self.userRecordIDArchive = CloudKitRecordIDArchive(recordIDs: [userRecordID])
      } else {
        self.userRecordIDArchive = nil
      }
      if let error {
        self.recordError = error
      } else {
        self.recordError = nil
      }
    }
  }
  
  struct AccountStatusResult: Codable, Sendable {
    let statusValue: Int
    let canopyError: CanopyError?
    
    public init(status: CKAccountStatus, error: CanopyError?) {
      self.statusValue = status.rawValue
      if let error {
        self.canopyError = error
      } else {
        self.canopyError = nil
      }
    }
  }
  
  struct AccountStatusStreamResult: Codable, Sendable {
    let statusValues: [Int]
    let error: CKContainerAPIError?
    public init(statuses: [CKAccountStatus], error: CKContainerAPIError?) {
      statusValues = statuses.map { $0.rawValue }
      self.error = error
    }
  }
  
  struct AcceptSharesResult: Codable, Sendable {
    let result: CodableResult<CloudKitShareArchive, CKRecordError>
    public init(result: Result<[CKShare], CKRecordError>) {
      switch result {
      case .success(let shares): self.result = .success(CloudKitShareArchive(shares: shares))
      case .failure(let error): self.result = .failure(error)
      }
    }
  }
  
  struct FetchShareParticipantsResult: Codable, Sendable {
    let result: CodableResult<CloudKitShareParticipantArchive, CKRecordError>
    public init(result: Result<[CKShare.Participant], CKRecordError>) {
      switch result {
      case .success(let participants): self.result = .success(CloudKitShareParticipantArchive(shareParticipants: participants))
      case .failure(let error): self.result = .failure(error)
      }
    }
  }
}
