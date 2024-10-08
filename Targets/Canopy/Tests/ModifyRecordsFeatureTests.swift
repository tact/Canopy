@testable import Canopy
import CanopyTestTools
import CanopyTypes
import CloudKit
import Foundation
import XCTest

final class ModifyRecordsFeatureTests: XCTestCase {
  private func records(startIndex: Int, endIndex: Int) -> [CKRecord] {
    stride(from: startIndex, to: endIndex + 1, by: 1).map { i in
      CKRecord(recordType: "TestRecord", recordID: .init(recordName: "id\(i)"))
    }
  }
  
  private var modify_zoneBusy_result: ReplayingMockCKDatabase.OperationResult {
    .modify(
      .init(
        savedRecordResults: [],
        deletedRecordIDResults: [],
        modifyResult: .init(
          result: .failure(
            CKError(
              CKError.Code.zoneBusy,
              userInfo: [CKErrorRetryAfterKey: 0.2]
            )
          )
        )
      )
    )
  }
  
  func test_fails_correctly_on_empty_input() async {
    let db = ReplayingMockCKDatabase(operationResults: [])
    do {
      let _ = try await ModifyRecords.with(
        recordsToSave: [],
        recordIDsToDelete: [],
        perRecordProgressBlock: nil,
        database: db,
        qualityOfService: .default
      ).get()
    } catch let recordError {
      XCTAssertEqual(recordError, CKRecordError(from: CKError(CKError.Code.internalError)))
    }
  }
  
