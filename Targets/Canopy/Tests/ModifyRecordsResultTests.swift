import CanopyTestTools
import CanopyTypes
import CloudKit
import XCTest

final class ModifyRecordsResultTests: XCTestCase {
  func test_codes() throws {
    let savedRecords = [CanopyResultRecord.mock(.init(recordType: "MockType"))]
    let deletedRecordIDs = [CKRecord.ID(recordName: "deletedId")]
    let modifyRecordsResult = ModifyRecordsResult(
      savedRecords: savedRecords,
      deletedRecordIDs: deletedRecordIDs
    )
    let coded = try JSONEncoder().encode(modifyRecordsResult)
    let decoded = try JSONDecoder().decode(ModifyRecordsResult.self, from: coded)
    XCTAssertEqual(modifyRecordsResult, decoded)
  }
  
  func test_throws_on_bad_deleted_ids_data() {
    let badJson = "{\"savedRecords\":[],\"deletedRecordIDs\":\"deadbeef\"}"
    let data = badJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(ModifyRecordsResult.self, from: data)
    } catch DecodingError.dataCorrupted(let context) {
      XCTAssertEqual(context.debugDescription, "Invalid deleted record IDs value in source data")
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}
