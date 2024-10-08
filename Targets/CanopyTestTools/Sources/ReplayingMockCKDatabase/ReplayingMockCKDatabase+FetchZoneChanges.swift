import Canopy
import CloudKit

public extension ReplayingMockCKDatabase {
  struct RecordWasChangedInZoneResult: Codable, Sendable {
    let recordIDArchive: CloudKitRecordIDArchive
    let codableResult: CodableResult<CloudKitRecordArchive, CKRequestError>
    
    public init(recordID: CKRecord.ID, result: Result<CKRecord, Error>) {
      self.recordIDArchive = CloudKitRecordIDArchive(recordIDs: [recordID])
      switch result {
      case let .success(record): self.codableResult = .success(CloudKitRecordArchive(records: [record]))
      case let .failure(error): self.codableResult = .failure(CKRequestError(from: error))
      }
    }
    
    var result: Result<CKRecord, Error> {
      switch codableResult {
      case let .success(recordArchive): return .success(recordArchive.records.first!)
      case let .failure(requestError): return .failure(requestError.ckError)
      }
    }
  }
  
  struct RecordWithIDWasDeletedInZoneResult: Codable, Sendable {
    let recordIDArchive: CloudKitRecordIDArchive
    let recordType: CKRecord.RecordType
    
    public init(recordID: CKRecord.ID, recordType: CKRecord.RecordType) {
      self.recordIDArchive = CloudKitRecordIDArchive(recordIDs: [recordID])
      self.recordType = recordType
    }
  }
  
  internal struct OneZoneFetchResultSuccess: Codable, Sendable {
    let serverChangeTokenArchive: CloudKitServerChangeTokenArchive
    let clientChangeTokenData: Data?
    let moreComing: Bool
  }
  
  struct OneZoneFetchResult: Codable, Sendable {
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
      case let .success(tuple): self.codableResult = .success(
          .init(
            serverChangeTokenArchive: CloudKitServerChangeTokenArchive(token: tuple.serverChangeToken),
            clientChangeTokenData: tuple.clientChangeTokenData,
            moreComing: tuple.moreComing
          )
        )
      case let .failure(error):
        self.codableResult = .failure(CKRequestError(from: error))
      }
    }

    var result: Result<(serverChangeToken: CKServerChangeToken, clientChangeTokenData: Data?, moreComing: Bool), Error> {
      switch codableResult {
      case let .failure(error): return .failure(error.ckError)
      case let .success(success): return .success((serverChangeToken: success.serverChangeTokenArchive.token, clientChangeTokenData: success.clientChangeTokenData, moreComing: success.moreComing))
      }
    }
  }
  
  struct FetchZoneChangesResult: Codable, Sendable {
    let codableResult: CodableResult<CodableVoid, CKRequestError>
        
    public init(result: Result<Void, Error>) {
      switch result {
      case .success: self.codableResult = .success(CodableVoid())
      case let .failure(error): self.codableResult = .failure(CKRequestError(from: error))
      }
    }
    
    var result: Result<Void, Error> {
      switch codableResult {
      case .success: return .success(())
      case let .failure(error): return .failure(error.ckError)
      }
    }
  }
  
  struct FetchZoneChangesOperationResult: Codable, Sendable {
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
