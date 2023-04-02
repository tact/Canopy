@testable import Canopy
import CanopyTestTools
import CloudKit
import XCTest

final class ModifyRecordsTests: XCTestCase {
  private func databaseAPI(_ db: CKDatabaseType, settings: CanopySettingsType = CanopySettings()) -> CKDatabaseAPIType {
    CKDatabaseAPI(db, settingsProvider: { settings }, tokenStore: TestTokenStore())
  }
  
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
  
  func test_success() async {
    let recordID = CKRecord.ID(recordName: "TestRecordName")
    let record = CKRecord(recordType: "TestRecord", recordID: recordID)
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .modify(
          .init(
            savedRecordResults: [
              .init(
                recordID: recordID,
                result: .success(record)
              )
            ],
            deletedRecordIDResults: [],
            modifyResult: .init(result: .success(()))
          )
        )
      ]
    )
    
    let api = databaseAPI(db)
    let result = try! await api.modifyRecords(saving: [record]).get()
    
    XCTAssertTrue(result.savedRecords.first!.isEqualToRecord(record))
    XCTAssertEqual(result.deletedRecordIDs, [])
  }
  
  func test_success_with_delay() async {
    let recordID = CKRecord.ID(recordName: "TestRecordName")
    let record = CKRecord(recordType: "TestRecord", recordID: recordID)
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .modify(
          .init(
            savedRecordResults: [
              .init(
                recordID: recordID,
                result: .success(record)
              )
            ],
            deletedRecordIDResults: [],
            modifyResult: .init(result: .success(()))
          )
        )
      ]
    )
    
    let api = databaseAPI(db, settings: CanopySettings(modifyRecordsBehavior: .regular(0.01)))
    let result = try! await api.modifyRecords(saving: [record]).get()
    
    XCTAssertTrue(result.savedRecords.first!.isEqualToRecord(record))
    XCTAssertEqual(result.deletedRecordIDs, [])
  }
  
  func test_simulated_fail() async {
    let recordID = CKRecord.ID(recordName: "TestRecordName")
    let record = CKRecord(recordType: "TestRecord", recordID: recordID)
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .modify(
          .init(
            savedRecordResults: [
              .init(
                recordID: recordID,
                result: .success(record)
              )
            ],
            deletedRecordIDResults: [],
            modifyResult: .init(result: .success(()))
          )
        )
      ]
    )
    
    let api = databaseAPI(db, settings: CanopySettings(modifyRecordsBehavior: .simulatedFail(nil)))
    do {
      let _ = try await api.modifyRecords(saving: [record]).get()
    } catch {
      XCTAssertTrue(error is CKRecordError)
    }
  }
  
  func test_simulated_fail_with_delay() async {
    let recordID = CKRecord.ID(recordName: "TestRecordName")
    let record = CKRecord(recordType: "TestRecord", recordID: recordID)
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .modify(
          .init(
            savedRecordResults: [
              .init(
                recordID: recordID,
                result: .success(record)
              )
            ],
            deletedRecordIDResults: [],
            modifyResult: .init(result: .success(()))
          )
        )
      ]
    )
    
    let api = databaseAPI(db, settings: CanopySettings(modifyRecordsBehavior: .simulatedFail(0.1)))
    do {
      let _ = try await api.modifyRecords(saving: [record]).get()
    } catch {
      XCTAssertTrue(error is CKRecordError)
    }
  }
  
  func test_simulated_fail_with_partial_errors() async {
    let recordID = CKRecord.ID(recordName: "TestRecordName")
    let recordIDToDelete = CKRecord.ID(recordName: "TestRecordNameToDelete")
    let record = CKRecord(recordType: "TestRecord", recordID: recordID)
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .modify(
          .init(
            savedRecordResults: [
              .init(
                recordID: recordID,
                result: .success(record)
              )
            ],
            deletedRecordIDResults: [
              .init(
                recordID: recordIDToDelete,
                result: .success(())
              )
            ],
            modifyResult: .init(result: .success(()))
          )
        )
      ]
    )
    
    let api = databaseAPI(db, settings: CanopySettings(modifyRecordsBehavior: .simulatedFailWithPartialErrors(nil)))
    do {
      let _ = try await api.modifyRecords(
        saving: [record],
        deleting: [recordIDToDelete]
      ).get()
    } catch {
      XCTAssertTrue(error is CKRecordError)
      let ckRecordError = error as! CKRecordError
      XCTAssertEqual(ckRecordError.batchErrors.count, 2)
    }
  }
  
  func test_explicit_autobatch_true() async {
    let recordsToSave = records(startIndex: 1, endIndex: 10)
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
            savedRecordResults: recordsToSave[0...9].map {
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
        )
      ]
    )
    
    let databaseAPI = CKDatabaseAPI(
      db,
      settingsProvider: { CanopySettings(autoBatchTooLargeModifyOperations: true) },
      tokenStore: TestTokenStore()
    )
    
    let result = try! await databaseAPI.modifyRecords(
      saving: recordsToSave,
      deleting: [recordIDToDelete]
    ).get()
    
    XCTAssertEqual(result.savedRecords.count, 10)
    for index in 0 ..< result.savedRecords.count {
      XCTAssertTrue(result.savedRecords[index].isEqualToRecord(recordsToSave[index]))
    }
    XCTAssertEqual(result.deletedRecordIDs.count, 1)

    let operationsRun = await db.operationsRun
    XCTAssertEqual(operationsRun, 2)
  }
  
  func test_explicit_autobatch_false() async {
    let recordsToSave = records(startIndex: 1, endIndex: 10)
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
    
    let databaseAPI = CKDatabaseAPI(
      db,
      settingsProvider: { CanopySettings(autoBatchTooLargeModifyOperations: false) },
      tokenStore: TestTokenStore()
    )
    
    do {
      let _ = try await databaseAPI.modifyRecords(
        saving: recordsToSave,
        deleting: [recordIDToDelete]
      ).get()
    } catch {
      XCTAssertEqual(error as! CKRecordError, CKRecordError(from: CKError(CKError.Code.limitExceeded)))
      let operationsRun = await db.operationsRun
      XCTAssertEqual(operationsRun, 1)
    }
  }
  
  func test_explicit_autoretry_true() async {
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
    
    let databaseAPI = CKDatabaseAPI(
      db,
      settingsProvider: { CanopySettings(autoRetryForRetriableErrors: true) },
      tokenStore: TestTokenStore()
    )
    
    let result = try! await databaseAPI.modifyRecords(
      saving: recordsToSave,
      deleting: []
    ).get()
    
    XCTAssertTrue(result.savedRecords[0].isEqualToRecord(recordsToSave[0]))
    XCTAssertEqual(result.savedRecords.count, 1)
    let operationsRun = await db.operationsRun
    XCTAssertEqual(operationsRun, 2)
  }
  
  func test_explicit_autoretry_false() async {
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
    
    let databaseAPI = CKDatabaseAPI(
      db,
      settingsProvider: { CanopySettings(autoRetryForRetriableErrors: false) },
      tokenStore: TestTokenStore()
    )
    
    do {
      let _ = try await databaseAPI.modifyRecords(
        saving: recordsToSave,
        deleting: []
      ).get()
    } catch {
      XCTAssertEqual(error as! CKRecordError, CKRecordError(from: CKError(CKError.Code.zoneBusy, userInfo: [CKErrorRetryAfterKey: 0.2])))
      let operationsRun = await db.operationsRun
      XCTAssertEqual(operationsRun, 1)
    }
  }
}
