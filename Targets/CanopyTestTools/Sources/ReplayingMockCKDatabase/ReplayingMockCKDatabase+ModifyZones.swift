import CanopyTypes
import CloudKit

public extension ReplayingMockCKDatabase {
  struct SavedZoneResult: Codable, Sendable {
    let zoneIDArchive: CloudKitRecordZoneIDArchive
    let codableResult: CodableResult<CloudKitRecordZoneArchive, CKRecordZoneError>
    
    public init(zoneID: CKRecordZone.ID, result: Result<CKRecordZone, Error>) {
      self.zoneIDArchive = CloudKitRecordZoneIDArchive(zoneIDs: [zoneID])
      switch result {
      case let .success(zone): self.codableResult = .success(CloudKitRecordZoneArchive(zones: [zone]))
      case let .failure(error): self.codableResult = .failure(CKRecordZoneError(from: error))
      }
    }

    var result: Result<CKRecordZone, Error> {
      switch codableResult {
      case let .success(zoneArchive): return .success(zoneArchive.zones.first!)
      case let .failure(zoneError): return .failure(zoneError.ckError)
      }
    }
  }
  
  struct DeletedZoneIDResult: Codable, Sendable {
    let zoneIDArchive: CloudKitRecordZoneIDArchive
    let codableResult: CodableResult<CodableVoid, CKRecordZoneError>
    
    public init(zoneID: CKRecordZone.ID, result: Result<Void, Error>) {
      self.zoneIDArchive = CloudKitRecordZoneIDArchive(zoneIDs: [zoneID])
      switch result {
      case .success: self.codableResult = .success(CodableVoid())
      case let .failure(error): self.codableResult = .failure(CKRecordZoneError(from: error))
      }
    }

    var result: Result<Void, Error> {
      switch codableResult {
      case .success: return .success(())
      case let .failure(zoneError): return .failure(zoneError.ckError)
      }
    }
  }
  
  struct ModifyZonesResult: Codable, Sendable {
    let codableResult: CodableResult<CodableVoid, CKRecordZoneError>
    
    public init(result: Result<Void, Error>) {
      switch result {
      case .success: self.codableResult = .success(CodableVoid())
      case let .failure(error): self.codableResult = .failure(CKRecordZoneError(from: error))
      }
    }

    var result: Result<Void, Error> {
      switch codableResult {
      case .success: return .success(())
      case let .failure(zoneError): return .failure(zoneError.ckError)
      }
    }
  }
  
  struct ModifyZonesOperationResult: Codable, Sendable {
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
