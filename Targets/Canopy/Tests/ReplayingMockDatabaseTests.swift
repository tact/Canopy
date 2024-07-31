import CanopyTestTools
import CanopyTypes
import CloudKit
import XCTest

final class ReplayingMockDatabaseTests: XCTestCase {
  func test_query_records_success() async {
    let db = ReplayingMockDatabase(operationResults: [
      .queryRecords(
        .init(
          result: .success([
            .mock(.init(recordID: .init(recordName: "mockName"), recordType: "MockType"))
          ])
        )
      )
    ])
    let result = try! await db.queryRecords(with: .init(recordType: "MockType", predicate: NSPredicate(value: true)), in: nil).get()
    XCTAssertEqual(result.first!.recordID.recordName, "mockName")
  }
  
  func test_query_records_failure() async {
    let db = ReplayingMockDatabase(operationResults: [
      .queryRecords(.init(result: .failure(.init(from: CKError(CKError.Code.badDatabase)))))
    ])
    do {
      let _ = try await db.queryRecords(with: .init(recordType: "MockType", predicate: NSPredicate(value: true)), in: nil).get()
    } catch let recordError as CKRecordError {
      XCTAssertEqual(recordError, CKRecordError(from: CKError(CKError.Code.badDatabase)))
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}
