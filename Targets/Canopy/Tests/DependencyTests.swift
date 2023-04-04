import Canopy
import CanopyTestTools
import CloudKit
import Dependencies
import XCTest

final class DependencyTests: XCTestCase {
  struct Fetcher {
    @Dependency(\.cloudKit) var canopy
    func fetchRecord(recordID: CKRecord.ID) async -> CKRecord? {
      try! await canopy.databaseAPI(usingDatabaseScope: .private).fetchRecords(
        with: [recordID]
      ).get().foundRecords.first
    }
  }
  
  func test_dependency() async {
    let fetcher = withDependencies {
      let testRecordID = CKRecord.ID(recordName: "testRecordID")
      let testRecord = CKRecord(recordType: "TestRecord", recordID: testRecordID)
      testRecord["testKey"] = "testValue"
      $0.cloudKit = MockCanopy(
        mockPrivateDatabase: ReplayingMockCKDatabase(
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
    XCTAssertEqual(record["testKey"], "testValue")
  }
}
