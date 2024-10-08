import Canopy
import CloudKit
import XCTest

final class ModifySubscriptionResultTests: XCTestCase {
  func test_codes() throws {
    let result = ModifySubscriptionsResult(
      savedSubscriptions: [
        CKDatabaseSubscription(subscriptionID: "db1"),
        CKQuerySubscription(
          recordType: "SomeType",
          predicate: NSPredicate(value: true),
          subscriptionID: "query1"
        )
      ],
      deletedSubscriptionIDs: ["deletedID1", "deletedID2"]
    )
    
    let encoded = try JSONEncoder().encode(result)
    let decoded = try JSONDecoder().decode(ModifySubscriptionsResult.self, from: encoded)
    XCTAssertEqual(decoded.deletedSubscriptionIDs, ["deletedID1", "deletedID2"])
    XCTAssertEqual(decoded.savedSubscriptions[0].subscriptionID, "db1")
    XCTAssertEqual(decoded.savedSubscriptions[1].subscriptionID, "query1")
  }
  
  func test_throws_on_invalid_saved_subscriptions_data() {
    let badJson = "{\"savedSubscriptions\":\"deadBeef\",\"deletedSubscriptionIDs\":[\"sub1\",\"sub2\"]}"
    let data = badJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(ModifySubscriptionsResult.self, from: data)
    } catch DecodingError.dataCorrupted(let context) {
      XCTAssertEqual(context.debugDescription, "Invalid saved subscriptions value in source data")
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}
