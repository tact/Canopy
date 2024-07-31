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
  
  func test_modify_records_success() async {
    let db = ReplayingMockDatabase(operationResults: [
      .modifyRecords(
        .init(
          result: .success(
            .init(
              savedRecords: [
                .mock(.init(recordType: "MockType"))
              ],
              deletedRecordIDs: [
                .init(recordName: "deleted0"),
                .init(recordName: "deleted1")
              ]
            )
          )
        )
      )
    ])
    let result = try! await db.modifyRecords(
      saving: [],
      deleting: []
    ).get()
    XCTAssertEqual(result.savedRecords.first!.recordType, "MockType")
    XCTAssertEqual(result.deletedRecordIDs[0].recordName, "deleted0")
    XCTAssertEqual(result.deletedRecordIDs[1].recordName, "deleted1")
  }
  
  func test_modify_records_error() async {
    let db = ReplayingMockDatabase(operationResults: [
      .modifyRecords(.init(result: .failure(.init(from: CKError(CKError.Code.networkFailure)))))
    ])
    do {
      let _ = try await db.modifyRecords(saving: [], deleting: []).get()
    } catch let recordError as CKRecordError {
      XCTAssertEqual(recordError, CKRecordError(from: CKError(CKError.Code.networkFailure)))
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
  
  func test_delete_records_success() async {
    let db = ReplayingMockDatabase(operationResults: [
      .deleteRecords(
        .init(
          result: .success(
            .init(
              savedRecords: [],
              deletedRecordIDs: [
                .init(recordName: "deleted0"),
                .init(recordName: "deleted1")
              ]
            )
          )
        )
      )
    ])
    let result = try! await db.deleteRecords(with: CKQuery(recordType: "SomeType", predicate: NSPredicate(value: true)), in: nil).get()
    XCTAssertEqual(result.deletedRecordIDs[0].recordName, "deleted0")
    XCTAssertEqual(result.deletedRecordIDs[1].recordName, "deleted1")
  }
  
  func test_delete_records_error() async {
    let db = ReplayingMockDatabase(operationResults: [
      .deleteRecords(.init(result: .failure(.init(from: CKError(CKError.Code.networkFailure)))))
    ])
    do {
      let _ = try await db.deleteRecords(with: CKQuery(recordType: "SomeType", predicate: NSPredicate(value: true)), in: nil).get()
    } catch let recordError as CKRecordError {
      XCTAssertEqual(recordError, CKRecordError(from: CKError(CKError.Code.networkFailure)))
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
  
  func test_fetch_records_success() async {
    let db = ReplayingMockDatabase(operationResults: [
      .fetchRecords(
        .init(
          result: .success(
            .init(
              foundRecords: [
                .mock(.init(recordID: .init(recordName: "record1"), recordType: "MockType")),
                .mock(.init(recordID: .init(recordName: "record2"), recordType: "MockType"))
              ],
              notFoundRecordIDs: [
                .init(recordName: "notFound1"),
                .init(recordName: "notFound2"),
                .init(recordName: "notFound3")
              ]
            )
          )
        )
      )
    ])
    let result = try! await db.fetchRecords(with: []).get()
    XCTAssertEqual(result.foundRecords[0].recordID.recordName, "record1")
    XCTAssertEqual(result.foundRecords[1].recordID.recordName, "record2")
    XCTAssertEqual(result.notFoundRecordIDs[0].recordName, "notFound1")
    XCTAssertEqual(result.notFoundRecordIDs[1].recordName, "notFound2")
    XCTAssertEqual(result.notFoundRecordIDs[2].recordName, "notFound3")
  }
  
  func test_fetch_records_error() async {
    let db = ReplayingMockDatabase(operationResults: [
      .fetchRecords(.init(result: .failure(.init(from: CKError(CKError.Code.networkFailure)))))
    ])
    do {
      let _ = try await db.fetchRecords(with: []).get()
    } catch let recordError as CKRecordError {
      XCTAssertEqual(recordError, CKRecordError(from: CKError(CKError.Code.networkFailure)))
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}
