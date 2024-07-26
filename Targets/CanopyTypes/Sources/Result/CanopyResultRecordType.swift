import CloudKit

protocol CanopyRecordValueProtocol: CKRecordValueProtocol, Sendable {}

protocol CanopyRecordValueGetting {
  subscript(_ key: String) -> (any CanopyRecordValueProtocol)? { get }
}

protocol CanopyResultRecordType: CanopyRecordValueGetting {
  var encryptedValuesView: CanopyRecordValueGetting { get }
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
