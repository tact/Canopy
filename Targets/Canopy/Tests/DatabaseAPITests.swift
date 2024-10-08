@testable import Canopy
import CanopyTestTools
import CanopyTypes
import CloudKit
import Foundation
import XCTest

/// Contains most Canopy database API tests.
///
/// Some tests are in individual test classes (fetch changes).
@available(iOS 16.4, macOS 13.3, *)
final class DatabaseAPITests: XCTestCase {
  private func databaseAPI(_ db: CKDatabaseType, settings: CanopySettingsType = CanopySettings()) -> CKDatabaseAPIType {
    CKDatabaseAPI(database: db, databaseScope: .private, settingsProvider: { settings }, tokenStore: TestTokenStore())
  }
  
  func test_init_with_default_settings() async {
    let databaseAPI = CKDatabaseAPI(database: ReplayingMockCKDatabase(), databaseScope: .private, tokenStore: TestTokenStore())
    let fetchDatabaseChangesBehavior = await databaseAPI.settingsProvider().fetchDatabaseChangesBehavior
    XCTAssertEqual(fetchDatabaseChangesBehavior, .regular(nil))
  }
    
  func test_query_records() async {
    let recordID = CKRecord.ID(recordName: "TestRecordName")
    let record = CKRecord(recordType: "TestRecord", recordID: recordID)
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .query(
          .init(
            queryRecordResults: [
              .init(
                recordID: recordID,
                result: .success(record)
              )
            ],
            queryResult: .init(result: .success(nil))
          )
        )
      ]
    )
    
    let api = databaseAPI(db)
    let query = CKQuery(recordType: "TestRecord", predicate: NSPredicate(value: true))
    let result = try! await api.queryRecords(with: query, in: nil).get()
    
    XCTAssertTrue(result.first!.isEqualToRecord(record.canopyResultRecord))
  }
  
  func test_delete_records_success() async {
    let recordID = CKRecord.ID(recordName: "TestRecordName")
    let record = CKRecord(recordType: "TestRecord", recordID: recordID)
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .query(
          .init(
            queryRecordResults: [
              .init(
                recordID: recordID,
                result: .success(record)
              )
            ],
            queryResult: .init(result: .success(nil))
          )
        ),
        .modify(
          .init(
            savedRecordResults: [],
            deletedRecordIDResults: [
              .init(recordID: recordID, result: .success(()))
            ],
            modifyResult: .init(result: .success(()))
          )
        )
      ]
    )
    
    let api = databaseAPI(db)
    let query = CKQuery(recordType: "TestRecord", predicate: NSPredicate(value: true))
    let result = try! await api.deleteRecords(with: query, in: nil).get()
    XCTAssertEqual(result.deletedRecordIDs, [recordID])
  }
  
  func test_delete_records_query_failure() async {
    let recordID = CKRecord.ID(recordName: "TestRecordName")
    let record = CKRecord(recordType: "TestRecord", recordID: recordID)
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .query(
          .init(
            queryRecordResults: [
              .init(
                recordID: recordID,
                result: .success(record)
              )
            ],
            queryResult: .init(result: .failure(CKError(CKError.Code.notAuthenticated)))
          )
        )
      ]
    )
    
    let api = databaseAPI(db)
    let query = CKQuery(recordType: "TestRecord", predicate: NSPredicate(value: true))
    do {
      let _ = try await api.deleteRecords(with: query, in: nil).get()
    } catch {
      XCTAssertEqual(error, CKRecordError(from: CKError(CKError.Code.notAuthenticated)))
    }
  }
  
  func test_delete_records_empty_success() async {
    // When there are no records returned by query,
    // the deletion should still report a success, since there is no work to be done.
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .query(
          .init(
            queryRecordResults: [],
            queryResult: .init(result: .success(nil))
          )
        )
      ]
    )
    
    let api = databaseAPI(db)
    let query = CKQuery(recordType: "TestRecord", predicate: NSPredicate(value: true))
    let result = try! await api.deleteRecords(with: query, in: nil).get()
    XCTAssertEqual(result.deletedRecordIDs, [])
  }
  
  func test_fetch_records_success() async {
    let recordID = CKRecord.ID(recordName: "testRecord")
    let record = CKRecord(recordType: "TestRecord", recordID: recordID)
    let db = ReplayingMockCKDatabase(operationResults: [
      .fetch(
        .init(
          fetchRecordResults: [
            .init(recordID: recordID, result: .success(record))
          ],
          fetchResult: .init(result: .success(()))
        )
      )
    ])
    let api = databaseAPI(db)
    let result = try! await api.fetchRecords(with: [recordID]).get()
    XCTAssertTrue(result.foundRecords.first!.isEqualToRecord(record.canopyResultRecord))
  }
  
  func test_fetch_records_record_failure() async {
    let recordID = CKRecord.ID(recordName: "testRecord")
    let db = ReplayingMockCKDatabase(operationResults: [
      .fetch(
        .init(
          fetchRecordResults: [
            .init(recordID: recordID, result: .failure(CKError(CKError.Code.notAuthenticated)))
          ],
          fetchResult: .init(result: .success(()))
        )
      )
    ])
    let api = databaseAPI(db)
    do {
      let _ = try await api.fetchRecords(with: [recordID]).get()
    } catch {
      XCTAssertEqual(error , CKRecordError(from: CKError(CKError.Code.notAuthenticated)))
    }
  }
  
  func test_fetch_records_result_failure() async {
    let recordID = CKRecord.ID(recordName: "testRecord")
    let record = CKRecord(recordType: "TestRecord", recordID: recordID)
    let db = ReplayingMockCKDatabase(operationResults: [
      .fetch(
        .init(
          fetchRecordResults: [
            .init(recordID: recordID, result: .success(record))
          ],
          fetchResult: .init(result: .failure(CKError(CKError.Code.managedAccountRestricted)))
        )
      )
    ])
    let api = databaseAPI(db)
    do {
      let _ = try await api.fetchRecords(with: [recordID]).get()
    } catch {
      XCTAssertEqual(error , CKRecordError(from: CKError(CKError.Code.managedAccountRestricted)))
    }
  }
  
  func test_fetch_records_not_found() async {
    let recordID = CKRecord.ID(recordName: "testRecord")
    let recordID2 = CKRecord.ID(recordName: "testRecord2")
    let record = CKRecord(recordType: "TestRecord", recordID: recordID)
    let db = ReplayingMockCKDatabase(operationResults: [
      .fetch(
        .init(
          fetchRecordResults: [
            .init(recordID: recordID, result: .success(record)),
            .init(recordID: recordID2, result: .failure(CKError(CKError.Code.unknownItem)))
          ],
          fetchResult: .init(result: .success(()))
        )
      )
    ])
    let api = databaseAPI(db)
    let fetchResult = try! await api.fetchRecords(with: [recordID]).get()
    XCTAssertTrue(fetchResult.foundRecords.first!.isEqualToRecord(record.canopyResultRecord))
    XCTAssertEqual(fetchResult.notFoundRecordIDs, [recordID2])
  }
  
  func test_modify_zones_success() async {
    let zoneToSave = CKRecordZone(zoneID: .init(zoneName: "SomeZone"))
    let zoneIDToDelete = CKRecordZone.ID(zoneName: "ZoneToDelete")
    let db = ReplayingMockCKDatabase(operationResults: [
      .modifyZones(
        .init(
          savedZoneResults: [
            .init(zoneID: zoneToSave.zoneID, result: .success(zoneToSave))
          ],
          deletedZoneIDResults: [
            .init(zoneID: zoneIDToDelete, result: .success(()))
          ],
          modifyZonesResult: .init(result: .success(()))
        )
      )
    ])
    let api = databaseAPI(db)
    let result = try! await api.modifyZones(saving: [zoneToSave], deleting: [zoneIDToDelete]).get()
    XCTAssertEqual(result.deletedZoneIDs.first!, zoneIDToDelete)
    XCTAssertTrue(result.savedZones.first!.isEqualToZone(zoneToSave))
  }
  
  func test_modify_zones_save_failure() async {
    let zoneToSave = CKRecordZone(zoneID: .init(zoneName: "SomeZone"))
    let zoneIDToDelete = CKRecordZone.ID(zoneName: "ZoneToDelete")
    let db = ReplayingMockCKDatabase(operationResults: [
      .modifyZones(
        .init(
          savedZoneResults: [
            .init(zoneID: zoneToSave.zoneID, result: .failure(CKError(CKError.Code.networkUnavailable)))
          ],
          deletedZoneIDResults: [
            .init(zoneID: zoneIDToDelete, result: .success(()))
          ],
          modifyZonesResult: .init(result: .success(()))
        )
      )
    ])
    let api = databaseAPI(db)
    do {
      let _ = try await api.modifyZones(saving: [zoneToSave], deleting: [zoneIDToDelete]).get()
    } catch {
      XCTAssertEqual(error , CKRecordZoneError(from: CKError(CKError.Code.networkUnavailable)))
    }
  }
  
  func test_modify_zones_delete_failure() async {
    let zoneToSave = CKRecordZone(zoneID: .init(zoneName: "SomeZone"))
    let zoneIDToDelete = CKRecordZone.ID(zoneName: "ZoneToDelete")
    let db = ReplayingMockCKDatabase(operationResults: [
      .modifyZones(
        .init(
          savedZoneResults: [
            .init(zoneID: zoneToSave.zoneID, result: .success(zoneToSave))
          ],
          deletedZoneIDResults: [
            .init(zoneID: zoneIDToDelete, result: .failure(CKError(CKError.Code.accountTemporarilyUnavailable)))
          ],
          modifyZonesResult: .init(result: .success(()))
        )
      )
    ])
    let api = databaseAPI(db)
    do {
      let _ = try await api.modifyZones(saving: [zoneToSave], deleting: [zoneIDToDelete]).get()
    } catch {
      XCTAssertEqual(error , CKRecordZoneError(from: CKError(CKError.Code.accountTemporarilyUnavailable)))
    }
  }
  
  func test_modify_zones_operation_failure() async {
    let zoneToSave = CKRecordZone(zoneID: .init(zoneName: "SomeZone"))
    let zoneIDToDelete = CKRecordZone.ID(zoneName: "ZoneToDelete")
    let db = ReplayingMockCKDatabase(operationResults: [
      .modifyZones(
        .init(
          savedZoneResults: [
            .init(zoneID: zoneToSave.zoneID, result: .success(zoneToSave))
          ],
          deletedZoneIDResults: [
            .init(zoneID: zoneIDToDelete, result: .success(()))
          ],
          modifyZonesResult: .init(result: .failure(CKError(CKError.Code.invalidArguments)))
        )
      )
    ])
    let api = databaseAPI(db)
    do {
      let _ = try await api.modifyZones(saving: [zoneToSave], deleting: [zoneIDToDelete]).get()
    } catch {
      XCTAssertEqual(error , CKRecordZoneError(from: CKError(CKError.Code.invalidArguments)))
    }
  }
  
  func test_fetch_all_zones_success() async {
    let mockZone = CKRecordZone(zoneID: .init(zoneName: "MockZone", ownerName: CKCurrentUserDefaultName))
    let db = ReplayingMockCKDatabase(operationResults: [
      .fetchZones(
        .init(
          fetchZoneResults: [
            .init(zoneID: mockZone.zoneID, result: .success(mockZone))
          ],
          fetchZonesResult: .init(result: .success(()))
        )
      )
    ])
    let api = databaseAPI(db)
    let result = try! await api.fetchAllZones(qualityOfService: .default).get()
    XCTAssertTrue(result.first!.isEqualToZone(mockZone))
  }
  
  func test_fetch_zones_success() async {
    let mockZone = CKRecordZone(zoneID: .init(zoneName: "MockZone", ownerName: CKCurrentUserDefaultName))
    let db = ReplayingMockCKDatabase(operationResults: [
      .fetchZones(
        .init(
          fetchZoneResults: [
            .init(zoneID: mockZone.zoneID, result: .success(mockZone))
          ],
          fetchZonesResult: .init(result: .success(()))
        )
      )
    ])
    let api = databaseAPI(db)
    let result = try! await api.fetchAllZones(qualityOfService: .default).get()
    XCTAssertTrue(result.first!.isEqualToZone(mockZone))
  }
  
  func test_fetch_zones_one_failure() async {
    let mockZone = CKRecordZone(zoneID: .init(zoneName: "MockZone", ownerName: CKCurrentUserDefaultName))
    let db = ReplayingMockCKDatabase(operationResults: [
      .fetchZones(
        .init(
          fetchZoneResults: [
            .init(zoneID: mockZone.zoneID, result: .failure(CKError(CKError.Code.badDatabase)))
          ],
          fetchZonesResult: .init(result: .success(()))
        )
      )
    ])
    let api = databaseAPI(db)
    do {
      let _ = try await api.fetchZones(with: [mockZone.zoneID]).get()
    } catch {
      XCTAssertEqual(error , CKRecordZoneError(from: CKError(CKError.Code.badDatabase)))
    }
  }
  
  func test_fetch_zones_result_failure() async {
    let mockZone = CKRecordZone(zoneID: .init(zoneName: "MockZone", ownerName: CKCurrentUserDefaultName))
    let db = ReplayingMockCKDatabase(operationResults: [
      .fetchZones(
        .init(
          fetchZoneResults: [
            .init(zoneID: mockZone.zoneID, result: .success(mockZone))
          ],
          fetchZonesResult: .init(result: .failure(CKError(CKError.Code.zoneNotFound)))
        )
      )
    ])
    let api = databaseAPI(db)
    do {
      let _ = try await api.fetchZones(with: [mockZone.zoneID]).get()
    } catch {
      XCTAssertEqual(error , CKRecordZoneError(from: CKError(CKError.Code.zoneNotFound)))
    }
  }
  
  func test_modify_subscriptions_success() async {
    let subscriptionID = CKSubscription.ID("DBSubscription")
    let subscriptionIDToDelete = CKSubscription.ID("DBSubscriptionToDelete")
    let subscription = CKDatabaseSubscription(subscriptionID: subscriptionID)
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .modifySubscriptions(
          .init(
            savedSubscriptionResults: [
              .init(subscriptionID: subscriptionID, result: .success(subscription))
            ],
            deletedSubscriptionIDResults: [
              .init(subscriptionID: subscriptionIDToDelete, result: .success(()))
            ],
            modifySubscriptionsResult: .init(result: .success(()))
          )
        )
      ]
    )
    let api = databaseAPI(db)
    let result = try! await api.modifySubscriptions(saving: [subscription]).get()
    XCTAssertEqual(result, .init(savedSubscriptions: [subscription], deletedSubscriptionIDs: [subscriptionIDToDelete]))
  }
  
  func test_modify_subscriptions_save_failure() async {
    let subscriptionID = CKSubscription.ID("DBSubscription")
    let subscriptionIDToDelete = CKSubscription.ID("DBSubscriptionToDelete")
    let subscription = CKDatabaseSubscription(subscriptionID: subscriptionID)
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .modifySubscriptions(
          .init(
            savedSubscriptionResults: [
              .init(subscriptionID: subscriptionID, result: .failure(CKError(CKError.Code.badDatabase)))
            ],
            deletedSubscriptionIDResults: [
              .init(subscriptionID: subscriptionIDToDelete, result: .success(()))
            ],
            modifySubscriptionsResult: .init(result: .success(()))
          )
        )
      ]
    )
    let api = databaseAPI(db)
    do {
      let _ = try await api.modifySubscriptions(saving: [subscription]).get()
    } catch {
      XCTAssertEqual(error , CKSubscriptionError(from: CKError(CKError.Code.badDatabase)))
    }
  }
  
  func test_modify_subscriptions_delete_failure() async {
    let subscriptionID = CKSubscription.ID("DBSubscription")
    let subscriptionIDToDelete = CKSubscription.ID("DBSubscriptionToDelete")
    let subscription = CKDatabaseSubscription(subscriptionID: subscriptionID)
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .modifySubscriptions(
          .init(
            savedSubscriptionResults: [
              .init(subscriptionID: subscriptionID, result: .success(subscription))
            ],
            deletedSubscriptionIDResults: [
              .init(subscriptionID: subscriptionIDToDelete, result: .failure(CKError(CKError.Code.badDatabase)))
            ],
            modifySubscriptionsResult: .init(result: .success(()))
          )
        )
      ]
    )
    let api = databaseAPI(db)
    do {
      let _ = try await api.modifySubscriptions(saving: [subscription]).get()
    } catch {
      XCTAssertEqual(error , CKSubscriptionError(from: CKError(CKError.Code.badDatabase)))
    }
  }
  
  func test_modify_subscriptions_operation_failure() async {
    let subscriptionID = CKSubscription.ID("DBSubscription")
    let subscriptionIDToDelete = CKSubscription.ID("DBSubscriptionToDelete")
    let subscription = CKDatabaseSubscription(subscriptionID: subscriptionID)
    let db = ReplayingMockCKDatabase(
      operationResults: [
        .modifySubscriptions(
          .init(
            savedSubscriptionResults: [
              .init(subscriptionID: subscriptionID, result: .success(subscription))
            ],
            deletedSubscriptionIDResults: [
              .init(subscriptionID: subscriptionIDToDelete, result: .success(()))
            ],
            modifySubscriptionsResult: .init(result: .failure(CKError(CKError.Code.badDatabase)))
          )
        )
      ]
    )
    let api = databaseAPI(db)
    do {
      let _ = try await api.modifySubscriptions(saving: [subscription]).get()
    } catch {
      XCTAssertEqual(error , CKSubscriptionError(from: CKError(CKError.Code.badDatabase)))
    }
  }
}
