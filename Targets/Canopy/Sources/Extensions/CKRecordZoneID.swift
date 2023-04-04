import CloudKit

public extension CKRecordZone.ID {
  /// Determine a database scope for a record zone.
  ///
  /// This can be derived from the zone owner (who by definition also created the zone).
  /// All zones in private database are created by current user. Zones created by other users
  /// are in the shared zone.
  var ckDatabaseScope: CKDatabase.Scope {
    (ownerName == CKCurrentUserDefaultName) ? .private : .shared
  }
}
