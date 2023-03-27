import CloudKit
import Foundation

/// Indicates what kind of changes you want to fetch for a given record zone.
///
/// You always get change tokens when fetching changes. In addition,
/// you can choose to fetch specific or all record key fields.
/// Limiting record key fields may reduce the download size if you are
/// interested only in the tokens, or only some specific fields (but e.g
/// not asset fields that may contain large files).
public enum FetchZoneChangesMethod {
  
  /// Fetch tokens and all available data.
  case changeTokenAndAllData
  
  /// Only fetch specific record fields.
  case changeTokenAndSpecificKeys([CKRecord.FieldKey])
  
  /// Don’t fetch any record data: only fetch the change token.
  ///
  /// This is useful to “catch up” with the current state of the zone, when you
  /// are not interested in all historic changes.
  ///
  /// It would be nice to have this as an API on CloudKit record zones, to fetch
  /// the current change token. Doing a “playback” of all history to get
  /// just the current token is a bit of an inefficient hack/workaround.
  case changeTokenOnly

  var desiredKeys: [CKRecord.FieldKey]? {
    switch self {
    case .changeTokenAndAllData:
      return nil
    case let .changeTokenAndSpecificKeys(keys):
      return keys
    case .changeTokenOnly:
      return []
    }
  }
}
