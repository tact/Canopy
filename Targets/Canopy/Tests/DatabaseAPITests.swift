@testable import Canopy
import CanopyTestTools
import CloudKit
import Foundation
import Testing

/// Contains most Canopy database API tests.
///
/// Some tests are in individual test classes (fetch changes).
@Suite struct DatabaseAPITests {
  private func databaseAPI(_ db: CKDatabaseType, settings: CanopySettingsType = CanopySettings()) -> CKDatabaseAPIType {
    CKDatabaseAPI(database: db, databaseScope: .private, settingsProvider: { settings }, tokenStore: TestTokenStore())
  }
  
  @Test func test_init_with_default_settings() async {
    let databaseAPI = CKDatabaseAPI(database: ReplayingMockCKDatabase(), databaseScope: .private, tokenStore: TestTokenStore())
    let fetchDatabaseChangesBehavior = await databaseAPI.settingsProvider().fetchDatabaseChangesBehavior
    #expect(fetchDatabaseChangesBehavior == .regular(nil))
  }
    
  @Test func test_query_records() async {
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
    
    #expect(result.first!.isEqualToRecord(record.canopyResultRecord) == true)
  }
  
  @Test func test_delete_records_success() async {
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
    #expect(result.deletedRecordIDs == [recordID])
  }
  
  @Test func test_delete_records_query_failure() async {
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
      #expect(error == CKRecordError(from: CKError(CKError.Code.notAuthenticated)))
    }
  }
  
  @Test func test_delete_records_empty_success() async {
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
    #expect(result.deletedRecordIDs == [])
  }
  
  @Test func test_fetch_records_success() async {
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
    #expect(result.foundRecords.first!.isEqualToRecord(record.canopyResultRecord) == true)
  }
  
  @Test func test_fetch_records_record_failure() async {
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
      #expect(error == CKRecordError(from: CKError(CKError.Code.notAuthenticated)))
    }
  }
  
  @Test func test_fetch_records_result_failure() async {
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
      #expect(error == CKRecordError(from: CKError(CKError.Code.managedAccountRestricted)))
    }
  }
  
  @Test func test_fetch_records_not_found() async {
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
    #expect(fetchResult.foundRecords.first!.isEqualToRecord(record.canopyResultRecord) == true)
    #expect(fetchResult.notFoundRecordIDs == [recordID2])
  }
  
  @Test func test_modify_zones_success() async {
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
    #expect(result.deletedZoneIDs.first == zoneIDToDelete)
    #expect(result.savedZones.first!.isEqualToZone(zoneToSave) == true)
  }
  
  @Test func test_modify_zones_save_failure() async {
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
      #expect(error == CKRecordZoneError(from: CKError(CKError.Code.networkUnavailable)))
    }
  }
  
  @Test func test_modify_zones_delete_failure() async {
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
      #expect(error == CKRecordZoneError(from: CKError(CKError.Code.accountTemporarilyUnavailable)))
    }
  }
  
  @Test func test_modify_zones_operation_failure() async {
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
      #expect(error == CKRecordZoneError(from: CKError(CKError.Code.invalidArguments)))
    }
  }
  
  @Test func test_fetch_all_zones_success() async {
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
    #expect(result.first!.isEqualToZone(mockZone) == true)
  }
  
  @Test func test_fetch_zones_success() async {
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
    #expect(result.first!.isEqualToZone(mockZone) == true)
  }
  
  @Test func test_fetch_zones_one_failure() async {
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
      #expect(error == CKRecordZoneError(from: CKError(CKError.Code.badDatabase)))
    }
  }
  
  @Test func test_fetch_zones_result_failure() async {
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
      #expect(error == CKRecordZoneError(from: CKError(CKError.Code.zoneNotFound)))
    }
  }
  
  @Test func test_modify_subscriptions_success() async {
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
    #expect(result == .init(savedSubscriptions: [subscription], deletedSubscriptionIDs: [subscriptionIDToDelete]))
  }
  
  @Test func test_modify_subscriptions_save_failure() async {
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
      #expect(error == CKSubscriptionError(from: CKError(CKError.Code.badDatabase)))
    }
  }
  
  @Test func test_modify_subscriptions_delete_failure() async {
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
      #expect(error == CKSubscriptionError(from: CKError(CKError.Code.badDatabase)))
    }
  }
  
  @Test func test_modify_subscriptions_operation_failure() async {
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
      #expect(error == CKSubscriptionError(from: CKError(CKError.Code.badDatabase)))
    }
  }
}
