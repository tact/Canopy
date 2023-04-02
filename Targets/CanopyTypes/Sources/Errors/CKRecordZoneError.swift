//
//  CKRecordZoneError.swift
//  Tact
//
//  Created by Andrew Tetlaw on 5/1/2022.
//  Copyright © 2022 Jaanus Kase. All rights reserved.
//

import CloudKit
import Foundation

// CKRecordZoneError for CKRecordZones.
// In this type, the keys are expected to be CKRecord.ID,
public struct CKRecordZoneError: CKTransactionError, Codable, Equatable {
  public let code: Int
  public let localizedDescription: String
  public let retryAfterSeconds: Double
  public let errorDump: String
  public let batchErrors: [String: CKRecordZoneError]

  public var hasMultipleErrors: Bool {
    !batchErrors.isEmpty
  }

  public init(from error: Error) {
    self.errorDump = String(describing: error)
    self.localizedDescription = error.localizedDescription

    if let ckError = error as? CKError {
      self.code = ckError.errorCode
      self.retryAfterSeconds = ckError.retryAfterSeconds ?? 0
      self.batchErrors = CKRecordZoneError.parseBatchErrors(dict: ckError.partialErrorsByItemID ?? [:])
    } else {
      // Probably no need for this, just being complete about it
      let nsError = error as NSError
      self.code = nsError.code
      self.retryAfterSeconds = (nsError.userInfo[CKErrorRetryAfterKey] as? NSNumber)?.doubleValue ?? 0
      self.batchErrors = CKRecordZoneError.parseBatchErrors(dict: (nsError.userInfo[CKPartialErrorsByItemIDKey] as? [AnyHashable: Error]) ?? [:])
    }
  }

  private static func parseBatchErrors(dict: [AnyHashable: Error]) -> [String: CKRecordZoneError] {
    dict.reduce(into: [:]) { partial, element in
      guard let zoneID = element.key as? CKRecordZone.ID, let zoneError = element.value as? CKError else {
        return
      }

      partial[zoneID.zoneName] = CKRecordZoneError(from: zoneError)
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
  
  public static func == (lhs: CKRecordZoneError, rhs: CKRecordZoneError) -> Bool {
    lhs.code == rhs.code &&
      lhs.retryAfterSeconds == rhs.retryAfterSeconds &&
      lhs.batchErrors == rhs.batchErrors
  }
}
