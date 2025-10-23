import Canopy
import CanopyTestTools
import CloudKit
import Testing

@Suite struct FetchRecordsResultTests {
  @Test func test_codes() throws {
    let foundRecords = [CanopyResultRecord.mock(.init(recordType: "MockType"))]
    let notFoundRecordIDs = [CKRecord.ID(recordName: "notFoundId")]
    let fetchRecordsResult = FetchRecordsResult(
      foundRecords: foundRecords,
      notFoundRecordIDs: notFoundRecordIDs
    )
    let coded = try JSONEncoder().encode(fetchRecordsResult)
    let decoded = try JSONDecoder().decode(FetchRecordsResult.self, from: coded)
    #expect(fetchRecordsResult == decoded)
  }
  
  @Test func test_throws_on_bad_deleted_ids_data() {
    let badJson = "{\"foundRecords\":[],\"notFoundRecordIDs\":\"deadbeef\"}"
    let data = badJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(FetchRecordsResult.self, from: data)
    } catch DecodingError.dataCorrupted(let context) {
      #expect(context.debugDescription == "Invalid not found record IDs value in source data")
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }
}
