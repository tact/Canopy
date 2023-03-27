@testable import Canopy
import CanopyTypes
import CanopyTestTools
import CloudKit
import Foundation
import XCTest

final class FetchDatabaseChangesTests: XCTestCase {
  func test_success() async {
    let changedRecordZoneID1 = CKRecordZone.ID(zoneName: "changedZone1", ownerName: CKCurrentUserDefaultName)
    let changedRecordZoneID2 = CKRecordZone.ID(zoneName: "changedZone2", ownerName: CKCurrentUserDefaultName)
    let deletedRecordZoneID = CKRecordZone.ID(zoneName: "deletedZone", ownerName: CKCurrentUserDefaultName)
    let purgedRecordZoneID = CKRecordZone.ID(zoneName: "purgedZone", ownerName: CKCurrentUserDefaultName)
    let db = MockDatabase(operationResults: [
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
    let api = CKDatabaseAPI(db, tokenStore: testTokenStore)
    let result = try? await api.fetchDatabaseChanges(qualityOfService: .default).get()
    XCTAssertEqual(result, FetchDatabaseChangesResult(
      changedRecordZoneIDs: [changedRecordZoneID1, changedRecordZoneID2],
      deletedRecordZoneIDs: [deletedRecordZoneID],
      purgedRecordZoneIDs: [purgedRecordZoneID])
    )
    XCTAssertEqual(testTokenStore.getTokenForDatabaseScopeCalls, 1)
    XCTAssertEqual(testTokenStore.storeTokenForDatabaseScopeCalls, 1)
  }
  
  func test_token_expired_error() async {
    let db = MockDatabase(operationResults: [
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
    let api = CKDatabaseAPI(db, settingsProvider: { CanopySettings() }, tokenStore: testTokenStore)
    do {
      let _ = try await api.fetchDatabaseChanges(qualityOfService: .default).get()
    } catch {
      XCTAssertEqual(error as! CanopyError, CanopyError.ckChangeTokenExpired)
      XCTAssertEqual(testTokenStore.storeTokenForDatabaseScopeCalls, 1) // nil token was stored
    }
  }
  
  func test_other_error() async {
    let db = MockDatabase(operationResults: [
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
    let api = CKDatabaseAPI(db, tokenStore: testTokenStore)
    do {
      let _ = try await api.fetchDatabaseChanges(qualityOfService: .default).get()
    } catch {
      XCTAssertEqual(error as! CanopyError, CanopyError.ckRequestError(CKRequestError(from: CKError(CKError.Code.networkFailure))))
      XCTAssertEqual(testTokenStore.storeTokenForDatabaseScopeCalls, 0) // nothing should have been stored
    }
  }
  
  func test_success_with_delay() async {
    let changedRecordZoneID1 = CKRecordZone.ID(zoneName: "changedZone1", ownerName: CKCurrentUserDefaultName)
    let db = MockDatabase(operationResults: [
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
    let api = CKDatabaseAPI(db, settingsProvider: { CanopySettings(fetchDatabaseChangesBehavior: .regular(0.1)) }, tokenStore: testTokenStore)
    let result = try? await api.fetchDatabaseChanges(qualityOfService: .default).get()
    XCTAssertEqual(result, FetchDatabaseChangesResult(
      changedRecordZoneIDs: [changedRecordZoneID1],
      deletedRecordZoneIDs: [],
      purgedRecordZoneIDs: [])
    )
    XCTAssertEqual(testTokenStore.getTokenForDatabaseScopeCalls, 1)
    XCTAssertEqual(testTokenStore.storeTokenForDatabaseScopeCalls, 1)
  }
  
  func test_simulated_fail() async {
    let changedRecordZoneID1 = CKRecordZone.ID(zoneName: "changedZone1", ownerName: CKCurrentUserDefaultName)
    let db = MockDatabase(operationResults: [
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
    let api = CKDatabaseAPI(db, settingsProvider: { CanopySettings(fetchDatabaseChangesBehavior: .simulatedFail(nil)) }, tokenStore: testTokenStore)
    do {
      let _ = try await api.fetchDatabaseChanges(qualityOfService: .default).get()
    } catch {
      switch error as! CanopyError {
      case .ckRequestError:
        break
      default:
        XCTFail("Unexpected error type: \(error)")
      }
      XCTAssertEqual(testTokenStore.getTokenForDatabaseScopeCalls, 0)
      XCTAssertEqual(testTokenStore.storeTokenForDatabaseScopeCalls, 0)
    }
  }
  
  func test_simulated_fail_with_delay() async {
    let changedRecordZoneID1 = CKRecordZone.ID(zoneName: "changedZone1", ownerName: CKCurrentUserDefaultName)
    let db = MockDatabase(operationResults: [
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
    let api = CKDatabaseAPI(db, settingsProvider: { CanopySettings(fetchDatabaseChangesBehavior: .simulatedFail(0.1)) }, tokenStore: testTokenStore)
    do {
      let _ = try await api.fetchDatabaseChanges(qualityOfService: .default).get()
    } catch {
      switch error as! CanopyError {
      case .ckRequestError:
        break
      default:
        XCTFail("Unexpected error type: \(error)")
      }
      XCTAssertEqual(testTokenStore.getTokenForDatabaseScopeCalls, 0)
      XCTAssertEqual(testTokenStore.storeTokenForDatabaseScopeCalls, 0)
    }
  }
}