  func test_simple_modify() async {
    let recordsToSave = records(startIndex: 1, endIndex: 10)
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .modify(
          .init(
            savedRecordResults:
            recordsToSave.map {
              ReplayingMockCKDatabase.SavedRecordResult(
                recordID: $0.recordID,
                result: .success($0)
              )
            },
            deletedRecordIDResults: [],
            modifyResult: ReplayingMockCKDatabase.ModifyResult(result: .success(()))
          )
        )
      ]
    )
    let result = try! await ModifyRecords.with(
      recordsToSave: recordsToSave,
      recordIDsToDelete: nil,
      perRecordProgressBlock: nil,
      database: db,
      qualityOfService: .default
    ).get()
    
    XCTAssertEqual(result.savedRecords.count, 10)
    XCTAssertEqual(result.deletedRecordIDs.count, 0)
    
    let operationsRun = await db.operationsRun
    XCTAssertEqual(operationsRun, 1)
  }
  
  func test_simple_delete() async {
    let recordIDsToDelete = records(startIndex: 1, endIndex: 10).map(\.recordID)
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .modify(
          .init(
            savedRecordResults: [],
            deletedRecordIDResults: recordIDsToDelete.map {
              ReplayingMockCKDatabase.DeletedRecordIDResult(
                recordID: $0,
                result: .success(())
              )
            },
            modifyResult: .init(result: .success(()))
          )
        )
      ]
    )
    let result = try! await ModifyRecords.with(
      recordsToSave: nil,
      recordIDsToDelete: recordIDsToDelete,
      perRecordProgressBlock: nil,
      database: db,
      qualityOfService: .default
    ).get()
    
    XCTAssertEqual(result.deletedRecordIDs.count, 10)
    XCTAssertEqual(result.savedRecords.count, 0)
    
    let operationsRun = await db.operationsRun
    XCTAssertEqual(operationsRun, 1)
  }
  
  func test_chunked_modify() async {
    let recordsToSave1 = records(startIndex: 1, endIndex: 3)
    let recordsToSave2 = records(startIndex: 4, endIndex: 6)
    let recordsToSave3 = records(startIndex: 7, endIndex: 9)
    let recordsToSave4 = records(startIndex: 10, endIndex: 11)
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .modify(
          .init(
            savedRecordResults:
            recordsToSave1.map {
              ReplayingMockCKDatabase.SavedRecordResult(
                recordID: $0.recordID,
                result: .success($0)
              )
            },
            deletedRecordIDResults: [],
            modifyResult: .init(result: .success(()))
          )
        ),
        .modify(
          .init(
            savedRecordResults:
            recordsToSave2.map {
              ReplayingMockCKDatabase.SavedRecordResult(
                recordID: $0.recordID,
                result: .success($0)
              )
            },
            deletedRecordIDResults: [],
            modifyResult: .init(result: .success(()))
          )
        ),
        .modify(
          .init(
            savedRecordResults:
            recordsToSave3.map {
              ReplayingMockCKDatabase.SavedRecordResult(
                recordID: $0.recordID,
                result: .success($0)
              )
            },
            deletedRecordIDResults: [],
            modifyResult: .init(result: .success(()))
          )
        ),
        .modify(
          .init(
            savedRecordResults:
            recordsToSave4.map {
              ReplayingMockCKDatabase.SavedRecordResult(
                recordID: $0.recordID,
                result: .success($0)
              )
            },
            deletedRecordIDResults: [],
            modifyResult: .init(result: .success(()))
          )
        )
      ]
    )
    let result = try! await ModifyRecords.with(
      recordsToSave: recordsToSave1 + recordsToSave2 + recordsToSave3 + recordsToSave4,
      recordIDsToDelete: nil,
      perRecordProgressBlock: nil,
      database: db,
      qualityOfService: .default,
      customBatchSize: 3
    ).get()
    
    XCTAssertEqual(result.savedRecords.count, 11)
    XCTAssertEqual(result.deletedRecordIDs.count, 0)
    
    let operationsRun = await db.operationsRun
    XCTAssertEqual(operationsRun, 4)
  }
  
  func test_cancellation() async {
    let recordsToSave1 = records(startIndex: 1, endIndex: 3)
    let recordsToSave2 = records(startIndex: 4, endIndex: 6)
    let recordsToSave3 = records(startIndex: 7, endIndex: 9)
    let recordsToSave4 = records(startIndex: 10, endIndex: 11)
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .modify(
          .init(
            savedRecordResults:
            recordsToSave1.map {
              ReplayingMockCKDatabase.SavedRecordResult(
                recordID: $0.recordID,
                result: .success($0)
              )
            },
            deletedRecordIDResults: [],
            modifyResult: .init(result: .success(()))
          )
        ),
        .modify(
          .init(
            savedRecordResults:
            recordsToSave2.map {
              ReplayingMockCKDatabase.SavedRecordResult(
                recordID: $0.recordID,
                result: .success($0)
              )
            },
            deletedRecordIDResults: [],
            modifyResult: .init(result: .success(()))
          )
        ),
        .modify(
          .init(
            savedRecordResults:
            recordsToSave3.map {
              ReplayingMockCKDatabase.SavedRecordResult(
                recordID: $0.recordID,
                result: .success($0)
              )
            },
            deletedRecordIDResults: [],
            modifyResult: .init(result: .success(()))
          )
        ),
        .modify(
          .init(
            savedRecordResults:
            recordsToSave4.map {
              ReplayingMockCKDatabase.SavedRecordResult(
                recordID: $0.recordID,
                result: .success($0)
              )
            },
            deletedRecordIDResults: [],
            modifyResult: .init(result: .success(()))
          )
        )
      ]
    )
    
    let task = Task {
      await ModifyRecords.with(
        recordsToSave: recordsToSave1 + recordsToSave2 + recordsToSave3 + recordsToSave4,
        recordIDsToDelete: nil,
        perRecordProgressBlock: nil,
        database: db,
        qualityOfService: .default,
        customBatchSize: 3
      )
    }
    
    task.cancel()
    
    do {
      // First get gets the task result and will succeed.
      // Second get gets the operation result, and this will throw because the operation resulted with error.
      let _ = try await task.result.get().get()
    } catch {
      XCTAssertEqual(error, CKRecordError(from: CKError(CKError.Code.operationCancelled)))
    }
    
    let operationsRun = await db.operationsRun
    XCTAssertEqual(operationsRun, 1)
  }
  
  func test_modify_recorderror() async {
    let recordsToSave = records(startIndex: 1, endIndex: 10)
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .modify(
          .init(
            savedRecordResults:
            recordsToSave.map {
              ReplayingMockCKDatabase.SavedRecordResult(
                recordID: $0.recordID,
                result: .failure(CKError(CKError.Code.internalError))
              )
            },
            deletedRecordIDResults: [],
            modifyResult: .init(result: .success(()))
          )
        )
      ]
    )
    do {
      let _ = try await ModifyRecords.with(
        recordsToSave: recordsToSave,
        recordIDsToDelete: nil,
        perRecordProgressBlock: nil,
        database: db,
        qualityOfService: .default
      ).get()
    } catch {
      XCTAssertEqual(error, CKRecordError(from: CKError(CKError.Code.internalError)))
    }
    
    let operationsRun = await db.operationsRun
    XCTAssertEqual(operationsRun, 1)
  }
  
  func test_delete_recorderror() async {
    let recordIDsToDelete = records(startIndex: 1, endIndex: 10).map(\.recordID)
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .modify(
          .init(
            savedRecordResults: [],
            deletedRecordIDResults: recordIDsToDelete.map {
              ReplayingMockCKDatabase.DeletedRecordIDResult(
                recordID: $0,
                result: .failure(CKError(CKError.Code.internalError))
              )
            },
            modifyResult: .init(result: .success(()))
          )
        )
      ]
    )
    do {
      let _ = try await ModifyRecords.with(
        recordsToSave: nil,
        recordIDsToDelete: recordIDsToDelete,
        perRecordProgressBlock: nil,
        database: db,
        qualityOfService: .default
      ).get()
    } catch {
      XCTAssertEqual(error, CKRecordError(from: CKError(CKError.Code.internalError)))
    }

    let operationsRun = await db.operationsRun
    XCTAssertEqual(operationsRun, 1)
  }
  
  func test_modify_resulterror() async {
    let recordsToSave = records(startIndex: 1, endIndex: 10)
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .modify(
          .init(
            savedRecordResults:
            recordsToSave.map {
              ReplayingMockCKDatabase.SavedRecordResult(
                recordID: $0.recordID,
                result: .success($0)
              )
            },
            deletedRecordIDResults: [],
            modifyResult: .init(result: .failure(CKError(CKError.Code.networkFailure)))
          )
        )
      ]
    )
    do {
      let _ = try await ModifyRecords.with(
        recordsToSave: recordsToSave,
        recordIDsToDelete: nil,
        perRecordProgressBlock: nil,
        database: db,
        qualityOfService: .default
      ).get()
    } catch {
      XCTAssertEqual(error, CKRecordError(from: CKError(CKError.Code.networkFailure)))
    }
    
    let operationsRun = await db.operationsRun
    XCTAssertEqual(operationsRun, 1)
  }
  
  func test_limit_exceeded() async {
    let recordsToSave = records(startIndex: 1, endIndex: 9)
    let recordIDToDelete = CKRecord.ID(recordName: "idToDelete")
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .modify(
          .init(
            savedRecordResults: [],
            deletedRecordIDResults: [],
            modifyResult: .init(result: .failure(CKError(CKError.Code.limitExceeded)))
          )
        ),
        .modify(
          .init(
            savedRecordResults: recordsToSave[0...3].map {
              ReplayingMockCKDatabase.SavedRecordResult(recordID: $0.recordID, result: .success($0))
            },
            deletedRecordIDResults: [
              ReplayingMockCKDatabase.DeletedRecordIDResult(
                recordID: recordIDToDelete,
                result: .success(())
              )
            ],
            modifyResult: .init(result: .success(()))
          )
        ),
        .modify(
          .init(
            savedRecordResults: recordsToSave[4...7].map {
              ReplayingMockCKDatabase.SavedRecordResult(recordID: $0.recordID, result: .success($0))
            },
            deletedRecordIDResults: [],
            modifyResult: .init(result: .success(()))
          )
        ),
        .modify(
          .init(
            savedRecordResults: [recordsToSave[8]].map {
              ReplayingMockCKDatabase.SavedRecordResult(recordID: $0.recordID, result: .success($0))
            },
            deletedRecordIDResults: [],
            modifyResult: .init(result: .success(()))
          )
        )
      ]
    )
    
    let result = try! await ModifyRecords.with(
      recordsToSave: recordsToSave,
      recordIDsToDelete: [recordIDToDelete],
      perRecordProgressBlock: nil,
      database: db,
      qualityOfService: .default,
      customBatchSize: 9
    ).get()

    XCTAssertEqual(result.savedRecords.count, 9)
    for index in 0 ..< result.savedRecords.count {
      XCTAssertTrue(result.savedRecords[index].isEqualToRecord(recordsToSave[index].canopyResultRecord))
    }
    XCTAssertEqual(result.deletedRecordIDs.count, 1)

    let operationsRun = await db.operationsRun
    XCTAssertEqual(operationsRun, 4)
  }
  
  func test_limit_exceeded_without_autobatch() async {
    let recordsToSave = records(startIndex: 1, endIndex: 9)
    let recordIDToDelete = CKRecord.ID(recordName: "idToDelete")
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .modify(
          .init(
            savedRecordResults: [],
            deletedRecordIDResults: [],
            modifyResult: .init(result: .failure(CKError(CKError.Code.limitExceeded)))
          )
        )
      ]
    )
    
    do {
      let _ = try await ModifyRecords.with(
        recordsToSave: recordsToSave,
        recordIDsToDelete: [recordIDToDelete],
        perRecordProgressBlock: nil,
        database: db,
        qualityOfService: .default,
        customBatchSize: 9,
        autoBatchToSmallerWhenLimitExceeded: false
      ).get()
    } catch {
      XCTAssertEqual(error, CKRecordError(from: CKError(CKError.Code.limitExceeded)))
      let operationsRun = await db.operationsRun
      XCTAssertEqual(operationsRun, 1)
    }
  }
  
  func test_autoretry_one_pass() async {
    let recordsToSave = records(startIndex: 0, endIndex: 0)
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .modify(
          .init(
            savedRecordResults: [
              .init(
                recordID: recordsToSave[0].recordID,
                result: .success(recordsToSave[0])
              )
            ],
            deletedRecordIDResults: [],
            modifyResult: .init(result: .success(()))
          )
        )
      ]
    )
    let result = try! await ModifyRecords.with(
      recordsToSave: recordsToSave,
      recordIDsToDelete: nil,
      perRecordProgressBlock: nil,
      database: db,
      qualityOfService: .default,
      autoRetryForRetriableErrors: true
    ).get()
    XCTAssertTrue(result.savedRecords[0].isEqualToRecord(recordsToSave[0].canopyResultRecord))
    XCTAssertEqual(result.savedRecords.count, 1)
    let operationsRun = await db.operationsRun
    XCTAssertEqual(operationsRun, 1)
  }
  
  func test_autoretry_one_retry() async {
    let recordsToSave = records(startIndex: 0, endIndex: 0)
    let db = ReplayingMockCKDatabase(
      operationResults: [
        modify_zoneBusy_result,
        .modify(
          .init(savedRecordResults: [
            .init(recordID: recordsToSave[0].recordID, result: .success(recordsToSave[0]))
          ], deletedRecordIDResults: [], modifyResult: .init(result: .success(()))))
      ]
    )
    let result = try! await ModifyRecords.with(
      recordsToSave: recordsToSave,
      recordIDsToDelete: nil,
      perRecordProgressBlock: nil,
      database: db,
      qualityOfService: .default,
      autoRetryForRetriableErrors: true
    ).get()
    XCTAssertTrue(result.savedRecords[0].isEqualToRecord(recordsToSave[0].canopyResultRecord))
    XCTAssertEqual(result.savedRecords.count, 1)
    let operationsRun = await db.operationsRun
    XCTAssertEqual(operationsRun, 2)
  }
  
  func test_autoretry_two_retries() async {
    let recordsToSave = records(startIndex: 0, endIndex: 0)
    let db = ReplayingMockCKDatabase(
      operationResults: [
        modify_zoneBusy_result,
        modify_zoneBusy_result,
        .modify(
          .init(savedRecordResults: [
            .init(recordID: recordsToSave[0].recordID, result: .success(recordsToSave[0]))
          ], deletedRecordIDResults: [], modifyResult: .init(result: .success(()))))
      ]
    )
    let result = try! await ModifyRecords.with(
      recordsToSave: recordsToSave,
      recordIDsToDelete: nil,
      perRecordProgressBlock: nil,
      database: db,
      qualityOfService: .default,
      autoRetryForRetriableErrors: true
    ).get()
    XCTAssertTrue(result.savedRecords[0].isEqualToRecord(recordsToSave[0].canopyResultRecord))
    XCTAssertEqual(result.savedRecords.count, 1)
    let operationsRun = await db.operationsRun
    XCTAssertEqual(operationsRun, 3)
  }
  
  func test_autoretry_three_retries_failure() async {
    let recordsToSave = records(startIndex: 0, endIndex: 0)
    let db = ReplayingMockCKDatabase(
      operationResults: [
        modify_zoneBusy_result,
        modify_zoneBusy_result,
        modify_zoneBusy_result
      ]
    )
    do {
      let _ = try await ModifyRecords.with(
        recordsToSave: recordsToSave,
        recordIDsToDelete: nil,
        perRecordProgressBlock: nil,
        database: db,
        qualityOfService: .default,
        autoRetryForRetriableErrors: true
      ).get()
    } catch {
      XCTAssertTrue(error.code == CKError.Code.zoneBusy.rawValue)
      let operationsRun = await db.operationsRun
      XCTAssertEqual(operationsRun, 3)
    }
  }
}
