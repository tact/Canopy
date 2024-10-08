import CloudKit
import Foundation

// CKSubscriptionError for CKSubscriptions.
// In this type, the keys are expected to be CKSubscription.ID,
public struct CKSubscriptionError: CKTransactionError, Codable, Equatable, Sendable {
  public let code: Int
  public let localizedDescription: String
  public let retryAfterSeconds: Double
  public let errorDump: String
  public let batchErrors: [String: CKSubscriptionError]

  public var hasMultipleErrors: Bool {
    !batchErrors.isEmpty
  }

  public init(from error: Error) {
    self.errorDump = String(describing: error)
    self.localizedDescription = error.localizedDescription

    if let ckError = error as? CKError {
      self.code = ckError.errorCode
      self.retryAfterSeconds = ckError.retryAfterSeconds ?? 0
      self.batchErrors = CKSubscriptionError.parseBatchErrors(dict: ckError.partialErrorsByItemID ?? [:])
    } else {
      // Probably no need for this, just being complete about it
      let nsError = error as NSError
      self.code = nsError.code
      self.retryAfterSeconds = (nsError.userInfo[CKErrorRetryAfterKey] as? NSNumber)?.doubleValue ?? 0
      self.batchErrors = CKSubscriptionError.parseBatchErrors(dict: (nsError.userInfo[CKPartialErrorsByItemIDKey] as? [AnyHashable: Error]) ?? [:])
    }
  }

  private static func parseBatchErrors(dict: [AnyHashable: Error]) -> [String: CKSubscriptionError] {
    dict.reduce(into: [:]) { partial, element in
      guard let subID = element.key as? CKSubscription.ID, let zoneError = element.value as? CKError else {
        return
      }

      partial[subID] = CKSubscriptionError(from: zoneError)
    }
  }
  
  public var ckError: CKError {
    isRetriable ?
      CKError(
        ckErrorCode!,
        userInfo: [
          CKErrorRetryAfterKey: retryAfterSeconds
        ]
      )
      : CKError(ckErrorCode!)
  }
  
  public static func == (lhs: CKSubscriptionError, rhs: CKSubscriptionError) -> Bool {
    lhs.code == rhs.code &&
      lhs.retryAfterSeconds == rhs.retryAfterSeconds
  }
}
