import CloudKit

extension CKRecord {
  public var canopyResultRecord: CanopyResultRecord {
    CanopyResultRecord(ckRecord: self)
  }
}
