import CloudKit
import Foundation

public protocol CKTransactionError: Error {
  var code: Int { get }
  var localizedDescription: String { get }
  var retryAfterSeconds: Double { get }
  var errorDump: String { get }
  var hasMultipleErrors: Bool { get }
}

public extension CKTransactionError {
  var ckErrorCode: CKError.Code? {
    CKError.Code(rawValue: code)
  }

  var isRetriable: Bool {
    guard let error = ckErrorCode else { return false }
    return Self.retriableErrors.contains(error)
  }

  static var networkErrors: Set<CKError.Code> {
    [.networkUnavailable, .networkFailure, .serviceUnavailable, .serverResponseLost, .requestRateLimited, .zoneBusy]
  }

  static var batchErrors: Set<CKError.Code> {
    [.limitExceeded, .partialFailure, .batchRequestFailed]
  }

  static var retriableErrors: Set<CKError.Code> {
    networkErrors.union(batchErrors)
  }

  static var requestErrors: Set<CKError.Code> {
    [.invalidArguments, .changeTokenExpired, .serverRejectedRequest, .constraintViolation]
  }

  static var conflictErrors: Set<CKError.Code> {
    [.serverRecordChanged]
  }

  static var notFoundErrors: Set<CKError.Code> {
    [.unknownItem, .assetFileNotFound, .zoneNotFound, .referenceViolation, .assetNotAvailable, .userDeletedZone]
  }

  static var accountErrors: Set<CKError.Code> {
    [.quotaExceeded, .notAuthenticated, .participantMayNeedVerification, .managedAccountRestricted]
  }

  static var permissionErrors: Set<CKError.Code> {
    [.permissionFailure, .participantMayNeedVerification]
  }

  static var shareErrors: Set<CKError.Code> {
    [.tooManyParticipants, .alreadyShared, .participantMayNeedVerification]
  }

  static var nonRecoverableErrors: Set<CKError.Code> {
    [.internalError, .badContainer, .missingEntitlement, .incompatibleVersion, .badDatabase]
  }
}

/*
 CKError.Code.limitExceeded
 The server can change its limits at any time, but the following are general guidelines:
 400 items (records or shares) per operation
 2 MB per request (not counting asset sizes)
 If your app receives CKError.Code.limitExceeded, it must split the operation in half and try both requests again.

 CKError.Code.batchRequestFailed
 This error occurs when an operation attempts to save multiple items in a custom zone, but one of those items encounters an error. Because custom zones are atomic, the entire batch fails. The items that cause the problem have their own errors, and all other items in the batch have a CKError.Code.batchRequestFailed error to indicate that the system can’t save them.
 This error indicates that the system can’t process the associated item due to an error in another item in the operation. Check the other per-item errors under CKPartialErrorsByItemIDKey for any that aren't CKError.Code.batchRequestFailed errors. Handle those errors, and then retry all items in the operation.

 partialFailure
 Examine the specific item failures, and act on the failed items. Each specific item error is from the CloudKit error domain. You can inspect the userInfo CKPartialErrorsByItemIDKey to see per-item errors.
 Note that in a custom zone, the system processes all items in an operation atomically. As a result, you may get a CKError.Code.batchRequestFailed error for all other items in an operation that don't cause an error.

 internalError
 If you receive this error, file a bug report that includes the error log.

 networkUnavailable/networkFailure
 You can retry network failures immediately, but have your app implement a backoff period so that it doesn't attempt the same operation repeatedly.

 participantMayNeedVerification
 A fetch share metadata operation fails when the user isn’t a participant of the share. However, there are invited participants on the share with email addresses or phone numbers that don’t have associations with an iCloud account. The user may be able to join a share by associating one of those email addresses or phone numbers with the user's iCloud account.
 Call openURL(_:) on the share URL to have the user attempt to verify their information.

 requestRateLimited
 Check for a CKErrorRetryAfterKey key in the userInfo dictionary of any CloudKit error that you receive. It's especially important to check for it if you receive any of these errors. Use the value of the CKErrorRetryAfterKey key as the number of seconds to wait before retrying this operation.

 zoneBusy
 Try the operation again in a few seconds. If you encounter this error again, increase the delay time exponentially for each subsequent retry to minimize server contention for the zone.
 Check for a CKErrorRetryAfterKey key in the userInfo dictionary of any CloudKit error that you receive. Use the value of this key as the number of seconds to wait before retrying the operation.
 */
