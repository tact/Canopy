//
//  CKRecordError.swift
//  CKRecordError
//
//  Created by Andrew Tetlaw on 2/9/21.
//  Copyright © 2021 Jaanus Kase. All rights reserved.
//

import CloudKit
import Foundation

// CKRecordError for CKRecords, more error types in the future for other CK types.
// Reason is that the partial errors dictionary will be using different keys for different operations
// In this type, the keys are expected to be CKRecord.ID,

public struct CKRecordError: CKTransactionError, Codable, Equatable, Sendable {
  public let code: Int
  public let localizedDescription: String
  public let retryAfterSeconds: Double
  public let errorDump: String
  public let batchErrors: [String: CKRecordError]

  public var hasMultipleErrors: Bool {
    !batchErrors.isEmpty
  }

  public init(from error: Error) {
    self.errorDump = String(describing: error)
    self.localizedDescription = error.localizedDescription
    
    if let ckError = error as? CKError {
      self.code = ckError.errorCode
      self.retryAfterSeconds = ckError.retryAfterSeconds ?? 0
      self.batchErrors = CKRecordError.parseBatchErrors(dict: ckError.partialErrorsByItemID ?? [:])
    } else {
      // Probably no need for this, just being complete about it
      let nsError = error as NSError
      self.code = nsError.code
      self.retryAfterSeconds = (nsError.userInfo[CKErrorRetryAfterKey] as? NSNumber)?.doubleValue ?? 0
      self.batchErrors = CKRecordError.parseBatchErrors(dict: (nsError.userInfo[CKPartialErrorsByItemIDKey] as? [AnyHashable: Error]) ?? [:])
    }
  }

  private static func parseBatchErrors(dict: [AnyHashable: Error]) -> [String: CKRecordError] {
    dict.reduce(into: [:]) { partial, element in
      guard let recordID = element.key as? CKRecord.ID, let recordError = element.value as? CKError else {
        return
      }

      partial[recordID.recordName] = CKRecordError(from: recordError)
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
  
  public static func == (lhs: CKRecordError, rhs: CKRecordError) -> Bool {
    lhs.code == rhs.code &&
      lhs.retryAfterSeconds == rhs.retryAfterSeconds &&
      lhs.batchErrors == rhs.batchErrors
  }
}
