@testable import Canopy
import CloudKit
import Testing

@Suite struct ResultsTypesTests {
  @Test func test_empty_database_changes_result() {
    let empty = FetchDatabaseChangesResult.empty
    #expect(
      empty ==
      .init(
        changedRecordZoneIDs: [],
        deletedRecordZoneIDs: [],
        purgedRecordZoneIDs: []
      )
    )
  }
  
  @Test func test_deleted_ckrecord() {
    let zoneID = CKRecordZone.ID(zoneName: "someZone", ownerName: "someOtherPerson")
    let recordID = CKRecord.ID(recordName: "deletedRecordID", zoneID: zoneID)
    let deletedCKRecord = DeletedCKRecord(recordID: recordID, recordType: "DeletedRecordType")
    #expect(deletedCKRecord.recordType == "DeletedRecordType")
    #expect(deletedCKRecord.recordID == recordID)
  }
}
