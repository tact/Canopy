import CanopyTypes
import CloudKit

// Types and functionality for CKModifyRecordsOperation results.
public extension ReplayingMockCKDatabase {
  /// Result for one saved record. perRecordSaveBlock is called with this.
  struct SavedRecordResult: Codable, Sendable {
    let recordIDArchive: CloudKitRecordIDArchive
    let codableResult: CodableResult<CloudKitRecordArchive, CKRecordError>
    
    public init(recordID: CKRecord.ID, result: Result<CKRecord, Error>) {
      self.recordIDArchive = CloudKitRecordIDArchive(recordIDs: [recordID])
      switch result {
      case let .success(record): self.codableResult = .success(CloudKitRecordArchive(records: [record]))
      case let .failure(error): self.codableResult = .failure(CKRecordError(from: error))
      }
    }

    var result: Result<CKRecord, Error> {
      switch codableResult {
      case let .success(recordArchive): return .success(recordArchive.records.first!)
      case let .failure(recordError): return .failure(recordError.ckError)
      }
    }
  }
  
  /// Result for one deleted record. perRecordDeleteBlock is called with this.
  struct DeletedRecordIDResult: Codable, Sendable {
    let recordIDArchive: CloudKitRecordIDArchive
    let codableResult: CodableResult<CodableVoid, CKRecordError>
    
    public init(recordID: CKRecord.ID, result: Result<Void, Error>) {
      self.recordIDArchive = CloudKitRecordIDArchive(recordIDs: [recordID])
      switch result {
      case let .failure(error): self.codableResult = .failure(CKRecordError(from: error))
      case .success: self.codableResult = .success(CodableVoid())
      }
    }

    var result: Result<Void, Error> {
      switch codableResult {
      case .success: return .success(())
      case let .failure(recordError): return .failure(recordError.ckError)
      }
    }
  }
  
  struct ModifyResult: Codable, Sendable {
    let codableResult: CodableResult<CodableVoid, CKRecordError>
    
    public init(result: Result<Void, Error>) {
      switch result {
      case .success: self.codableResult = .success(CodableVoid())
      case let .failure(error): self.codableResult = .failure(CKRecordError(from: error))
      }
    }

    var result: Result<Void, Error> {
      switch codableResult {
      case .success: return .success(())
      case let .failure(recordError): return .failure(recordError.ckError)
      }
    }
  }
  
  struct ModifyOperationResult: Codable, Sendable {
    let savedRecordResults: [SavedRecordResult]
    let deletedRecordIDResults: [DeletedRecordIDResult]
    let modifyResult: ModifyResult
    
    public init(
      savedRecordResults: [SavedRecordResult],
      deletedRecordIDResults: [DeletedRecordIDResult],
      modifyResult: ModifyResult
    ) {
      self.savedRecordResults = savedRecordResults
      self.deletedRecordIDResults = deletedRecordIDResults
      self.modifyResult = modifyResult
    }
  }
  
  internal func runModifyOperation(
    _ operation: CKModifyRecordsOperation,
    operationResult: ModifyOperationResult
  ) {
    for savedRecordResult in operationResult.savedRecordResults {
      operation.perRecordSaveBlock?(savedRecordResult.recordIDArchive.recordIDs.first!, savedRecordResult.result)
    }
    for deletedRecordResult in operationResult.deletedRecordIDResults {
      operation.perRecordDeleteBlock?(deletedRecordResult.recordIDArchive.recordIDs.first!, deletedRecordResult.result)
    }
    operation.modifyRecordsResultBlock?(operationResult.modifyResult.result)
  }
}
