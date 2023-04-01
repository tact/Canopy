import CanopyTypes
import CloudKit

extension ReplayingMockCKContainer {
  public struct UserRecordIDResult: Codable {
    let userRecordIDArchive: CloudKitRecordIDArchive?
    let recordError: CKRecordError?
    
    public init(userRecordID: CKRecord.ID? = nil, error: Error? = nil) {
      if let userRecordID {
        userRecordIDArchive = CloudKitRecordIDArchive(recordIDs: [userRecordID])
      } else {
        userRecordIDArchive = nil
      }
      if let error {
        recordError = CKRecordError(from: error)
      } else {
        recordError = nil
      }
    }
  }
}
