@testable import Canopy
import CanopyTestTools
import CloudKit
import Foundation
import Testing

@Suite struct QueryRecordsFeatureTests {
  private func records(startIndex: Int, endIndex: Int) -> [CKRecord] {
    stride(from: startIndex, to: endIndex + 1, by: 1).map { i in
      CKRecord(recordType: "TestRecord", recordID: .init(recordName: "id\(i)"))
    }
  }
  
  @Test func test_simple_query() async {
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
    
    #expect(results.count == 10)
    let operationsRun = await db.operationsRun
    #expect(operationsRun == 1)
  }
  
  @Test func test_simple_nested_query() async {
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
    #expect(records.count == 20)
    let operationsRun = await db.operationsRun
    #expect(operationsRun == 2)
    #expect(records[0].recordID.recordName == "id1")
    #expect(records[19].recordID.recordName == "id20")
  }
  
  @Test func test_results_limit_query() async {
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
    #expect(records.count == 10)
    let operationsRun = await db.operationsRun
    #expect(operationsRun == 1)
    #expect(records[0].recordID.recordName == "id1")
    #expect(records[9].recordID.recordName == "id10")
  }
  
  @Test func test_depth3_query() async {
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
    
    #expect(records.count == 9)
    let operationsRun = await db.operationsRun
    #expect(operationsRun == 3)
    #expect(records[0].recordID.recordName == "id1")
    #expect(records[8].recordID.recordName == "id9")
  }
  
  @Test func test_task_cancellation_query() async {
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
    } catch let recordError {
      #expect(recordError == .init(from: CKError(CKError.Code.operationCancelled)))
    }
    
    let operationsRun = await db.operationsRun
    #expect(operationsRun == 1)
  }
  
  @Test func test_record_error() async {
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
      #expect(error == CKRecordError(from: CKError(CKError.Code.requestRateLimited)))
    }
  }
  
  @Test func test_nested_request_error() async {
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
      #expect(error == CKRecordError(from: CKError(CKError.Code.networkFailure)))
    }
  }
}
