import CloudKit

extension CKRecordZone {
  /// A simple comparison to determine zone equivalence.
  ///
  /// Doesn’t compare fields.
  public func isEqualToZone(_ zone: CKRecordZone) -> Bool {
    return zoneID == zone.zoneID &&
    capabilities == zone.capabilities
  }
}
