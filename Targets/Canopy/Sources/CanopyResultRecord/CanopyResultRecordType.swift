import CloudKit

public protocol CanopyRecordValueGetting {
  subscript(_ key: String) -> CKRecordValueProtocol? { get }
}

/// Access the values of ``CanopyResultRecord`` through this protocol.
///
/// The API is equivalent to `CKRecord`, except that this is a read-only
/// immutable view, without any setters.
public protocol CanopyResultRecordType: CanopyRecordValueGetting {
  var encryptedValues: CanopyRecordValueGetting { get }
  var recordID: CKRecord.ID { get }
  var recordType: CKRecord.RecordType { get }
  var creationDate: Date? { get }
  var creatorUserRecordID: CKRecord.ID? { get }
  var modificationDate: Date? { get }
  var lastModifiedUserRecordID: CKRecord.ID? { get }
  var recordChangeTag: String? { get }
  var parent: CKRecord.Reference? { get }
  var share: CKRecord.Reference? { get }
}
