import CloudKit
import Foundation

public struct FetchDatabaseChangesResult: Equatable, Sendable {
  public let changedRecordZoneIDs: [CKRecordZone.ID]
  public let deletedRecordZoneIDs: [CKRecordZone.ID]
  public let purgedRecordZoneIDs: [CKRecordZone.ID]

  public static var empty: FetchDatabaseChangesResult {
    FetchDatabaseChangesResult(
      changedRecordZoneIDs: [],
      deletedRecordZoneIDs: [],
      purgedRecordZoneIDs: []
    )
  }
  
  public init(
    changedRecordZoneIDs: [CKRecordZone.ID],
    deletedRecordZoneIDs: [CKRecordZone.ID],
    purgedRecordZoneIDs: [CKRecordZone.ID]
  ) {
    self.changedRecordZoneIDs = changedRecordZoneIDs
    self.deletedRecordZoneIDs = deletedRecordZoneIDs
    self.purgedRecordZoneIDs = purgedRecordZoneIDs
  }
}
