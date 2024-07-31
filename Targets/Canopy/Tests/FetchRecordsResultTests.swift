import CanopyTestTools
import CanopyTypes
import CloudKit
import XCTest

final class FetchRecordsResultTests: XCTestCase {
  func test_codes() throws {
    let foundRecords = [CanopyResultRecord.mock(.init(recordType: "MockType"))]
    let notFoundRecordIDs = [CKRecord.ID(recordName: "notFoundId")]
    let fetchRecordsResult = FetchRecordsResult(
      foundRecords: foundRecords,
      notFoundRecordIDs: notFoundRecordIDs
    )
    let coded = try JSONEncoder().encode(fetchRecordsResult)
    let decoded = try JSONDecoder().decode(FetchRecordsResult.self, from: coded)
    XCTAssertEqual(fetchRecordsResult, decoded)
  }
  
  func test_throws_on_bad_deleted_ids_data() {
    let badJson = "{\"foundRecords\":[],\"notFoundRecordIDs\":\"deadbeef\"}"
    let data = badJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(FetchRecordsResult.self, from: data)
    } catch DecodingError.dataCorrupted(let context) {
      XCTAssertEqual(context.debugDescription, "Invalid not found record IDs value in source data")
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}
