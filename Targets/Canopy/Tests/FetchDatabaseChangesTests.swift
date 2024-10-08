@testable import Canopy
import CanopyTestTools
import CanopyTypes
import CloudKit
import Foundation
import XCTest

@available(iOS 16.4, macOS 13.3, *)
final class FetchDatabaseChangesTests: XCTestCase {
  func test_success() async {
    let changedRecordZoneID1 = CKRecordZone.ID(zoneName: "changedZone1", ownerName: CKCurrentUserDefaultName)
    let changedRecordZoneID2 = CKRecordZone.ID(zoneName: "changedZone2", ownerName: CKCurrentUserDefaultName)
    let deletedRecordZoneID = CKRecordZone.ID(zoneName: "deletedZone", ownerName: CKCurrentUserDefaultName)
    let purgedRecordZoneID = CKRecordZone.ID(zoneName: "purgedZone", ownerName: CKCurrentUserDefaultName)
    let db = ReplayingMockCKDatabase(operationResults: [
      .fetchDatabaseChanges(
        .init(
          changedRecordZoneIDs: [changedRecordZoneID1, changedRecordZoneID2],
          deletedRecordZoneIDs: [deletedRecordZoneID],
          purgedRecordZoneIDs: [purgedRecordZoneID],
          fetchDatabaseChangesResult: .init(result: .success((serverChangeToken: CKServerChangeToken.mock, moreComing: false)))
        )
      )
    ])
    let testTokenStore = TestTokenStore()
    let api = CKDatabaseAPI(database: db, databaseScope: .private, tokenStore: testTokenStore)
    let result = try? await api.fetchDatabaseChanges().get()
    XCTAssertEqual(result, FetchDatabaseChangesResult(
      changedRecordZoneIDs: [changedRecordZoneID1, changedRecordZoneID2],
      deletedRecordZoneIDs: [deletedRecordZoneID],
      purgedRecordZoneIDs: [purgedRecordZoneID]
    ))
    
    let getTokenForDatabaseScopeCalls = await testTokenStore.getTokenForDatabaseScopeCalls
    let storeTokenForDatabaseScopeCalls = await testTokenStore.storeTokenForDatabaseScopeCalls
    
    XCTAssertEqual(getTokenForDatabaseScopeCalls, 1)
    XCTAssertEqual(storeTokenForDatabaseScopeCalls, 1)
  }
  
  func test_token_expired_error() async {
    let db = ReplayingMockCKDatabase(operationResults: [
      .fetchDatabaseChanges(
        .init(
          changedRecordZoneIDs: [],
          deletedRecordZoneIDs: [],
          purgedRecordZoneIDs: [],
          fetchDatabaseChangesResult: .init(result: .failure(CKError(CKError.Code.changeTokenExpired)))
        )
      )
    ])
    let testTokenStore = TestTokenStore()
    let api = CKDatabaseAPI(database: db, databaseScope: .private, settingsProvider: { CanopySettings() }, tokenStore: testTokenStore)
    do {
      let _ = try await api.fetchDatabaseChanges().get()
    } catch {
      XCTAssertEqual(error, CanopyError.ckChangeTokenExpired)
      let storeTokenForDatabaseScopeCalls = await testTokenStore.storeTokenForDatabaseScopeCalls
      XCTAssertEqual(storeTokenForDatabaseScopeCalls, 1) // nil token was stored
    }
  }
  
  func test_other_error() async {
    let db = ReplayingMockCKDatabase(operationResults: [
      .fetchDatabaseChanges(
        .init(
          changedRecordZoneIDs: [],
          deletedRecordZoneIDs: [],
          purgedRecordZoneIDs: [],
          fetchDatabaseChangesResult: .init(result: .failure(CKError(CKError.Code.networkFailure)))
        )
      )
    ])
    let testTokenStore = TestTokenStore()
    let api = CKDatabaseAPI(database: db, databaseScope: .private, tokenStore: testTokenStore)
    do {
      let _ = try await api.fetchDatabaseChanges().get()
    } catch {
      XCTAssertEqual(error, CanopyError.ckRequestError(CKRequestError(from: CKError(CKError.Code.networkFailure))))
      let storeTokenForDatabaseScopeCalls = await testTokenStore.storeTokenForDatabaseScopeCalls
      XCTAssertEqual(storeTokenForDatabaseScopeCalls, 0) // nothing should have been stored
    }
  }
  
