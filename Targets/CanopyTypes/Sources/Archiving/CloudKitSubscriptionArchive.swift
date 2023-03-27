import CloudKit
import Foundation

public struct CloudKitSubscriptionArchive: Codable {
  private let data: Data

  public var subscription: CKSubscription {
    let decodedRecord = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)
    return decodedRecord as! CKSubscription
  }

  public init(subscription: CKSubscription) {
    data = try! NSKeyedArchiver.archivedData(withRootObject: subscription, requiringSecureCoding: true)
  }
}
