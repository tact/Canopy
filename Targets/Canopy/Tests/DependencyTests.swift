import Canopy
import CanopyTestTools
import CloudKit
import Dependencies
import Testing

@Suite struct DependencyTests {
  struct Fetcher {
    @Dependency(\.cloudKit) private var canopy
    func fetchRecord(recordID: CKRecord.ID) async -> CanopyResultRecord? {
      try! await canopy.databaseAPI(usingDatabaseScope: .private).fetchRecords(
        with: [recordID]
      ).get().foundRecords.first
    }
  }
  
  @Test func test_dependency() async {
    let fetcher = withDependencies {
      let testRecordID = CKRecord.ID(recordName: "testRecordID")
      let testRecord = CKRecord(recordType: "TestRecord", recordID: testRecordID)
      testRecord["testKey"] = "testValue"
      $0.cloudKit = MockCanopyWithCKMocks(
        mockPrivateCKDatabase: ReplayingMockCKDatabase(
          operationResults: [
            .fetch(
              .init(
                fetchRecordResults: [
                  .init(
                    recordID: testRecordID,
                    result: .success(testRecord)
                  )
                ],
                fetchResult: .init(
                  result: .success(())
                )
              )
            )
          ]
        )
      )
    } operation: {
      Fetcher()
    }
    let record = await fetcher.fetchRecord(recordID: .init(recordName: "testRecordID"))!
    #expect(record["testKey"] as! String == "testValue")
  }
}
