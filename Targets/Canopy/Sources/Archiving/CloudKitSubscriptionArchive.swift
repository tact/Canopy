import CloudKit
import Foundation

public struct CloudKitSubscriptionArchive: Codable, Sendable {
  private let data: Data

  public var subscription: CKSubscription {
    let decodedRecord = try! NSKeyedUnarchiver.unarchivedObject(ofClass: CKSubscription.self, from: data)!
    return decodedRecord
  }

  public init(subscription: CKSubscription) {
    self.data = try! NSKeyedArchiver.archivedData(withRootObject: subscription, requiringSecureCoding: true)
  }
}
