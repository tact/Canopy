import CloudKit
import CanopyTypes

extension MockDatabase {
  
  public struct SavedZoneResult: Codable {
    let zoneIDArchive: CloudKitRecordZoneIDArchive
    let codableResult: CodableResult<CloudKitRecordZoneArchive, CKRecordZoneError>
    
    public init(zoneID: CKRecordZone.ID, result: Result<CKRecordZone, Error>) {
      self.zoneIDArchive = CloudKitRecordZoneIDArchive(zoneIDs: [zoneID])
      switch result {
      case .success(let zone): codableResult = .success(CloudKitRecordZoneArchive(zones: [zone]))
      case .failure(let error): codableResult = .failure(CKRecordZoneError(from: error))
      }
    }

    var result: Result<CKRecordZone, Error> {
      switch codableResult {
      case .success(let zoneArchive): return .success(zoneArchive.zones.first!)
      case .failure(let zoneError): return .failure(zoneError.ckError)
      }
    }
  }
  
  public struct DeletedZoneIDResult: Codable {
    let zoneIDArchive: CloudKitRecordZoneIDArchive
    let codableResult: CodableResult<CodableVoid, CKRecordZoneError>
    
    public init(zoneID: CKRecordZone.ID, result: Result<Void, Error>) {
      self.zoneIDArchive = CloudKitRecordZoneIDArchive(zoneIDs: [zoneID])
      switch result {
      case .success: codableResult = .success(CodableVoid())
      case .failure(let error): codableResult = .failure(CKRecordZoneError(from: error))
      }
    }

    var result: Result<Void, Error> {
      switch codableResult {
      case .success: return .success(())
      case .failure(let zoneError): return .failure(zoneError.ckError)
      }
    }
  }
  
  public struct ModifyZonesResult: Codable {
    let codableResult: CodableResult<CodableVoid, CKRecordZoneError>
    
    public init(result: Result<Void, Error>) {
      switch result {
      case .success: codableResult = .success(CodableVoid())
      case .failure(let error): codableResult = .failure(CKRecordZoneError(from: error))
      }
    }

    var result: Result<Void, Error> {
      switch codableResult {
      case .success: return .success(())
      case .failure(let zoneError): return .failure(zoneError.ckError)
      }
    }
  }
  
  public struct ModifyZonesOperationResult: Codable {
    public let savedZoneResults: [SavedZoneResult]
    public let deletedZoneIDResults: [DeletedZoneIDResult]
    public let modifyZonesResult: ModifyZonesResult
    
    public init(savedZoneResults: [SavedZoneResult], deletedZoneIDResults: [DeletedZoneIDResult], modifyZonesResult: ModifyZonesResult) {
      self.savedZoneResults = savedZoneResults
      self.deletedZoneIDResults = deletedZoneIDResults
      self.modifyZonesResult = modifyZonesResult
    }
  }
  
  internal func runModifyZonesOperation(
    _ operation: CKModifyRecordZonesOperation,
    operationResult: ModifyZonesOperationResult
  ) {
    for savedZoneResult in operationResult.savedZoneResults {
      operation.perRecordZoneSaveBlock?(savedZoneResult.zoneIDArchive.zoneIDs.first!, savedZoneResult.result)
    }
    for deletedZoneIDResult in operationResult.deletedZoneIDResults {
      operation.perRecordZoneDeleteBlock?(deletedZoneIDResult.zoneIDArchive.zoneIDs.first!, deletedZoneIDResult.result)
    }
    operation.modifyRecordZonesResultBlock?(operationResult.modifyZonesResult.result)
  }
}
