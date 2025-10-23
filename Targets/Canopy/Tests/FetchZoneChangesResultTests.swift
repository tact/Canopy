import Canopy
import CloudKit
import Testing

@Suite struct FetchZoneChangesResultTests {
  @Test func test_codes() throws {
    let result = FetchZoneChangesResult(
      records: [.mock(.init(recordID: .init(recordName: "recordName1"), recordType: "SomeType"))],
      deletedRecords: [.init(recordID: .init(recordName: "deletedId1"), recordType: "SomeDeletedType")]
    )
    let coded = try JSONEncoder().encode(result)
    let decoded = try JSONDecoder().decode(FetchZoneChangesResult.self, from: coded)
    #expect(decoded.changedRecords[0].recordID.recordName == "recordName1")
    #expect(decoded.deletedRecords[0].recordID.recordName == "deletedId1")
  }
  
  @Test func test_empty() {
    let result = FetchZoneChangesResult.empty
    #expect(result.changedRecords.isEmpty == true)
    #expect(result.deletedRecords.isEmpty == true)
  }
}
