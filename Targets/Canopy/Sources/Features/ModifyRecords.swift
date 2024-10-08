import CloudKit

struct ModifyRecords {
  /// Default maximum batch size is 400.
  ///
  /// https://developer.apple.com/documentation/cloudkit/ckerror/code/limitexceeded
  ///
  /// We may receive `limitExceeded` error, in which case we will retry with a smaller batch size.
  static let CKBatchSize = 400
  
  public static func with(
    recordsToSave: [CKRecord]?,
    recordIDsToDelete: [CKRecord.ID]?,
    perRecordProgressBlock: CKDatabaseAPIType.PerRecordProgressBlock?,
    database: CKDatabaseType,
    qualityOfService: QualityOfService = .default,
    customBatchSize: Int? = nil,
    autoBatchToSmallerWhenLimitExceeded: Bool = true,
    autoRetryForRetriableErrors: Bool = true
  ) async -> Result<ModifyRecordsResult, CKRecordError> {
    var savedRecords: [CanopyResultRecord] = []
    var deletedRecordIDs: [CKRecord.ID] = []
    var currentBatchSize = customBatchSize ?? CKBatchSize
    
    var recordsToSaveStrided: [[CKRecord]] = []
    var recordIDsToDeleteStrided: [[CKRecord.ID]] = []
    
    if let recordsToSave {
      recordsToSaveStrided = chunk(recordsToSave, into: currentBatchSize)
    }
    
    if let recordIDsToDelete {
      recordIDsToDeleteStrided = chunk(recordIDsToDelete, into: currentBatchSize)
    }
    
    while true {
      let recordsToSaveChunk = recordsToSaveStrided.first
      let recordIDsToDeleteChunk = recordIDsToDeleteStrided.first
      if recordsToSaveChunk == nil,
         recordIDsToDeleteChunk == nil,
         !savedRecords.isEmpty || !deletedRecordIDs.isEmpty
      {
        return .success(
          .init(
            savedRecords: savedRecords,
            deletedRecordIDs: deletedRecordIDs
          )
        )
      }
      
      if recordsToSaveChunk != nil {
        recordsToSaveStrided.removeFirst()
      }
      
      if recordIDsToDeleteChunk != nil {
        recordIDsToDeleteStrided.removeFirst()
      }
      
      let result = await performOneOperationWithRetry(
        recordsToSave: recordsToSaveChunk,
        recordIDsToDelete: recordIDsToDeleteChunk,
        perRecordProgressBlock: perRecordProgressBlock,
        database: database,
        qualityOfService: qualityOfService,
        autoRetryForRetriableErrors: autoRetryForRetriableErrors
      )
            
      switch result {
      case let .success(result):
        savedRecords.append(contentsOf: result.savedRecords)
        deletedRecordIDs += result.deletedRecordIDs
      case let .failure(error):
        if error == CKRecordError(from: CKError(CKError.Code.limitExceeded)), autoBatchToSmallerWhenLimitExceeded {
          // CloudKit reports "limit exceeded". Platform guidance is to retry
          // with a smaller batch size.
          // So we do exactly that - split the batch in half and reset the state.
          // The loop will then re-run with smaller batch size.
          // https://developer.apple.com/documentation/cloudkit/ckerror/code/limitexceeded
          //
          // This behavior is controlled by the `autoBatchToSmallerWhenLimitExceeded` parameter.
          // If it’s false, we don’t autobatch, but return the original error right away.
          currentBatchSize /= 2
          savedRecords = []
          deletedRecordIDs = []
          
          if let recordsToSave {
            recordsToSaveStrided = chunk(recordsToSave, into: currentBatchSize)
          }
          
          if let recordIDsToDelete {
            recordIDsToDeleteStrided = chunk(recordIDsToDelete, into: currentBatchSize)
          }
          
        } else {
          return .failure(error)
        }
      }
      
      guard !Task.isCancelled else {
        return .failure(.init(from: CKError(CKError.Code.operationCancelled)))
      }
    }
  }
  
