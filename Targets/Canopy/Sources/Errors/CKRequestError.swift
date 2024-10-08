import CloudKit
import Foundation

// CKRequestError for general requests

public struct CKRequestError: CKTransactionError, Codable, Equatable {
  public let code: Int
  public let localizedDescription: String
  public let retryAfterSeconds: Double
  public let errorDump: String

  public var hasMultipleErrors: Bool {
    false
  }

  public init(from error: Error) {
    self.errorDump = String(describing: error)
    self.localizedDescription = error.localizedDescription

    if let ckError = error as? CKError {
      self.code = ckError.errorCode
      self.retryAfterSeconds = ckError.retryAfterSeconds ?? 0
    } else {
      // Probably no need for this, just being complete about it
      let nsError = error as NSError
      self.code = nsError.code
      self.retryAfterSeconds = (nsError.userInfo[CKErrorRetryAfterKey] as? NSNumber)?.doubleValue ?? 0
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
  
  public static func == (lhs: CKRequestError, rhs: CKRequestError) -> Bool {
    lhs.code == rhs.code &&
      lhs.retryAfterSeconds == rhs.retryAfterSeconds
  }
}
