@testable import Canopy
import CanopyTestTools
import CanopyTypes
import CloudKit
import Foundation
import XCTest

final class QueryRecordsFeatureTests: XCTestCase {
  func records(startIndex: Int, endIndex: Int) -> [CKRecord] {
    stride(from: startIndex, to: endIndex + 1, by: 1).map { i in
      CKRecord(recordType: "TestRecord", recordID: .init(recordName: "id\(i)"))
    }
  }
  
  func test_simple_query() async {
    let query = CKQuery(recordType: "TestRecord", predicate: NSPredicate(value: true))
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .query(
          .init(
            queryRecordResults:
            records(startIndex: 1, endIndex: 10).map {
              ReplayingMockCKDatabase.QueryRecordResult(recordID: $0.recordID, result: .success($0))
            },
            queryResult: .init(result: .success(nil))
          )
        )
      ]
    )
    let results = try! await QueryRecords.with(
      query,
      recordZoneID: nil,
      database: db
    ).get()
    
    XCTAssertEqual(results.count, 10)
    let operationsRun = await db.operationsRun
    XCTAssertEqual(operationsRun, 1)
  }
  
  func test_simple_nested_query() async {
    let query = CKQuery(recordType: "TestRecord", predicate: NSPredicate(value: true))
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .query(
          .init(
            queryRecordResults: records(startIndex: 1, endIndex: 10).map {
              ReplayingMockCKDatabase.QueryRecordResult(recordID: $0.recordID, result: .success($0))
            },
            queryResult: .init(result: .success(CKQueryOperation.Cursor.mock))
          )
        ),
        .query(
          .init(
            queryRecordResults: records(startIndex: 11, endIndex: 20).map {
              ReplayingMockCKDatabase.QueryRecordResult(recordID: $0.recordID, result: .success($0))
            }, queryResult: .init(result: .success(nil))
          )
        )
      ]
    )
    
    let records = try! await QueryRecords.with(
      query,
      recordZoneID: nil,
      database: db
    ).get()
    XCTAssertEqual(records.count, 20)
    let operationsRun = await db.operationsRun
    XCTAssertEqual(operationsRun, 2)
    XCTAssertEqual(records[0].recordID.recordName, "id1")
    XCTAssertEqual(records[19].recordID.recordName, "id20")
  }
  
  func test_results_limit_query() async {
    let query = CKQuery(recordType: "TestRecord", predicate: NSPredicate(value: true))
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .query(
          .init(
            queryRecordResults: records(startIndex: 1, endIndex: 10).map {
              ReplayingMockCKDatabase.QueryRecordResult(recordID: $0.recordID, result: .success($0))
            },
            queryResult: .init(result: .success(CKQueryOperation.Cursor.mock))
          )
        )
      ]
    )
    
    let records = try! await QueryRecords.with(
      query,
      recordZoneID: nil,
      database: db,
      resultsLimit: 10
    ).get()
    XCTAssertEqual(records.count, 10)
    let operationsRun = await db.operationsRun
    XCTAssertEqual(operationsRun, 1)
    XCTAssertEqual(records[0].recordID.recordName, "id1")
    XCTAssertEqual(records[9].recordID.recordName, "id10")
  }
  
  func test_depth3_query() async {
    let query = CKQuery(recordType: "TestRecord", predicate: NSPredicate(value: true))
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .query(
          .init(
            queryRecordResults: records(startIndex: 1, endIndex: 3).map {
              ReplayingMockCKDatabase.QueryRecordResult(recordID: $0.recordID, result: .success($0))
            },
            queryResult: .init(result: .success(CKQueryOperation.Cursor.mock))
          )
        ),
        .query(
          .init(
            queryRecordResults: records(startIndex: 4, endIndex: 6).map {
              ReplayingMockCKDatabase.QueryRecordResult(recordID: $0.recordID, result: .success($0))
            },
            queryResult: .init(result: .success(CKQueryOperation.Cursor.mock))
          )
        ),
        .query(
          .init(
            queryRecordResults: records(startIndex: 7, endIndex: 9).map {
              ReplayingMockCKDatabase.QueryRecordResult(recordID: $0.recordID, result: .success($0))
            },
            queryResult: .init(result: .success(nil))
          )
        )
      ]
    )
    
    let records = try! await QueryRecords.with(
      query,
      recordZoneID: nil,
      database: db
    ).get()
    
    XCTAssertEqual(records.count, 9)
    let operationsRun = await db.operationsRun
    XCTAssertEqual(operationsRun, 3)
    XCTAssertEqual(records[0].recordID.recordName, "id1")
    XCTAssertEqual(records[8].recordID.recordName, "id9")
  }
  
  func test_task_cancellation_query() async {
    let query = CKQuery(recordType: "TestRecord", predicate: NSPredicate(value: true))
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .query(
          .init(
            queryRecordResults: records(startIndex: 1, endIndex: 10).map {
              ReplayingMockCKDatabase.QueryRecordResult(recordID: $0.recordID, result: .success($0))
            },
            queryResult: .init(result: .success(CKQueryOperation.Cursor.mock))
          )
        ),
        .query(
          .init(
            queryRecordResults: records(startIndex: 11, endIndex: 20).map {
              ReplayingMockCKDatabase.QueryRecordResult(recordID: $0.recordID, result: .success($0))
            },
            queryResult: .init(result: .success(nil))
          )
        )
      ]
    )
    
    let task = Task {
      await QueryRecords.with(
        query,
        recordZoneID: nil,
        database: db
      )
    }
    
    task.cancel()
    
    do {
      let _ = try await task.result.get().get()
    } catch {
      XCTAssertEqual(error as! CKRecordError, .init(from: CKError(CKError.Code.operationCancelled)))
    }
    
    let operationsRun = await db.operationsRun
    XCTAssertEqual(operationsRun, 1)
  }
  
  func test_record_error() async {
    let query = CKQuery(recordType: "TestRecord", predicate: NSPredicate(value: true))
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .query(
          .init(
            queryRecordResults:
            records(startIndex: 1, endIndex: 10).map {
              ReplayingMockCKDatabase.QueryRecordResult(recordID: $0.recordID, result: .failure(CKError(CKError.Code.requestRateLimited)))
            },
            queryResult: .init(result: .success(nil))
          )
        )
      ]
    )
    do {
      let _ = try await QueryRecords.with(
        query,
        recordZoneID: nil,
        database: db
      ).get()
    } catch {
      XCTAssertEqual(error as! CKRecordError, CKRecordError(from: CKError(CKError.Code.requestRateLimited)))
    }
  }
  
  func test_nested_request_error() async {
    let query = CKQuery(recordType: "TestRecord", predicate: NSPredicate(value: true))
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .query(
          .init(
            queryRecordResults: records(startIndex: 1, endIndex: 3).map {
              ReplayingMockCKDatabase.QueryRecordResult(recordID: $0.recordID, result: .success($0))
            },
            queryResult: .init(result: .success(CKQueryOperation.Cursor.mock))
          )
        ),
        .query(
          .init(
            queryRecordResults: records(startIndex: 4, endIndex: 6).map {
              ReplayingMockCKDatabase.QueryRecordResult(recordID: $0.recordID, result: .success($0))
            },
            queryResult: .init(result: .failure(CKError(CKError.Code.networkFailure)))
          )
        )
      ]
    )
    
    do {
      let _ = try await QueryRecords.with(
        query,
        recordZoneID: nil,
        database: db
      ).get()
    } catch {
      XCTAssertEqual(error as! CKRecordError, CKRecordError(from: CKError(CKError.Code.networkFailure)))
    }
  }
}
