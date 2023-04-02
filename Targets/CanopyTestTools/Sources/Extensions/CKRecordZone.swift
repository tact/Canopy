import CloudKit

public extension CKRecordZone {
  /// A simple comparison to determine zone equivalence.
  ///
  /// Doesn’t compare fields.
  func isEqualToZone(_ zone: CKRecordZone) -> Bool {
    zoneID == zone.zoneID &&
      capabilities == zone.capabilities
  }
}
