import CloudKit
import CanopyTypes

// Types and functionality for CKModifyRecordsOperation results.
extension ReplayingMockCKDatabase {
  /// Result for one saved record. perRecordSaveBlock is called with this.
  public struct SavedRecordResult: Codable {
    
    let recordIDArchive: CloudKitRecordIDArchive
    let codableResult: CodableResult<CloudKitRecordArchive, CKRecordError>
    
    public init(recordID: CKRecord.ID, result: Result<CKRecord, Error>) {
      self.recordIDArchive = CloudKitRecordIDArchive(recordIDs: [recordID])
      switch result {
      case .success(let record): codableResult = .success(CloudKitRecordArchive(records: [record]))
      case .failure(let error): codableResult = .failure(CKRecordError(from: error))
      }
    }

    var result: Result<CKRecord, Error> {
      switch codableResult {
      case .success(let recordArchive): return .success(recordArchive.records.first!)
      case .failure(let recordError): return .failure(recordError.ckError)
      }
    }
  }
  
  /// Result for one deleted record. perRecordDeleteBlock is called with this.
  public struct DeletedRecordIDResult: Codable {
    let recordIDArchive: CloudKitRecordIDArchive
    let codableResult: CodableResult<CodableVoid, CKRecordError>
    
    public init(recordID: CKRecord.ID, result: Result<Void, Error>) {
      self.recordIDArchive = CloudKitRecordIDArchive(recordIDs: [recordID])
      switch result {
      case .failure(let error): codableResult = .failure(CKRecordError(from: error))
      case .success: codableResult = .success(CodableVoid())
      }
    }

    var result: Result<Void, Error> {
      switch codableResult {
      case .success: return .success(())
      case .failure(let recordError): return .failure(recordError.ckError)
      }
    }
  }
  
  public struct ModifyResult: Codable {
    let codableResult: CodableResult<CodableVoid, CKRecordError>
    
    public init(result: Result<Void, Error>) {
      switch result {
      case .success: codableResult = .success(CodableVoid())
      case .failure(let error): codableResult = .failure(CKRecordError(from: error))
      }
    }

    var result: Result<Void, Error> {
      switch codableResult {
      case .success: return .success(())
      case .failure(let recordError): return .failure(recordError.ckError)
      }
    }
  }
  
  public struct ModifyOperationResult: Codable {
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
