import CloudKit

public struct ModifySubscriptionsResult: Equatable, Sendable {
  public let savedSubscriptions: [CKSubscription]
  public let deletedSubscriptionIDs: [CKSubscription.ID]
  
  public init(savedSubscriptions: [CKSubscription], deletedSubscriptionIDs: [CKSubscription.ID]) {
    self.savedSubscriptions = savedSubscriptions
    self.deletedSubscriptionIDs = deletedSubscriptionIDs
  }
}

extension ModifySubscriptionsResult: Codable {
  enum CodingKeys: CodingKey {
    case savedSubscriptions
    case deletedSubscriptionIDs
  }
  
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let savedSubscriptionsData = try container.decode(Data.self, forKey: .savedSubscriptions)
    if let savedSubscriptions = try? NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: CKSubscription.self, from: savedSubscriptionsData) {
      self.savedSubscriptions = savedSubscriptions
    } else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: [CodingKeys.savedSubscriptions],
          debugDescription: "Invalid saved subscriptions value in source data"
        )
      )
    }
    deletedSubscriptionIDs = try container.decode([CKSubscription.ID].self, forKey: .deletedSubscriptionIDs)
  }
  
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(deletedSubscriptionIDs, forKey: .deletedSubscriptionIDs)
    let savedSubscriptionsData = try NSKeyedArchiver.archivedData(withRootObject: savedSubscriptions, requiringSecureCoding: true)
    try container.encode(savedSubscriptionsData, forKey: .savedSubscriptions)
  }
}
