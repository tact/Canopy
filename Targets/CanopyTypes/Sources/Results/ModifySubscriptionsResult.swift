import CloudKit

public struct ModifySubscriptionsResult: Equatable, Sendable {
  public let savedSubscriptions: [CKSubscription]
  public let deletedSubscriptionIDs: [CKSubscription.ID]
  
  public init(savedSubscriptions: [CKSubscription], deletedSubscriptionIDs: [CKSubscription.ID]) {
    self.savedSubscriptions = savedSubscriptions
    self.deletedSubscriptionIDs = deletedSubscriptionIDs
  }
}
