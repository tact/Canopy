import CloudKit
import Foundation

public struct FetchZoneChangesResult {
  public let changedRecords: [CKRecord]
  public let deletedRecords: [DeletedCKRecord]
  
  public init(records: [CKRecord], deletedRecords: [DeletedCKRecord]) {
    self.changedRecords = records
    self.deletedRecords = deletedRecords
  }
  
  public static var empty: FetchZoneChangesResult {
    FetchZoneChangesResult(records: [], deletedRecords: [])
  }
}
