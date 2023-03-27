@testable import Canopy
import CanopyTypes
import CanopyTestTools
import CloudKit
import Foundation
import XCTest

final class FetchZoneChangesTests: XCTestCase {
  
  func test_success() async {
    
    let changedRecordID = CKRecord.ID(recordName: "SomeRecordName")
    let changedRecord = CKRecord(recordType: "TestRecord", recordID: changedRecordID)
    let zoneID = CKRecordZone.ID(zoneName: "testZone", ownerName: CKCurrentUserDefaultName)
    
    let db = MockDatabase(operationResults: [
      .fetchZoneChanges(
        .init(
          recordWasChangedInZoneResults: [
            .init(recordID: changedRecordID, result: .success(changedRecord))
          ],
          recordWithIDWasDeletedInZoneResults: [],
          oneZoneFetchResults: [
            .init(
              zoneID: zoneID,
              result: .success((
                serverChangeToken: CKServerChangeToken.mock,
                clientChangeTokenData: nil,
                moreComing: false
              ))
            )
          ],
          fetchZoneChangesResult: .init(result: .success(()))
        )
      )
    ])
    let tokenStore = TestTokenStore()
    let api = CKDatabaseAPI(db, tokenStore: tokenStore)
    let result = try! await api.fetchZoneChanges(
      recordZoneIDs: [zoneID],
      fetchMethod: .changeTokenAndAllData,
      qualityOfService: .default
    ).get()
    XCTAssertTrue(result.changedRecords.first!.isEqualToRecord(changedRecord))
    XCTAssertEqual(result.deletedRecords, [])
    XCTAssertEqual(tokenStore.getTokenForRecordZoneCalls, 1)
    XCTAssertEqual(tokenStore.storeTokenForRecordZoneCalls, 1)
  }
  
  func test_fetch_tokens_only() async {
    
    let changedRecordID = CKRecord.ID(recordName: "SomeRecordName")
    let changedRecord = CKRecord(recordType: "TestRecord", recordID: changedRecordID)
    let zoneID = CKRecordZone.ID(zoneName: "testZone", ownerName: CKCurrentUserDefaultName)
    
    let db = MockDatabase(operationResults: [
      .fetchZoneChanges(
        .init(
          recordWasChangedInZoneResults: [
            .init(recordID: changedRecordID, result: .success(changedRecord))
          ],
          recordWithIDWasDeletedInZoneResults: [],
          oneZoneFetchResults: [
            .init(
              zoneID: zoneID,
              result: .success((
                serverChangeToken: CKServerChangeToken.mock,
                clientChangeTokenData: nil,
                moreComing: false
              ))
            )
          ],
          fetchZoneChangesResult: .init(result: .success(()))
        )
      )
    ])
    let tokenStore = TestTokenStore()
    let api = CKDatabaseAPI(db, tokenStore: tokenStore)
    let result = try! await api.fetchZoneChanges(
      recordZoneIDs: [zoneID],
      fetchMethod: .changeTokenOnly,
      qualityOfService: .default
    ).get()
    XCTAssertEqual(result.changedRecords, [])
    XCTAssertEqual(result.deletedRecords, [])
    XCTAssertEqual(tokenStore.getTokenForRecordZoneCalls, 1)
    XCTAssertEqual(tokenStore.storeTokenForRecordZoneCalls, 1)
  }
  
  func test_record_error() async {
    
    let changedRecordID = CKRecord.ID(recordName: "SomeRecordName")
    let deletedRecordID = CKRecord.ID(recordName: "DeletedRecordID")
    let zoneID = CKRecordZone.ID(zoneName: "testZone", ownerName: CKCurrentUserDefaultName)
    
    let db = MockDatabase(operationResults: [
      .fetchZoneChanges(
        .init(
          recordWasChangedInZoneResults: [
            .init(recordID: changedRecordID, result: .failure(CKError(CKError.Code.networkUnavailable)))
          ],
          recordWithIDWasDeletedInZoneResults: [
            .init(recordID: deletedRecordID, recordType: "SomeType")
          ],
          oneZoneFetchResults: [
            .init(
              zoneID: zoneID,
              result: .success((
                serverChangeToken: CKServerChangeToken.mock,
                clientChangeTokenData: nil,
                moreComing: false
              ))
            )
          ],
          fetchZoneChangesResult: .init(result: .success(()))
        )
      )
    ])
    let tokenStore = TestTokenStore()
    let api = CKDatabaseAPI(db, tokenStore: tokenStore)

    do {
      let _ = try await api.fetchZoneChanges(
        recordZoneIDs: [zoneID],
        fetchMethod: .changeTokenAndSpecificKeys(["key1", "key2"]),
        qualityOfService: .default
      ).get()
    } catch {
      XCTAssertEqual(error as! CanopyError, .ckRecordError(.init(from: CKError(CKError.Code.networkUnavailable))))
      XCTAssertEqual(tokenStore.storeTokenForRecordZoneCalls, 0)
    }
  }
  
