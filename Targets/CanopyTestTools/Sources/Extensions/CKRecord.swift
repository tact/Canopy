import CloudKit

extension CKRecord {
  /// A simple comparison to determine record equivalence.
  ///
  /// Doesn’t compare fields.
  public func isEqualToRecord(_ record: CKRecord) -> Bool {
    return recordID == record.recordID &&
    recordType == record.recordType &&
    record.recordChangeTag == record.recordChangeTag
  }
}