  private static func performOneOperationWithRetry(
    recordsToSave: [CKRecord]?,
    recordIDsToDelete: [CKRecord.ID]?,
    perRecordProgressBlock: CKDatabaseAPIType.PerRecordProgressBlock?,
    database: CKDatabaseType,
    qualityOfService: QualityOfService,
    autoRetryForRetriableErrors: Bool
  ) async -> Result<ModifyRecordsResult, CKRecordError> {
    var retriesRemaining = 3
    var result: Result<ModifyRecordsResult, CKRecordError>
    var done = false
    repeat {
      result = await performOneOperation(
        recordsToSave: recordsToSave,
        recordIDsToDelete: recordIDsToDelete,
        perRecordProgressBlock: perRecordProgressBlock,
        database: database,
        qualityOfService: qualityOfService
      )
      switch result {
      case .success:
        done = true
      case let .failure(recordError):
        if recordError.isRetriable, recordError.retryAfterSeconds > 0 {
          retriesRemaining -= 1
          try? await Task.sleep(nanoseconds: UInt64(recordError.retryAfterSeconds * Double(NSEC_PER_SEC)))
        } else {
          done = true
          break
        }
      }
    } while retriesRemaining > 0 && autoRetryForRetriableErrors && !done
    return result
  }
  
  private static func performOneOperation(
    recordsToSave: [CKRecord]?,
    recordIDsToDelete: [CKRecord.ID]?,
    perRecordProgressBlock: CKDatabaseAPIType.PerRecordProgressBlock?,
    database: CKDatabaseType,
    qualityOfService: QualityOfService
  ) async -> Result<ModifyRecordsResult, CKRecordError> {
    await withCheckedContinuation { continuation in
      
      guard !(recordsToSave?.isEmpty ?? true) || !(recordIDsToDelete?.isEmpty ?? true) else {
        // Both records to save and delete were empty.
        // This indicates a logic error by the caller.
        continuation.resume(returning: .failure(.init(from: CKError(CKError.Code.internalError))))
        return
      }
      
      let modifyOperation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
      modifyOperation.qualityOfService = qualityOfService
      modifyOperation.perRecordProgressBlock = perRecordProgressBlock
      
      var savedRecords: [CKRecord] = []
      var deletedRecordIDs: [CKRecord.ID] = []
      var recordError: CKRecordError?
      
      // This causes the record key values on the server side to be overwritten
      // with the uploaded key values, not comparing record change tags.
      // It is a simple “latest wins” policy that is appropriate for many apps.
      modifyOperation.savePolicy = .changedKeys
      
      // Cause the operation to fail for a given zone, if there is an error with modifying some records.
      modifyOperation.isAtomic = true
      
      modifyOperation.perRecordSaveBlock = { _, result in
        switch result {
        case let .success(record): savedRecords.append(record)
        case let .failure(error): recordError = CKRecordError(from: error)
        }
      }
      
      modifyOperation.perRecordDeleteBlock = { recordID, result in
        switch result {
        case .success: deletedRecordIDs.append(recordID)
        case let .failure(error): recordError = CKRecordError(from: error)
        }
      }
      
      modifyOperation.modifyRecordsResultBlock = { result in
        switch result {
        case let .failure(error):
          continuation.resume(returning: .failure(CKRecordError(from: error)))
        case .success:
          if let recordError {
            // Be defensive. If there was at least one record error, consider the whole operation failed.
            // This should match the CloudKit behavior with atomic zones and atomic modify operation.
            continuation.resume(returning: .failure(recordError))
          } else {
            continuation.resume(
              returning: .success(
                ModifyRecordsResult(
                  savedRecords: savedRecords.map(\.canopyResultRecord),
                  deletedRecordIDs: deletedRecordIDs
                )
              )
            )
          }
        }
      }
      
      database.add(modifyOperation)
    }
  }
  
  /// Chunk an array into batches of the given size.
  static func chunk<T>(_ array: [T], into size: Int) -> [[T]] {
    // https://stackoverflow.com/questions/53708126/swift-using-stride-with-an-int-array
    stride(from: 0, to: array.count, by: size).map {
      Array(array[$0 ..< min($0 + size, array.count)])
    }
  }
}
