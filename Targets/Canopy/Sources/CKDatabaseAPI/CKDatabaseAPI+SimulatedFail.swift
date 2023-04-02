import CloudKit

extension CKDatabaseAPI {
  func randomCKRecordError(
    codes: Set<CKError.Code>,
    saving recordsToSave: [CKRecord]? = nil,
    deleting recordIDsToDelete: [CKRecord.ID]? = nil,
    includePartialErrors: Bool = false
  ) -> CKRecordError {
    let code = codes.randomElement()!
    var info: [String: Any] = [:]

    if CKRecordError.retriableErrors.contains(code) {
      info[CKErrorRetryAfterKey] = NSNumber(10)
    }
    
    // Add the partial error dictionary, to be more realistic
    if includePartialErrors {
      // Don't fall into an infinite hell hole
      let otherCodes = codes.subtracting([.partialFailure])

      var partialErrors: [AnyHashable: Error] = [:]
      if let saved = recordsToSave {
        saved.forEach {
          partialErrors[$0.recordID] = randomCKRecordError(codes: otherCodes).ckError
        }
      }

      if let deleted = recordIDsToDelete {
        deleted.forEach {
          partialErrors[$0] = randomCKRecordError(codes: otherCodes).ckError
        }
      }

      info[CKPartialErrorsByItemIDKey] = partialErrors
    }

    let error = CKError(code, userInfo: info)
    return CKRecordError(from: error)
  }
  
  func randomCKRequestError(
    codes: Set<CKError.Code>
  ) -> CKRequestError {
    let code = codes.randomElement()!
    var info: [String: Any] = [:]
    
    if CKRecordError.retriableErrors.contains(code) {
      info[CKErrorRetryAfterKey] = NSNumber(10)
    }
    
    let error = CKError(code, userInfo: info)
    return CKRequestError(from: error)
  }
}
