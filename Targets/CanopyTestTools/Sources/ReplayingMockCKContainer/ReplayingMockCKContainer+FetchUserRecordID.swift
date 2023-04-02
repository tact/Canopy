import CanopyTypes
import CloudKit

public extension ReplayingMockCKContainer {
  struct UserRecordIDResult: Codable {
    let userRecordIDArchive: CloudKitRecordIDArchive?
    let recordError: CKRecordError?
    
    public init(userRecordID: CKRecord.ID? = nil, error: Error? = nil) {
      if let userRecordID {
        self.userRecordIDArchive = CloudKitRecordIDArchive(recordIDs: [userRecordID])
      } else {
        self.userRecordIDArchive = nil
      }
      if let error {
        self.recordError = CKRecordError(from: error)
      } else {
        self.recordError = nil
      }
    }
  }
}
