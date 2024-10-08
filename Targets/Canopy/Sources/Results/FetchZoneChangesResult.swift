import CloudKit
import Foundation

public struct FetchZoneChangesResult: Sendable, Codable {
  public let changedRecords: [CanopyResultRecord]
  public let deletedRecords: [DeletedCKRecord]
  
  public init(records: [CanopyResultRecord], deletedRecords: [DeletedCKRecord]) {
    self.changedRecords = records
    self.deletedRecords = deletedRecords
  }
  
  public static var empty: FetchZoneChangesResult {
    FetchZoneChangesResult(records: [], deletedRecords: [])
  }
}
