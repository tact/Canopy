import CanopyTypes
import CloudKit

public extension ReplayingMockCKDatabase {
  struct FetchZoneResult: Codable {
    public let zoneIDArchive: CloudKitRecordZoneIDArchive
    let codableResult: CodableResult<CloudKitRecordZoneArchive, CKRecordZoneError>
    
    public init(zoneID: CKRecordZone.ID, result: Result<CKRecordZone, Error>) {
      self.zoneIDArchive = CloudKitRecordZoneIDArchive(zoneIDs: [zoneID])
      switch result {
      case let .success(zone): self.codableResult = .success(CloudKitRecordZoneArchive(zones: [zone]))
      case let .failure(error): self.codableResult = .failure(CKRecordZoneError(from: error))
      }
    }

    public var result: Result<CKRecordZone, Error> {
      switch codableResult {
      case let .success(zoneArchive): return .success(zoneArchive.zones.first!)
      case let .failure(error): return .failure(error.ckError)
      }
    }
  }
  
  struct FetchZonesResult: Codable {
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
  
  struct FetchZonesOperationResult: Codable {
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
