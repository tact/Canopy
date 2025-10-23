@testable import Canopy
import CloudKit
import Testing

@Suite struct CKRecordZoneIDExtensionTests {
  @Test func test_private_zone() {
    let privateZoneID = CKRecordZone.ID(zoneName: "someZone", ownerName: CKCurrentUserDefaultName)
    #expect(privateZoneID.ckDatabaseScope == .private)
  }
  
  @Test func test_shared_zone() {
    let sharedZoneID = CKRecordZone.ID(zoneName: "someSharedZone", ownerName: "someOtherPerson")
    #expect(sharedZoneID.ckDatabaseScope == .shared)
  }
}
