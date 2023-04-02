import CloudKit

public extension CKRecord {
  /// A simple comparison to determine record equivalence.
  ///
  /// Doesn’t compare fields.
  func isEqualToRecord(_ record: CKRecord) -> Bool {
    recordID == record.recordID &&
      recordType == record.recordType &&
      record.recordChangeTag == record.recordChangeTag
  }
}
