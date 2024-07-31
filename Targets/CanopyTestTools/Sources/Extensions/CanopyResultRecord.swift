import CanopyTypes
import CloudKit

public extension CanopyResultRecord {
  /// A simple comparison to determine record equivalence.
  ///
  /// Doesn’t compare fields.
  func isEqualToRecord(_ record: CanopyResultRecord) -> Bool {
    recordID == record.recordID &&
      recordType == record.recordType &&
      record.recordChangeTag == record.recordChangeTag
  }
}
