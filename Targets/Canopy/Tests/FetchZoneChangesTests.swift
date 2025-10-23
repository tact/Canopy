@testable import Canopy
import CanopyTestTools
import CloudKit
import Foundation
import Testing

@Suite struct FetchZoneChangesTests {
  @Test func test_success() async {
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
    #expect(result.changedRecords.first!.isEqualToRecord(changedRecord.canopyResultRecord) == true)
    #expect(result.deletedRecords == [])
    let getTokenForRecordZoneCalls = await tokenStore.getTokenForRecordZoneCalls
    let storeTokenForRecordZoneCalls = await tokenStore.storeTokenForRecordZoneCalls
    #expect(getTokenForRecordZoneCalls == 1)
    #expect(storeTokenForRecordZoneCalls == 1)
  }
  
  @Test func test_fetch_tokens_only() async {
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
    #expect(result.changedRecords == [])
    #expect(result.deletedRecords == [])
    let getTokenForRecordZoneCalls = await tokenStore.getTokenForRecordZoneCalls
    let storeTokenForRecordZoneCalls = await tokenStore.storeTokenForRecordZoneCalls
    #expect(getTokenForRecordZoneCalls == 1)
    #expect(storeTokenForRecordZoneCalls == 1)
  }
  
  @Test func test_record_error() async {
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
    } catch CanopyError.ckRecordError(let recordError) {
      #expect(recordError == .init(from: CKError(CKError.Code.networkUnavailable)))
      let storeTokenForRecordZoneCalls = await tokenStore.storeTokenForRecordZoneCalls
      #expect(storeTokenForRecordZoneCalls == 0)
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }
  
  @Test func test_token_expired() async {
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

      #expect(getTokenForRecordZoneCalls == 2)
      // Stored only one nil token
      #expect(storeTokenForRecordZoneCalls == 1)
      #expect(error == .ckRecordZoneError(.init(from: CKError(CKError.Code.changeTokenExpired))))
    }
  }
  
  @Test func test_result_error() async {
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

      #expect(getTokenForRecordZoneCalls == 1)
      #expect(storeTokenForRecordZoneCalls == 0)
      
      #expect(error == .ckRequestError(.init(from: CKError(CKError.Code.accountTemporarilyUnavailable))))
    }
  }
  
  @Test func test_success_with_delay() async {
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
    #expect(result.changedRecords.first!.isEqualToRecord(changedRecord.canopyResultRecord) == true)
    #expect(result.deletedRecords == [])
    let getTokenForRecordZoneCalls = await tokenStore.getTokenForRecordZoneCalls
    let storeTokenForRecordZoneCalls = await tokenStore.storeTokenForRecordZoneCalls

    #expect(getTokenForRecordZoneCalls == 1)
    #expect(storeTokenForRecordZoneCalls == 1)
  }
  
  @Test func test_simulated_fail() async {
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
      switch error {
      case .ckRequestError:
        break
      default:
        Issue.record("Unexpected error type: \(error)")
      }
      let getTokenForRecordZoneCalls = await tokenStore.getTokenForRecordZoneCalls
      let storeTokenForRecordZoneCalls = await tokenStore.storeTokenForRecordZoneCalls

      #expect(getTokenForRecordZoneCalls == 0)
      #expect(storeTokenForRecordZoneCalls == 0)
    }
  }
  
  @Test func test_simulated_fail_with_delay() async {
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
      switch error {
      case .ckRequestError:
        break
      default:
        Issue.record("Unexpected error type: \(error)")
      }
      let getTokenForRecordZoneCalls = await tokenStore.getTokenForRecordZoneCalls
      let storeTokenForRecordZoneCalls = await tokenStore.storeTokenForRecordZoneCalls

      #expect(getTokenForRecordZoneCalls == 0)
      #expect(storeTokenForRecordZoneCalls == 0)
    }
  }
}