  func test_token_expired() async {
    
    let zoneID1 = CKRecordZone.ID(zoneName: "testZone1", ownerName: CKCurrentUserDefaultName)
    let zoneID2 = CKRecordZone.ID(zoneName: "testZone2", ownerName: CKCurrentUserDefaultName)

    let db = MockDatabase(operationResults: [
      .fetchZoneChanges(
        .init(
          recordWasChangedInZoneResults: [],
          recordWithIDWasDeletedInZoneResults: [],
          oneZoneFetchResults: [
            .init(
              zoneID: zoneID1,
              result: .failure(CKError(CKError.Code.changeTokenExpired))
            ),
            .init(
              zoneID: zoneID2,
              result: .failure(CKError(CKError.Code.changeTokenExpired))
            )
          ],
          fetchZoneChangesResult: .init(result: .success(()))
        )
      )
    ])
    let tokenStore = TestTokenStore()
    let api = CKDatabaseAPI(db, tokenStore: tokenStore)
    
    do {
      let _ = try await api.fetchZoneChanges(
        recordZoneIDs: [zoneID1, zoneID2],
        fetchMethod: .changeTokenAndAllData,
        qualityOfService: .default
      ).get()
    } catch {
      XCTAssertEqual(tokenStore.getTokenForRecordZoneCalls, 2)
      // Stored only one nil token
      XCTAssertEqual(tokenStore.storeTokenForRecordZoneCalls, 1)
      XCTAssertEqual(error as! CanopyError, .ckRecordZoneError(.init(from: CKError(CKError.Code.changeTokenExpired))))
    }
  }
  
  func test_result_error() async {
    
    let zoneID = CKRecordZone.ID(zoneName: "testZone", ownerName: CKCurrentUserDefaultName)
    
    let db = MockDatabase(operationResults: [
      .fetchZoneChanges(
        .init(
          recordWasChangedInZoneResults: [],
          recordWithIDWasDeletedInZoneResults: [],
          oneZoneFetchResults: [
            .init(
              zoneID: zoneID,
              result: .success((
                serverChangeToken: CKServerChangeToken.mock,
                clientChangeTokenData: nil,
                moreComing: false
              ))
            )
          ],
          fetchZoneChangesResult: .init(result: .failure(CKError(CKError.Code.accountTemporarilyUnavailable)))
        )
      )
    ])
    let tokenStore = TestTokenStore()
    let api = CKDatabaseAPI(db, tokenStore: tokenStore)
    
    do {
      let _ = try await api.fetchZoneChanges(
        recordZoneIDs: [zoneID],
        fetchMethod: .changeTokenAndAllData,
        qualityOfService: .default
      ).get()
    } catch {
      XCTAssertEqual(tokenStore.getTokenForRecordZoneCalls, 1)
      XCTAssertEqual(tokenStore.storeTokenForRecordZoneCalls, 0)
      
      XCTAssertEqual(error as! CanopyError, .ckRequestError(.init(from: CKError(CKError.Code.accountTemporarilyUnavailable))))
    }
  }
  
