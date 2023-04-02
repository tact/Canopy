@testable import Canopy
import CanopyTestTools
import CloudKit
import Foundation
import XCTest

/// Tests to make sure that fetching database and zone changes operates in a serial fashion.
///
/// When you fetch changes, you get a change token, that you should use as starting point
/// in the next fetch. Executing multiple fetches in parallel might yield duplicate records.
/// Although in many apps ingesting duplicate records can be resolved locally,
/// receiving multiple database/zone change tokens in parallel puts the local client data
/// in some indeterministic state, where you no longer have assurance about which state
/// of the cloud database your local data represents.
///
/// To guard against this, Canopy serializes the database and zone change fetches,
/// so that only one fetch for a given context is ever in flight. It is OK to schedule more
/// fetches. Next fetches wait for previous ones to finish.
///
/// These tests make sure that this behavior is correct.
final class SerialFetchChangesTests: XCTestCase {
  /// A token store that balances calls to getting and storing tokens.
  ///
  /// The store makes sure that only one token of a given type is ever in use,
  /// and reports violations.
  actor BalancingTokenStore: TokenStoreType {
    private let databaseViolationReporter: (CKDatabase.Scope) -> Void
    private let zoneViolationReporter: (CKRecordZone.ID) -> Void
    
    private var inflightDatabaseScopes: Set<CKDatabase.Scope> = []
    private var inflightZoneIDs: Set<CKRecordZone.ID> = []
    
    init(
      databaseViolationReporter: @escaping (CKDatabase.Scope) -> Void,
      zoneViolationReporter: @escaping (CKRecordZone.ID) -> Void
    ) {
      self.databaseViolationReporter = databaseViolationReporter
      self.zoneViolationReporter = zoneViolationReporter
    }
    
    func storeToken(_ token: CKServerChangeToken?, forDatabaseScope scope: CKDatabase.Scope) {
      inflightDatabaseScopes.remove(scope)
    }

    func tokenForDatabaseScope(_ scope: CKDatabase.Scope) -> CKServerChangeToken? {
      guard !inflightDatabaseScopes.contains(scope) else {
        databaseViolationReporter(scope)
        return nil
      }
      inflightDatabaseScopes.insert(scope)
      return nil
    }

    func storeToken(_ token: CKServerChangeToken?, forRecordZoneID zoneID: CKRecordZone.ID) {
      inflightZoneIDs.remove(zoneID)
    }

    func tokenForRecordZoneID(_ zoneID: CKRecordZone.ID) -> CKServerChangeToken? {
      guard !inflightZoneIDs.contains(zoneID) else {
        zoneViolationReporter(zoneID)
        return nil
      }
      inflightZoneIDs.insert(zoneID)
      return nil
    }
    
    func clear() {}
  }
    
  func test_two_database_fetches_work() async {
    // Two simultaneous change fetch requests for the same database should get queued up.

    let privateZoneID1 = CKRecordZone.ID(zoneName: "SomePrivateZone1", ownerName: CKCurrentUserDefaultName)

    let testDB = ReplayingMockCKDatabase(
      operationResults: [
        .fetchDatabaseChanges(
          .init(
            changedRecordZoneIDs: [privateZoneID1],
            deletedRecordZoneIDs: [],
            purgedRecordZoneIDs: [],
            fetchDatabaseChangesResult: .success
          )
        ),
        .fetchDatabaseChanges(
          .init(
            changedRecordZoneIDs: [privateZoneID1],
            deletedRecordZoneIDs: [],
            purgedRecordZoneIDs: [],
            fetchDatabaseChangesResult: .success
          )
        )
      ],
      scope: .private,
      sleep: 0.1
    )
    
    let api = CKDatabaseAPI(
      testDB,
      tokenStore: BalancingTokenStore(
        databaseViolationReporter: { scope in
          XCTFail("Token balance error for database scope: \(scope)")
        },
        zoneViolationReporter: { _ in }
      )
    )
    
    async let results1 = api.fetchDatabaseChanges()
    async let results2 = api.fetchDatabaseChanges()
    
    let _ = await [results1, results2]
  }
  
  func test_two_zone_fetches_work() async {
    // Two simultaneous change fetch requests for the same record zone should get queued up.
    
    let privateZoneID1 = CKRecordZone.ID(zoneName: "SomePrivateZone1", ownerName: CKCurrentUserDefaultName)
    
    let testDB = ReplayingMockCKDatabase(
      operationResults: [
        .fetchZoneChanges(
          .init(
            recordWasChangedInZoneResults: [],
            recordWithIDWasDeletedInZoneResults: [],
            oneZoneFetchResults: [
              .init(
                zoneID: privateZoneID1,
                result: .success(
                  (
                    serverChangeToken: CKServerChangeToken.mock,
                    clientChangeTokenData: nil,
                    moreComing: false
                  )
                )
              )
            ],
            fetchZoneChangesResult: .init(result: .success(()))
          )
        ),
        .fetchZoneChanges(
          .init(
            recordWasChangedInZoneResults: [],
            recordWithIDWasDeletedInZoneResults: [],
            oneZoneFetchResults: [
              .init(
                zoneID: privateZoneID1,
                result: .success(
                  (
                    serverChangeToken: CKServerChangeToken.mock,
                    clientChangeTokenData: nil,
                    moreComing: false
                  )
                )
              )
            ],
            fetchZoneChangesResult: .init(result: .success(()))
          )
        )
      ],
      scope: .private,
      sleep: 0.01
    )
    
    let api = CKDatabaseAPI(
      testDB,
      tokenStore: BalancingTokenStore(
        databaseViolationReporter: { _ in },
        zoneViolationReporter: { zoneID in
          XCTFail("Token balance error for zone: \(zoneID)")
        }
      )
    )
    
    async let results1 = api.fetchZoneChanges(
      recordZoneIDs: [privateZoneID1],
      fetchMethod: .changeTokenAndAllData
    )
    async let results2 = api.fetchZoneChanges(
      recordZoneIDs: [privateZoneID1],
      fetchMethod: .changeTokenAndAllData
    )
    
    let _ = await [results1, results2]
  }
}
