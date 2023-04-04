@testable import Canopy
import CloudKit
import XCTest

final class CKRecordZoneIDExtensionTests: XCTestCase {
  func test_private_zone() {
    let privateZoneID = CKRecordZone.ID(zoneName: "someZone", ownerName: CKCurrentUserDefaultName)
    XCTAssertEqual(privateZoneID.ckDatabaseScope, .private)
  }
  
  func test_shared_zone() {
    let sharedZoneID = CKRecordZone.ID(zoneName: "someSharedZone", ownerName: "someOtherPerson")
    XCTAssertEqual(sharedZoneID.ckDatabaseScope, .shared)
  }
}