  func test_success_with_delay() async {
    let changedRecordID = CKRecord.ID(recordName: "SomeRecordName")
    let changedRecord = CKRecord(recordType: "TestRecord", recordID: changedRecordID)
    let zoneID = CKRecordZone.ID(zoneName: "testZone", ownerName: CKCurrentUserDefaultName)
    
    let db = MockDatabase(operationResults: [
      .fetchZoneChanges(
        .init(
          recordWasChangedInZoneResults: [
            .init(recordID: changedRecordID, result: .success(changedRecord))
          ],
          recordWithIDWasDeletedInZoneResults: [],
          oneZoneFetchResults: [
            .init(
              zoneID: zoneID,
              result: .success((
                serverChangeToken: CKServerChangeToken.mock,
                clientChangeTokenData: nil,
                moreComing: false
              ))
            )
          ],
          fetchZoneChangesResult: .init(result: .success(()))
        )
      )
    ])
    let tokenStore = TestTokenStore()
    let api = CKDatabaseAPI(db, settingsProvider: { CanopySettings(fetchZoneChangesBehavior: .regular(0.1)) }, tokenStore: tokenStore)
    let result = try! await api.fetchZoneChanges(
      recordZoneIDs: [zoneID],
      fetchMethod: .changeTokenAndAllData,
      qualityOfService: .default
    ).get()
    XCTAssertTrue(result.changedRecords.first!.isEqualToRecord(changedRecord))
    XCTAssertEqual(result.deletedRecords, [])
    XCTAssertEqual(tokenStore.getTokenForRecordZoneCalls, 1)
    XCTAssertEqual(tokenStore.storeTokenForRecordZoneCalls, 1)
  }
  
  func test_simulated_fail() async {
    let changedRecordID = CKRecord.ID(recordName: "SomeRecordName")
    let changedRecord = CKRecord(recordType: "TestRecord", recordID: changedRecordID)
    let zoneID = CKRecordZone.ID(zoneName: "testZone", ownerName: CKCurrentUserDefaultName)
    
    let db = MockDatabase(operationResults: [
      .fetchZoneChanges(
        .init(
          recordWasChangedInZoneResults: [
            .init(recordID: changedRecordID, result: .success(changedRecord))
          ],
          recordWithIDWasDeletedInZoneResults: [],
          oneZoneFetchResults: [
            .init(
              zoneID: zoneID,
              result: .success((
                serverChangeToken: CKServerChangeToken.mock,
                clientChangeTokenData: nil,
                moreComing: false
              ))
            )
          ],
          fetchZoneChangesResult: .init(result: .success(()))
        )
      )
    ])
    let tokenStore = TestTokenStore()
    let api = CKDatabaseAPI(db, settingsProvider: { CanopySettings(fetchZoneChangesBehavior: .simulatedFail(nil)) }, tokenStore: tokenStore)
    do {
      let _ = try await api.fetchZoneChanges(
        recordZoneIDs: [zoneID],
        fetchMethod: .changeTokenAndAllData,
        qualityOfService: .default
      ).get()
    } catch {
      switch error as! CanopyError {
      case .ckRequestError:
        break
      default:
        XCTFail("Unexpected error type: \(error)")
      }
      XCTAssertEqual(tokenStore.getTokenForRecordZoneCalls, 0)
      XCTAssertEqual(tokenStore.storeTokenForRecordZoneCalls, 0)
    }
  }
  
  func test_simulated_fail_with_delay() async {
    let changedRecordID = CKRecord.ID(recordName: "SomeRecordName")
    let changedRecord = CKRecord(recordType: "TestRecord", recordID: changedRecordID)
    let zoneID = CKRecordZone.ID(zoneName: "testZone", ownerName: CKCurrentUserDefaultName)
    
    let db = MockDatabase(operationResults: [
      .fetchZoneChanges(
        .init(
          recordWasChangedInZoneResults: [
            .init(recordID: changedRecordID, result: .success(changedRecord))
          ],
          recordWithIDWasDeletedInZoneResults: [],
          oneZoneFetchResults: [
            .init(
              zoneID: zoneID,
              result: .success((
                serverChangeToken: CKServerChangeToken.mock,
                clientChangeTokenData: nil,
                moreComing: false
              ))
            )
          ],
          fetchZoneChangesResult: .init(result: .success(()))
        )
      )
    ])
    let tokenStore = TestTokenStore()
    let api = CKDatabaseAPI(db, settingsProvider: { CanopySettings(fetchZoneChangesBehavior: .simulatedFail(0.1)) }, tokenStore: tokenStore)
    do {
      let _ = try await api.fetchZoneChanges(
        recordZoneIDs: [zoneID],
        fetchMethod: .changeTokenAndAllData,
        qualityOfService: .default
      ).get()
    } catch {
      switch error as! CanopyError {
      case .ckRequestError:
        break
      default:
        XCTFail("Unexpected error type: \(error)")
      }
      XCTAssertEqual(tokenStore.getTokenForRecordZoneCalls, 0)
      XCTAssertEqual(tokenStore.storeTokenForRecordZoneCalls, 0)
    }
  }
}
