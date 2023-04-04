@testable import Canopy
import CloudKit
import XCTest

final class ResultsTypesTests: XCTestCase {
  func test_empty_database_changes_result() {
    let empty = FetchDatabaseChangesResult.empty
    XCTAssertEqual(
      empty,
      .init(
        changedRecordZoneIDs: [],
        deletedRecordZoneIDs: [],
        purgedRecordZoneIDs: []
      )
    )
  }
  
  func test_deleted_ckrecord() {
    let zoneID = CKRecordZone.ID(zoneName: "someZone", ownerName: "someOtherPerson")
    let recordID = CKRecord.ID(recordName: "deletedRecordID", zoneID: zoneID)
    let deletedCKRecord = DeletedCKRecord(recordID: recordID, recordType: "DeletedRecordType")
    XCTAssertEqual(deletedCKRecord.recordType, "DeletedRecordType")
    XCTAssertEqual(deletedCKRecord.recordID, recordID)
  }
}