  func test_success_with_delay() async {
    let changedRecordZoneID1 = CKRecordZone.ID(zoneName: "changedZone1", ownerName: CKCurrentUserDefaultName)
    let db = ReplayingMockCKDatabase(operationResults: [
      .fetchDatabaseChanges(
        .init(
          changedRecordZoneIDs: [changedRecordZoneID1],
          deletedRecordZoneIDs: [],
          purgedRecordZoneIDs: [],
          fetchDatabaseChangesResult: .init(result: .success((serverChangeToken: CKServerChangeToken.mock, moreComing: false)))
        )
      )
    ])
    let testTokenStore = TestTokenStore()
    let api = CKDatabaseAPI(
      database: db,
      databaseScope: .private,
      settingsProvider: {
        CanopySettings(fetchDatabaseChangesBehavior: .regular(0.1))
      },
      tokenStore: testTokenStore
    )
    let result = try? await api.fetchDatabaseChanges().get()
    XCTAssertEqual(result, FetchDatabaseChangesResult(
      changedRecordZoneIDs: [changedRecordZoneID1],
      deletedRecordZoneIDs: [],
      purgedRecordZoneIDs: []
    ))
    let getTokenForDatabaseScopeCalls = await testTokenStore.getTokenForDatabaseScopeCalls
    let storeTokenForDatabaseScopeCalls = await testTokenStore.storeTokenForDatabaseScopeCalls
    XCTAssertEqual(getTokenForDatabaseScopeCalls, 1)
    XCTAssertEqual(storeTokenForDatabaseScopeCalls, 1)
  }
  
  func test_simulated_fail() async {
    let changedRecordZoneID1 = CKRecordZone.ID(zoneName: "changedZone1", ownerName: CKCurrentUserDefaultName)
    let db = ReplayingMockCKDatabase(operationResults: [
      .fetchDatabaseChanges(
        .init(
          changedRecordZoneIDs: [changedRecordZoneID1],
          deletedRecordZoneIDs: [],
          purgedRecordZoneIDs: [],
          fetchDatabaseChangesResult: .init(result: .success((serverChangeToken: CKServerChangeToken.mock, moreComing: false)))
        )
      )
    ])
    let testTokenStore = TestTokenStore()
    let api = CKDatabaseAPI(
      database: db,
      databaseScope: .private,
      settingsProvider: {
        CanopySettings(fetchDatabaseChangesBehavior: .simulatedFail(nil))
      },
      tokenStore: testTokenStore
    )
    do {
      let _ = try await api.fetchDatabaseChanges().get()
    } catch {
      switch error {
      case .ckRequestError:
        break
      default:
        XCTFail("Unexpected error type: \(error)")
      }
      let getTokenForDatabaseScopeCalls = await testTokenStore.getTokenForDatabaseScopeCalls
      let storeTokenForDatabaseScopeCalls = await testTokenStore.storeTokenForDatabaseScopeCalls

      XCTAssertEqual(getTokenForDatabaseScopeCalls, 0)
      XCTAssertEqual(storeTokenForDatabaseScopeCalls, 0)
    }
  }
  
  func test_simulated_fail_with_delay() async {
    let changedRecordZoneID1 = CKRecordZone.ID(zoneName: "changedZone1", ownerName: CKCurrentUserDefaultName)
    let db = ReplayingMockCKDatabase(operationResults: [
      .fetchDatabaseChanges(
        .init(
          changedRecordZoneIDs: [changedRecordZoneID1],
          deletedRecordZoneIDs: [],
          purgedRecordZoneIDs: [],
          fetchDatabaseChangesResult: .init(result: .success((serverChangeToken: CKServerChangeToken.mock, moreComing: false)))
        )
      )
    ])
    let testTokenStore = TestTokenStore()
    let api = CKDatabaseAPI(
      database: db,
      databaseScope: .private,
      settingsProvider: {
        CanopySettings(fetchDatabaseChangesBehavior: .simulatedFail(0.1))
      },
      tokenStore: testTokenStore
    )
    do {
      let _ = try await api.fetchDatabaseChanges().get()
    } catch {
      switch error {
      case .ckRequestError:
        break
      default:
        XCTFail("Unexpected error type: \(error)")
      }
      
      let getTokenForDatabaseScopeCalls = await testTokenStore.getTokenForDatabaseScopeCalls
      let storeTokenForDatabaseScopeCalls = await testTokenStore.storeTokenForDatabaseScopeCalls

      XCTAssertEqual(getTokenForDatabaseScopeCalls, 0)
      XCTAssertEqual(storeTokenForDatabaseScopeCalls, 0)
    }
  }
}
