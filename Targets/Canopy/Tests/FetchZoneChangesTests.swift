@testable import Canopy
import CanopyTestTools
import CanopyTypes
import CloudKit
import Foundation
import XCTest

@available(iOS 16.4, macOS 13.3, *)
final class FetchZoneChangesTests: XCTestCase {
  func test_success() async {
    let changedRecordID = CKRecord.ID(recordName: "SomeRecordName")
    let changedRecord = CKRecord(recordType: "TestRecord", recordID: changedRecordID)
    let zoneID = CKRecordZone.ID(zoneName: "testZone", ownerName: CKCurrentUserDefaultName)
    
    let db = ReplayingMockCKDatabase(operationResults: [
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
    let api = CKDatabaseAPI(database: db, databaseScope: .private, tokenStore: tokenStore)
    let result = try! await api.fetchZoneChanges(
      recordZoneIDs: [zoneID],
      fetchMethod: .changeTokenAndAllData
    ).get()
    XCTAssertTrue(result.changedRecords.first!.isEqualToRecord(changedRecord))
    XCTAssertEqual(result.deletedRecords, [])
    let getTokenForRecordZoneCalls = await tokenStore.getTokenForRecordZoneCalls
    let storeTokenForRecordZoneCalls = await tokenStore.storeTokenForRecordZoneCalls
    XCTAssertEqual(getTokenForRecordZoneCalls, 1)
    XCTAssertEqual(storeTokenForRecordZoneCalls, 1)
  }
  
  func test_fetch_tokens_only() async {
    let changedRecordID = CKRecord.ID(recordName: "SomeRecordName")
    let changedRecord = CKRecord(recordType: "TestRecord", recordID: changedRecordID)
    let zoneID = CKRecordZone.ID(zoneName: "testZone", ownerName: CKCurrentUserDefaultName)
    
    let db = ReplayingMockCKDatabase(operationResults: [
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
    let api = CKDatabaseAPI(database: db, databaseScope: .private, tokenStore: tokenStore)
    let result = try! await api.fetchZoneChanges(
      recordZoneIDs: [zoneID],
      fetchMethod: .changeTokenOnly
    ).get()
    XCTAssertEqual(result.changedRecords, [])
    XCTAssertEqual(result.deletedRecords, [])
    let getTokenForRecordZoneCalls = await tokenStore.getTokenForRecordZoneCalls
    let storeTokenForRecordZoneCalls = await tokenStore.storeTokenForRecordZoneCalls
    XCTAssertEqual(getTokenForRecordZoneCalls, 1)
    XCTAssertEqual(storeTokenForRecordZoneCalls, 1)
  }
  
  func test_record_error() async {
    let changedRecordID = CKRecord.ID(recordName: "SomeRecordName")
    let deletedRecordID = CKRecord.ID(recordName: "DeletedRecordID")
    let zoneID = CKRecordZone.ID(zoneName: "testZone", ownerName: CKCurrentUserDefaultName)
    
    let db = ReplayingMockCKDatabase(operationResults: [
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
    let api = CKDatabaseAPI(database: db, databaseScope: .private, tokenStore: tokenStore)

    do {
      let _ = try await api.fetchZoneChanges(
        recordZoneIDs: [zoneID],
        fetchMethod: .changeTokenAndSpecificKeys(["key1", "key2"])
      ).get()
    } catch {
      XCTAssertEqual(error as! CanopyError, .ckRecordError(.init(from: CKError(CKError.Code.networkUnavailable))))
      let storeTokenForRecordZoneCalls = await tokenStore.storeTokenForRecordZoneCalls
      XCTAssertEqual(storeTokenForRecordZoneCalls, 0)
    }
  }
  
  func test_token_expired() async {
    let zoneID1 = CKRecordZone.ID(zoneName: "testZone1", ownerName: CKCurrentUserDefaultName)
    let zoneID2 = CKRecordZone.ID(zoneName: "testZone2", ownerName: CKCurrentUserDefaultName)

    let db = ReplayingMockCKDatabase(operationResults: [
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
    let api = CKDatabaseAPI(database: db, databaseScope: .private, tokenStore: tokenStore)
    
    do {
      let _ = try await api.fetchZoneChanges(
        recordZoneIDs: [zoneID1, zoneID2],
        fetchMethod: .changeTokenAndAllData
      ).get()
    } catch {
      let getTokenForRecordZoneCalls = await tokenStore.getTokenForRecordZoneCalls
      let storeTokenForRecordZoneCalls = await tokenStore.storeTokenForRecordZoneCalls

      XCTAssertEqual(getTokenForRecordZoneCalls, 2)
      // Stored only one nil token
      XCTAssertEqual(storeTokenForRecordZoneCalls, 1)
      XCTAssertEqual(error as! CanopyError, .ckRecordZoneError(.init(from: CKError(CKError.Code.changeTokenExpired))))
    }
  }
  
  func test_result_error() async {
    let zoneID = CKRecordZone.ID(zoneName: "testZone", ownerName: CKCurrentUserDefaultName)
    
    let db = ReplayingMockCKDatabase(operationResults: [
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
    let api = CKDatabaseAPI(database: db, databaseScope: .private, tokenStore: tokenStore)
    
    do {
      let _ = try await api.fetchZoneChanges(
        recordZoneIDs: [zoneID],
        fetchMethod: .changeTokenAndAllData
      ).get()
    } catch {
      let getTokenForRecordZoneCalls = await tokenStore.getTokenForRecordZoneCalls
      let storeTokenForRecordZoneCalls = await tokenStore.storeTokenForRecordZoneCalls

      XCTAssertEqual(getTokenForRecordZoneCalls, 1)
      XCTAssertEqual(storeTokenForRecordZoneCalls, 0)
      
      XCTAssertEqual(error as! CanopyError, .ckRequestError(.init(from: CKError(CKError.Code.accountTemporarilyUnavailable))))
    }
  }
  
  func test_success_with_delay() async {
    let changedRecordID = CKRecord.ID(recordName: "SomeRecordName")
    let changedRecord = CKRecord(recordType: "TestRecord", recordID: changedRecordID)
    let zoneID = CKRecordZone.ID(zoneName: "testZone", ownerName: CKCurrentUserDefaultName)
    
    let db = ReplayingMockCKDatabase(operationResults: [
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
    let api = CKDatabaseAPI(database: db, databaseScope: .private, settingsProvider: { CanopySettings(fetchZoneChangesBehavior: .regular(0.1)) }, tokenStore: tokenStore)
    let result = try! await api.fetchZoneChanges(
      recordZoneIDs: [zoneID],
      fetchMethod: .changeTokenAndAllData
    ).get()
    XCTAssertTrue(result.changedRecords.first!.isEqualToRecord(changedRecord))
    XCTAssertEqual(result.deletedRecords, [])
    let getTokenForRecordZoneCalls = await tokenStore.getTokenForRecordZoneCalls
    let storeTokenForRecordZoneCalls = await tokenStore.storeTokenForRecordZoneCalls

    XCTAssertEqual(getTokenForRecordZoneCalls, 1)
    XCTAssertEqual(storeTokenForRecordZoneCalls, 1)
  }
  
  func test_simulated_fail() async {
    let changedRecordID = CKRecord.ID(recordName: "SomeRecordName")
    let changedRecord = CKRecord(recordType: "TestRecord", recordID: changedRecordID)
    let zoneID = CKRecordZone.ID(zoneName: "testZone", ownerName: CKCurrentUserDefaultName)
    
    let db = ReplayingMockCKDatabase(operationResults: [
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
    let api = CKDatabaseAPI(database: db, databaseScope: .private, settingsProvider: { CanopySettings(fetchZoneChangesBehavior: .simulatedFail(nil)) }, tokenStore: tokenStore)
    do {
      let _ = try await api.fetchZoneChanges(
        recordZoneIDs: [zoneID],
        fetchMethod: .changeTokenAndAllData
      ).get()
    } catch {
      switch error as! CanopyError {
      case .ckRequestError:
        break
      default:
        XCTFail("Unexpected error type: \(error)")
      }
      let getTokenForRecordZoneCalls = await tokenStore.getTokenForRecordZoneCalls
      let storeTokenForRecordZoneCalls = await tokenStore.storeTokenForRecordZoneCalls

      XCTAssertEqual(getTokenForRecordZoneCalls, 0)
      XCTAssertEqual(storeTokenForRecordZoneCalls, 0)
    }
  }
  
  func test_simulated_fail_with_delay() async {
    let changedRecordID = CKRecord.ID(recordName: "SomeRecordName")
    let changedRecord = CKRecord(recordType: "TestRecord", recordID: changedRecordID)
    let zoneID = CKRecordZone.ID(zoneName: "testZone", ownerName: CKCurrentUserDefaultName)
    
    let db = ReplayingMockCKDatabase(operationResults: [
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
    let api = CKDatabaseAPI(database: db, databaseScope: .private, settingsProvider: { CanopySettings(fetchZoneChangesBehavior: .simulatedFail(0.1)) }, tokenStore: tokenStore)
    do {
      let _ = try await api.fetchZoneChanges(
        recordZoneIDs: [zoneID],
        fetchMethod: .changeTokenAndAllData
      ).get()
    } catch {
      switch error as! CanopyError {
      case .ckRequestError:
        break
      default:
        XCTFail("Unexpected error type: \(error)")
      }
      let getTokenForRecordZoneCalls = await tokenStore.getTokenForRecordZoneCalls
      let storeTokenForRecordZoneCalls = await tokenStore.storeTokenForRecordZoneCalls

      XCTAssertEqual(getTokenForRecordZoneCalls, 0)
      XCTAssertEqual(storeTokenForRecordZoneCalls, 0)
    }
  }
}
