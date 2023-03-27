import CloudKit

public protocol CKContainerType {
  func fetchUserRecordID(completionHandler: @escaping (CKRecord.ID?, Error?) -> Void)
  func accountStatus(completionHandler: @escaping (CKAccountStatus, Error?) -> Void)
  func add(_ operation: CKOperation)
}
