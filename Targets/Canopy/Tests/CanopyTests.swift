@testable import Canopy
import CanopyTestTools
import CloudKit
import Testing

@Suite struct CanopyTests {
  @Test func test_init_with_default_settings() async {
    let _ = Canopy(
      container: ReplayingMockCKContainer(),
      publicCloudDatabase: ReplayingMockCKDatabase(),
      privateCloudDatabase: ReplayingMockCKDatabase(),
      sharedCloudDatabase: ReplayingMockCKDatabase(),
      tokenStore: TestTokenStore()
    )
  }
  
  @Test func test_settings_provider_uses_modified_value() async {
    let changedRecordID = CKRecord.ID(recordName: "SomeRecordName")
    let changedRecord = CKRecord(recordType: "TestRecord", recordID: changedRecordID)
    
    actor ModifiableSettings: CanopySettingsType {
      var modifyRecordsBehavior: RequestBehavior = .regular(nil)
      let fetchZoneChangesBehavior: RequestBehavior = .regular(nil)
      let fetchDatabaseChangesBehavior: RequestBehavior = .regular(nil)
      let autoBatchTooLargeModifyOperations: Bool = true
      let autoRetryForRetriableErrors: Bool = true
      
      func setModifyRecordsBehavior(behavior: RequestBehavior) {
        modifyRecordsBehavior = behavior
      }
    }
    
    let modifiableSettings = ModifiableSettings()
    
    let canopy = Canopy(
      container: ReplayingMockCKContainer(),
      publicCloudDatabase: ReplayingMockCKDatabase(),
      privateCloudDatabase: ReplayingMockCKDatabase(
        operationResults: [
          .modify(
            .init(
              savedRecordResults: [
                .init(recordID: changedRecordID, result: .success(changedRecord))
              ],
              deletedRecordIDResults: [],
              modifyResult: .init(result: .success(()))
            )
          ),
          .modify(
            .init(
              savedRecordResults: [],
              deletedRecordIDResults: [],
              modifyResult: .init(result: .success(()))
            )
          )
        ]
      ),
      sharedCloudDatabase: ReplayingMockCKDatabase(),
      settings: { modifiableSettings },
      tokenStore: TestTokenStore()
    )
    
    let api = await canopy.databaseAPI(usingDatabaseScope: .private)

    // First request will succeed.
    let result1 = try! await api.modifyRecords(saving: [changedRecord]).get()
    #expect(result1.savedRecords.count == 1)
    #expect(result1.savedRecords[0].isEqualToRecord(changedRecord.canopyResultRecord) == true)
    
    // Second request will fail after modifying the settings.
    await modifiableSettings.setModifyRecordsBehavior(behavior: .simulatedFail(nil))
    
    do {
      let _ = try await api.modifyRecords(saving: [changedRecord]).get()
    } catch {
      // Error is CKRecordError, so we use a CKRecordError API to test it
      #expect(error.batchErrors == [:])
    }
  }
  
  @Test func test_returns_same_api_instances() async {
    let canopy = Canopy(
      container: ReplayingMockCKContainer(),
      publicCloudDatabase: ReplayingMockCKDatabase(),
      privateCloudDatabase: ReplayingMockCKDatabase(),
      sharedCloudDatabase: ReplayingMockCKDatabase()
    )
    
    let privateApi1 = await canopy.databaseAPI(usingDatabaseScope: .private) as! CKDatabaseAPI
    let privateApi2 = await canopy.databaseAPI(usingDatabaseScope: .private) as! CKDatabaseAPI
    #expect(privateApi1 === privateApi2)

    let publicApi1 = await canopy.databaseAPI(usingDatabaseScope: .public) as! CKDatabaseAPI
    let publicApi2 = await canopy.databaseAPI(usingDatabaseScope: .public) as! CKDatabaseAPI
    #expect(publicApi1 === publicApi2)

    let sharedApi1 = await canopy.databaseAPI(usingDatabaseScope: .shared) as! CKDatabaseAPI
    let sharedApi2 = await canopy.databaseAPI(usingDatabaseScope: .shared) as! CKDatabaseAPI
    #expect(sharedApi1 === sharedApi2)

    let containerApi1 = await canopy.containerAPI() as! CKContainerAPI
    let containerApi2 = await canopy.containerAPI() as! CKContainerAPI
    
    #expect(containerApi1 === containerApi2)
  }
}
