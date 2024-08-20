import CanopyTestTools
import CanopyTypes
import CloudKit
import XCTest

final class ReplayingMockDatabaseTests: XCTestCase {
  func test_query_records_success() async {
    let db = ReplayingMockDatabase(operationResults: [
      .queryRecords(
        .init(
          result: .success([
            .mock(.init(recordID: .init(recordName: "mockName"), recordType: "MockType"))
          ])
        )
      )
    ])
    let result = try! await db.queryRecords(with: .init(recordType: "MockType", predicate: NSPredicate(value: true)), in: nil).get()
    XCTAssertEqual(result.first!.recordID.recordName, "mockName")
  }
  
  func test_query_records_failure() async {
    let db = ReplayingMockDatabase(operationResults: [
      .queryRecords(.init(result: .failure(.init(from: CKError(CKError.Code.badDatabase)))))
    ])
    do {
      let _ = try await db.queryRecords(with: .init(recordType: "MockType", predicate: NSPredicate(value: true)), in: nil).get()
    } catch let recordError as CKRecordError {
      XCTAssertEqual(recordError, CKRecordError(from: CKError(CKError.Code.badDatabase)))
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
  
  func test_modify_records_success() async {
    let db = ReplayingMockDatabase(operationResults: [
      .modifyRecords(
        .init(
          result: .success(
            .init(
              savedRecords: [
                .mock(.init(recordType: "MockType"))
              ],
              deletedRecordIDs: [
                .init(recordName: "deleted0"),
                .init(recordName: "deleted1")
              ]
            )
          )
        )
      )
    ])
    let result = try! await db.modifyRecords(
      saving: [],
      deleting: []
    ).get()
    XCTAssertEqual(result.savedRecords.first!.recordType, "MockType")
    XCTAssertEqual(result.deletedRecordIDs[0].recordName, "deleted0")
    XCTAssertEqual(result.deletedRecordIDs[1].recordName, "deleted1")
  }
  
  func test_modify_records_error() async {
    let db = ReplayingMockDatabase(operationResults: [
      .modifyRecords(.init(result: .failure(.init(from: CKError(CKError.Code.networkFailure)))))
    ])
    do {
      let _ = try await db.modifyRecords(saving: [], deleting: []).get()
    } catch let recordError as CKRecordError {
      XCTAssertEqual(recordError, CKRecordError(from: CKError(CKError.Code.networkFailure)))
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
  
  func test_delete_records_success() async {
    let db = ReplayingMockDatabase(operationResults: [
      .deleteRecords(
        .init(
          result: .success(
            .init(
              savedRecords: [],
              deletedRecordIDs: [
                .init(recordName: "deleted0"),
                .init(recordName: "deleted1")
              ]
            )
          )
        )
      )
    ])
    let result = try! await db.deleteRecords(with: CKQuery(recordType: "SomeType", predicate: NSPredicate(value: true)), in: nil).get()
    XCTAssertEqual(result.deletedRecordIDs[0].recordName, "deleted0")
    XCTAssertEqual(result.deletedRecordIDs[1].recordName, "deleted1")
  }
  
  func test_delete_records_error() async {
    let db = ReplayingMockDatabase(operationResults: [
      .deleteRecords(.init(result: .failure(.init(from: CKError(CKError.Code.networkFailure)))))
    ])
    do {
      let _ = try await db.deleteRecords(with: CKQuery(recordType: "SomeType", predicate: NSPredicate(value: true)), in: nil).get()
    } catch let recordError as CKRecordError {
      XCTAssertEqual(recordError, CKRecordError(from: CKError(CKError.Code.networkFailure)))
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
  
  func test_fetch_records_success() async {
    let db = ReplayingMockDatabase(operationResults: [
      .fetchRecords(
        .init(
          result: .success(
            .init(
              foundRecords: [
                .mock(.init(recordID: .init(recordName: "record1"), recordType: "MockType")),
                .mock(.init(recordID: .init(recordName: "record2"), recordType: "MockType"))
              ],
              notFoundRecordIDs: [
                .init(recordName: "notFound1"),
                .init(recordName: "notFound2"),
                .init(recordName: "notFound3")
              ]
            )
          )
        )
      )
    ])
    let result = try! await db.fetchRecords(with: []).get()
    XCTAssertEqual(result.foundRecords[0].recordID.recordName, "record1")
    XCTAssertEqual(result.foundRecords[1].recordID.recordName, "record2")
    XCTAssertEqual(result.notFoundRecordIDs[0].recordName, "notFound1")
    XCTAssertEqual(result.notFoundRecordIDs[1].recordName, "notFound2")
    XCTAssertEqual(result.notFoundRecordIDs[2].recordName, "notFound3")
  }
  
  func test_fetch_records_error() async {
    let db = ReplayingMockDatabase(operationResults: [
      .fetchRecords(.init(result: .failure(.init(from: CKError(CKError.Code.networkFailure)))))
    ])
    do {
      let _ = try await db.fetchRecords(with: []).get()
    } catch let recordError as CKRecordError {
      XCTAssertEqual(recordError, CKRecordError(from: CKError(CKError.Code.networkFailure)))
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
  
  func test_modify_zones_success() async {
    let db = ReplayingMockDatabase(operationResults: [
      .modifyZones(
        .init(
          result: .success(
            .init(
              savedZones: [
                .init(zoneName: "myZone")
              ],
              deletedZoneIDs: [
                .init(zoneName: "myDeletedZone")
              ]
            )
          )
        )
      )
    ])
    let result = try! await db.modifyZones(saving: [], deleting: []).get()
    XCTAssertEqual(result.savedZones[0].zoneID.zoneName, "myZone")
    XCTAssertEqual(result.deletedZoneIDs[0].zoneName, "myDeletedZone")
  }
  
  func test_modify_zones_error() async {
    let db = ReplayingMockDatabase(operationResults: [
      .modifyZones(.init(result: .failure(.init(from: CKError(CKError.Code.badDatabase)))))
    ])
    do {
      let _ = try await db.modifyZones(saving: [], deleting: []).get()
    } catch let recordError as CKRecordZoneError {
      XCTAssertEqual(recordError, CKRecordZoneError(from: CKError(CKError.Code.badDatabase)))
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
  
  func test_fetch_zones_success() async {
    let db = ReplayingMockDatabase(operationResults: [
      .fetchZones(
        .init(
          result: .success([
            .init(zoneID: .init(zoneName: "zone1")),
            .init(zoneID: .init(zoneName: "zone2"))
          ])
        )
      )
    ])
    let result = try! await db.fetchZones(with: []).get()
    XCTAssertEqual(result[0].zoneID.zoneName, "zone1")
    XCTAssertEqual(result[1].zoneID.zoneName, "zone2")
  }
  
  func test_fetch_zones_error() async {
    let db = ReplayingMockDatabase(operationResults: [
      .fetchZones(.init(result: .failure(.init(from: CKError(CKError.Code.badDatabase)))))
    ])
    do {
      let _ = try await db.fetchZones(with: []).get()
    } catch let recordError as CKRecordZoneError {
      XCTAssertEqual(recordError, CKRecordZoneError(from: CKError(CKError.Code.badDatabase)))
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
  
  func test_fetch_all_zones_success() async {
    let db = ReplayingMockDatabase(operationResults: [
      .fetchAllZones(
        .init(
          result: .success([
            .init(zoneID: .init(zoneName: "zone1")),
            .init(zoneID: .init(zoneName: "zone2"))
          ])
        )
      )
    ])
    let result = try! await db.fetchAllZones().get()
    XCTAssertEqual(result[0].zoneID.zoneName, "zone1")
    XCTAssertEqual(result[1].zoneID.zoneName, "zone2")
  }
  
  func test_fetch_all_zones_error() async {
    let db = ReplayingMockDatabase(operationResults: [
      .fetchAllZones(.init(result: .failure(.init(from: CKError(CKError.Code.badDatabase)))))
    ])
    do {
      let _ = try await db.fetchAllZones().get()
    } catch let recordError as CKRecordZoneError {
      XCTAssertEqual(recordError, CKRecordZoneError(from: CKError(CKError.Code.badDatabase)))
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
  
  func test_modify_subscriptions_success() async {
    let db = ReplayingMockDatabase(operationResults: [
      .modifySubscriptions(
        .init(
          result: .success(
            .init(
              savedSubscriptions: [
                CKDatabaseSubscription(subscriptionID: "db"),
                CKQuerySubscription(
                  recordType: "SomeType",
                  predicate: NSPredicate(value: true),
                  subscriptionID: "query"
                )
              ],
              deletedSubscriptionIDs: ["deleted1", "deleted2"]
            )
          )
        )
      )
    ])
    let result = try! await db.modifySubscriptions(saving: [], deleting: []).get()
    XCTAssertEqual(result.savedSubscriptions[1].subscriptionID, "query")
    XCTAssertEqual(result.deletedSubscriptionIDs[1], "deleted2")
  }
  
  func test_modify_subscriptions_error() async {
    let db = ReplayingMockDatabase(operationResults: [
      .modifySubscriptions(.init(result: .failure(.init(from: CKError(CKError.Code.badDatabase)))))
    ])
    do {
      let _ = try await db.modifySubscriptions(saving: [], deleting: []).get()
    } catch let recordError as CKSubscriptionError {
      XCTAssertEqual(recordError, CKSubscriptionError(from: CKError(CKError.Code.badDatabase)))
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
  
  func test_fetch_database_changes_success() async {
    let db = ReplayingMockDatabase(operationResults: [
      .fetchDatabaseChanges(
        .init(
          result: .success(
            .init(
              changedRecordZoneIDs: [.init(zoneName: "changedZone")],
              deletedRecordZoneIDs: [.init(zoneName: "deletedZone")],
              purgedRecordZoneIDs: [.init(zoneName: "purgedZone")]
            )
          )
        )
      )
    ])
    let result = try! await db.fetchDatabaseChanges().get()
    XCTAssertEqual(result.changedRecordZoneIDs[0].zoneName, "changedZone")
    XCTAssertEqual(result.deletedRecordZoneIDs[0].zoneName, "deletedZone")
    XCTAssertEqual(result.purgedRecordZoneIDs[0].zoneName, "purgedZone")
  }
  
  func test_fetch_database_changes_error() async {
    let db = ReplayingMockDatabase(operationResults: [
      .fetchDatabaseChanges(
        .init(
          result: .failure(.ckRequestError(.init(from: CKError(CKError.Code.notAuthenticated))))
        )
      )
    ])
    do {
      let _ = try await db.fetchDatabaseChanges().get()
    } catch CanopyError.ckRequestError(let requestError) {
      XCTAssertEqual(requestError, CKRequestError(from: CKError(CKError.Code.notAuthenticated)))
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
  
  func test_fetch_zone_changes_success() async {
    let db = ReplayingMockDatabase(operationResults: [
      .fetchZoneChanges(
        .init(
          result: .success(
            .init(
              records: [
                .mock(
                  .init(
                    recordID: .init(recordName: "someRecordName"),
                    recordType: "SomeType"
                  )
                )
              ],
              deletedRecords: [
                .init(
                  recordID: .init(
                    recordName: "deletedRecordName"),
                  recordType: "DeletedMockType"
                )
              ]
            )
          )
        )
      )
    ])
    let zoneChanges = try! await db.fetchZoneChanges(recordZoneIDs: []).get()
    XCTAssertEqual(zoneChanges.changedRecords[0].recordID.recordName, "someRecordName")
    XCTAssertEqual(zoneChanges.deletedRecords[0].recordID.recordName, "deletedRecordName")
  }
  
  func test_fetch_zone_changes_error() async {
    let db = ReplayingMockDatabase(operationResults: [
      .fetchZoneChanges(
        .init(
          result: .failure(.ckRequestError(.init(from: CKError(CKError.Code.notAuthenticated))))
        )
      )
    ])
    do {
      let _ = try await db.fetchZoneChanges(recordZoneIDs: []).get()
    } catch CanopyError.ckRequestError(let requestError) {
      XCTAssertEqual(requestError, CKRequestError(from: CKError(CKError.Code.notAuthenticated)))
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
  
  func test_two_operations() async {
    let db = ReplayingMockDatabase(operationResults: [
      .queryRecords(
        .init(
          result: .success([
            .mock(.init(recordID: .init(recordName: "mockName"), recordType: "MockType"))
          ])
        )
      ),
      .fetchRecords(
        .init(
          result: .success(
            .init(
              foundRecords: [
                .mock(.init(recordID: .init(recordName: "record1"), recordType: "MockType")),
                .mock(.init(recordID: .init(recordName: "record2"), recordType: "MockType"))
              ],
              notFoundRecordIDs: [
                .init(recordName: "notFound1"),
                .init(recordName: "notFound2"),
                .init(recordName: "notFound3")
              ]
            )
          )
        )
      )
    ])
    let result1 = try! await db.queryRecords(with: .init(recordType: "MockType", predicate: NSPredicate(value: true)), in: nil).get()
    XCTAssertEqual(result1.first!.recordID.recordName, "mockName")
    
    let result2 = try! await db.fetchRecords(with: []).get()
    XCTAssertEqual(result2.notFoundRecordIDs[0].recordName, "notFound1")
  }
  
  func test_sleep_if_needed() async {
    let db = ReplayingMockDatabase(
      operationResults: [
        .queryRecords(
          .init(
            result: .success([
              .mock(.init(recordID: .init(recordName: "mockName"), recordType: "MockType"))
            ])
          )
        )
      ],
      sleepBeforeEachOperation: 0.01
    )
    let result = try! await db.queryRecords(with: .init(recordType: "MockType", predicate: NSPredicate(value: true)), in: nil).get()
    XCTAssertEqual(result.first!.recordID.recordName, "mockName")
  }
}
