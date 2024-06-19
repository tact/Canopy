//
//  SyncTransactionError.swift
//  SyncTransactionError
//
//  Created by Andrew Tetlaw on 27/8/21.
//  Copyright © 2021 Jaanus Kase. All rights reserved.
//

import CloudKit
import Foundation

public enum CanopyError: Error, Codable, Equatable, Sendable {
  case unknown
  case ckAccountError(String, Int) // description, code
  case ckSavedRecordsIsEmpty
  case ckDeletedRecordIDsIsEmpty
  case ckTimeout
  case ckRecordError(CKRecordError)
  case ckRecordZoneError(CKRecordZoneError)
  case ckSubscriptionError(CKSubscriptionError)
  case ckChangeTokenExpired
  case ckRequestError(CKRequestError) // description, code
  case canceled

  public var localizedDescription: String {
    switch self {
    case let .ckRecordError(error):
      return error.localizedDescription
    case let .ckRecordZoneError(error):
      return error.localizedDescription
    case let .ckSubscriptionError(error):
      return error.localizedDescription
    case let .ckRequestError(error):
      return error.localizedDescription
    case .unknown:
      return "Unknown error"
    case .ckSavedRecordsIsEmpty:
      return "Saved records is empty"
    case .ckDeletedRecordIDsIsEmpty:
      return "Deleted record IDs is empty"
    case .ckTimeout:
      return "Request has not completed in the expected time"
    case let .ckAccountError(reason, code):
      return "Error fetching account status: \(reason) (\(code))"
    case .ckChangeTokenExpired:
      return "Server change token expired"
    case .canceled:
      return "Request was canceled"
    }
  }

  public var code: Int {
    switch self {
    case let .ckRecordError(error):
      return error.code
    case let .ckRecordZoneError(error):
      return error.code
    case let .ckSubscriptionError(error):
      return error.code
    case let .ckRequestError(error):
      return error.code
    case .unknown:
      return 999
    case .ckSavedRecordsIsEmpty:
      return 1000
    case .ckDeletedRecordIDsIsEmpty:
      return 1001
    case .ckTimeout:
      return 1002
    case let .ckAccountError(_, code):
      return code
    case .ckChangeTokenExpired:
      return CKError.Code.changeTokenExpired.rawValue
    case .canceled:
      return 1003
    }
  }

  public var retryAfterSeconds: Double {
    switch self {
    case let .ckRecordError(error):
      return error.retryAfterSeconds
    case let .ckRecordZoneError(error):
      return error.retryAfterSeconds
    case let .ckSubscriptionError(error):
      return error.retryAfterSeconds
    case let .ckRequestError(error):
      return error.retryAfterSeconds
    default:
      return 0
    }
  }

  public var errorDump: String {
    switch self {
    case let .ckRecordError(error):
      return error.errorDump
    case let .ckRecordZoneError(error):
      return error.errorDump
    case let .ckSubscriptionError(error):
      return error.errorDump
    case let .ckRequestError(error):
      return error.errorDump
    default:
      return "SyncTransactionError \(code) \(localizedDescription)"
    }
  }
  
  public init(from error: Error) {
    if let requestError = error as? CKError {
      switch requestError.code {
      case .changeTokenExpired:
        self = .ckChangeTokenExpired
      default:
        self = .ckRequestError(CKRequestError(from: requestError))
      }
    } else {
      self = .ckRequestError(CKRequestError(from: error as NSError))
    }
  }

  public static func accountError(from error: Error) -> CanopyError {
    if let accountError = error as? CKError {
      return CanopyError.ckAccountError(accountError.localizedDescription, accountError.errorCode)
    } else {
      return CanopyError.ckAccountError(String(describing: error), 0)
    }
  }
  
  /// Recreate the CKError.
  ///
  /// This is likely lossy, resulting in loss of fidelity compared to the original CKError.
  /// What’s preserved is the code and description.
  ///
  /// The main use of this is in testing, to recreate the error from possibly archived CanopyError.
  public var ckError: CKError {
    switch self {
    case let .ckAccountError(description, code):
      return CKError(CKError.Code(rawValue: code)!, userInfo: ["localizedDescription": description])
    case let .ckRecordError(ckRecordError):
      return ckRecordError.ckError
    case let .ckRequestError(ckRequestError):
      return ckRequestError.ckError
    case .ckChangeTokenExpired:
      return CKError(CKError.Code.changeTokenExpired)
    case let .ckSubscriptionError(subscriptionError):
      return subscriptionError.ckError
    default:
      fatalError("Not implemented")
    }
  }
}

extension CanopyError: LocalizedError {
  public var errorDescription: String? {
    localizedDescription
  }
  
  public var recoverySuggestion: String? {
    "Check your network connection and iCloud account settings."
  }
}
