import CanopyTypes
import CloudKit
import XCTest

final class FetchZoneChangesResultTests: XCTestCase {
  func test_codes() throws {
    let result = FetchZoneChangesResult(
      records: [.mock(.init(recordID: .init(recordName: "recordName1"), recordType: "SomeType"))],
      deletedRecords: [.init(recordID: .init(recordName: "deletedId1"), recordType: "SomeDeletedType")]
    )
    let coded = try JSONEncoder().encode(result)
    let decoded = try JSONDecoder().decode(FetchZoneChangesResult.self, from: coded)
    XCTAssertEqual(decoded.changedRecords[0].recordID.recordName, "recordName1")
    XCTAssertEqual(decoded.deletedRecords[0].recordID.recordName, "deletedId1")
  }
  
  func test_empty() {
    let result = FetchZoneChangesResult.empty
    XCTAssertTrue(result.changedRecords.isEmpty)
    XCTAssertTrue(result.deletedRecords.isEmpty)
  }
}
