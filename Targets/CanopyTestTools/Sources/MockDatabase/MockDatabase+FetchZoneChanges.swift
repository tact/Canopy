import CloudKit
import CanopyTypes

extension MockDatabase {
  
  public struct RecordWasChangedInZoneResult: Codable {
    let recordIDArchive: CloudKitRecordIDArchive
    let codableResult: CodableResult<CloudKitRecordArchive, CKRequestError>
    
    public init(recordID: CKRecord.ID, result: Result<CKRecord, Error>) {
      self.recordIDArchive = CloudKitRecordIDArchive(recordIDs: [recordID])
      switch result {
      case .success(let record): codableResult = .success(CloudKitRecordArchive(records: [record]))
      case .failure(let error): codableResult = .failure(CKRequestError(from: error))
      }
    }
    
    var result: Result<CKRecord, Error> {
      switch codableResult {
      case .success(let recordArchive): return .success(recordArchive.records.first!)
      case .failure(let requestError): return .failure(requestError.ckError)
      }
    }
  }
  
  public struct RecordWithIDWasDeletedInZoneResult: Codable {
    let recordIDArchive: CloudKitRecordIDArchive
    let recordType: CKRecord.RecordType
    
    public init(recordID: CKRecord.ID, recordType: CKRecord.RecordType) {
      self.recordIDArchive = CloudKitRecordIDArchive(recordIDs: [recordID])
      self.recordType = recordType
    }
  }
  
  struct OneZoneFetchResultSuccess: Codable {
    let serverChangeTokenArchive: CloudKitServerChangeTokenArchive
    let clientChangeTokenData: Data?
    let moreComing: Bool
  }
  
  public struct OneZoneFetchResult: Codable {
    let zoneIDArchive: CloudKitRecordZoneIDArchive
    let codableResult: CodableResult<OneZoneFetchResultSuccess, CKRequestError>

    public static func successForZoneID(_ zoneID: CKRecordZone.ID) -> OneZoneFetchResult {
      OneZoneFetchResult(
        zoneID: zoneID,
        result: .success(
          (
            serverChangeToken: .mock,
            clientChangeTokenData: nil,
            moreComing: false
          )
        )
      )
    }
    
    public init(zoneID: CKRecordZone.ID, result: Result<(serverChangeToken: CKServerChangeToken, clientChangeTokenData: Data?, moreComing: Bool), Error>) {
      self.zoneIDArchive = CloudKitRecordZoneIDArchive(zoneIDs: [zoneID])
      switch result {
      case .success(let tuple): codableResult = .success(
        .init(
          serverChangeTokenArchive: CloudKitServerChangeTokenArchive(token: tuple.serverChangeToken),
          clientChangeTokenData: tuple.clientChangeTokenData,
          moreComing: tuple.moreComing
        )
      )
      case .failure(let error):
        codableResult = .failure(CKRequestError(from: error))
      }
    }

    var result: Result<(serverChangeToken: CKServerChangeToken, clientChangeTokenData: Data?, moreComing: Bool), Error> {
      switch codableResult {
      case .failure(let error): return .failure(error.ckError)
      case .success(let success): return .success((serverChangeToken: success.serverChangeTokenArchive.token, clientChangeTokenData: success.clientChangeTokenData, moreComing: success.moreComing))
      }
    }
  }
  
  public struct FetchZoneChangesResult: Codable {
    let codableResult: CodableResult<CodableVoid, CKRequestError>
        
    public init(result: Result<Void, Error>) {
      switch result {
      case .success: codableResult = .success(CodableVoid())
      case .failure(let error): codableResult = .failure(CKRequestError(from: error))
      }
    }
    
    var result: Result<Void, Error> {
      switch codableResult {
      case .success: return .success(())
      case .failure(let error): return .failure(error.ckError)
      }
    }
  }
  
  public struct FetchZoneChangesOperationResult: Codable {
    let recordWasChangedInZoneResults: [RecordWasChangedInZoneResult]
    let recordWithIDWasDeletedInZoneResults: [RecordWithIDWasDeletedInZoneResult]
    let oneZoneFetchResults: [OneZoneFetchResult]
    let fetchZoneChangesResult: FetchZoneChangesResult
    
    public init(
      recordWasChangedInZoneResults: [RecordWasChangedInZoneResult],
      recordWithIDWasDeletedInZoneResults: [RecordWithIDWasDeletedInZoneResult],
      oneZoneFetchResults: [OneZoneFetchResult],
      fetchZoneChangesResult: FetchZoneChangesResult
    ) {
      self.recordWasChangedInZoneResults = recordWasChangedInZoneResults
      self.recordWithIDWasDeletedInZoneResults = recordWithIDWasDeletedInZoneResults
      self.oneZoneFetchResults = oneZoneFetchResults
      self.fetchZoneChangesResult = fetchZoneChangesResult
    }
  }
  
  internal func runFetchZoneChangesOperation(
    _ operation: CKFetchRecordZoneChangesOperation,
    operationResult: FetchZoneChangesOperationResult,
    sleep: Float?
  ) async {
    
    if let sleep {
      try? await Task.sleep(nanoseconds: UInt64(sleep * Float(NSEC_PER_SEC)))
    }
    
    for recordWasChangedInZoneResult in operationResult.recordWasChangedInZoneResults {
      operation.recordWasChangedBlock?(recordWasChangedInZoneResult.recordIDArchive.recordIDs.first!, recordWasChangedInZoneResult.result)
    }
    for recordWithIDWasDeletedInZoneResult in operationResult.recordWithIDWasDeletedInZoneResults {
      operation.recordWithIDWasDeletedBlock?(recordWithIDWasDeletedInZoneResult.recordIDArchive.recordIDs.first!, recordWithIDWasDeletedInZoneResult.recordType)
    }
    for oneZoneFetchResult in operationResult.oneZoneFetchResults {
      operation.recordZoneFetchResultBlock?(oneZoneFetchResult.zoneIDArchive.zoneIDs.first!, oneZoneFetchResult.result)
    }
    operation.fetchRecordZoneChangesResultBlock?(operationResult.fetchZoneChangesResult.result)
  }
}
