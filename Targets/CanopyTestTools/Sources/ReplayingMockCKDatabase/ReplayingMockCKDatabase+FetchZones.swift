import CloudKit
import CanopyTypes

extension ReplayingMockCKDatabase {
  
  public struct FetchZoneResult: Codable {
    
    public let zoneIDArchive: CloudKitRecordZoneIDArchive
    let codableResult: CodableResult<CloudKitRecordZoneArchive, CKRecordZoneError>
    
    public init(zoneID: CKRecordZone.ID, result: Result<CKRecordZone, Error>) {
      self.zoneIDArchive = CloudKitRecordZoneIDArchive(zoneIDs: [zoneID])
      switch result {
      case .success(let zone): codableResult = .success(CloudKitRecordZoneArchive(zones: [zone]))
      case .failure(let error): codableResult = .failure(CKRecordZoneError(from: error))
      }
    }

    public var result: Result<CKRecordZone, Error> {
      switch codableResult {
      case .success(let zoneArchive): return .success(zoneArchive.zones.first!)
      case .failure(let error): return .failure(error.ckError)
      }
    }
  }
  
  public struct FetchZonesResult: Codable {
    
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
  
  public struct FetchZonesOperationResult: Codable {
    let fetchZoneResults: [FetchZoneResult]
    let fetchZonesResult: FetchZonesResult
    
    public init(fetchZoneResults: [FetchZoneResult], fetchZonesResult: FetchZonesResult) {
      self.fetchZoneResults = fetchZoneResults
      self.fetchZonesResult = fetchZonesResult
    }
  }
  
  internal func runFetchZonesOperation(
    _ operation: CKFetchRecordZonesOperation,
    operationResult: FetchZonesOperationResult
  ) {
    for fetchZoneResult in operationResult.fetchZoneResults {
      operation.perRecordZoneResultBlock?(fetchZoneResult.zoneIDArchive.zoneIDs.first!, fetchZoneResult.result)
    }
    operation.fetchRecordZonesResultBlock?(operationResult.fetchZonesResult.result)
  }
}
