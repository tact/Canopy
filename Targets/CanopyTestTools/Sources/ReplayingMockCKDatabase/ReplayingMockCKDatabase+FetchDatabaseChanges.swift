import CanopyTypes
import CloudKit

extension ReplayingMockCKDatabase {
  struct FetchDatabaseChangesSuccess: Codable {
    let serverChangeTokenArchive: CloudKitServerChangeTokenArchive
    let moreComing: Bool
  }
  
  public struct FetchDatabaseChangesResult: Codable, Sendable {
    let codableResult: CodableResult<FetchDatabaseChangesSuccess, CanopyError>
    
    public static let success = FetchDatabaseChangesResult(result: .success((serverChangeToken: CKServerChangeToken.mock, moreComing: false)))
    
    public init(
      result: Result<(serverChangeToken: CKServerChangeToken, moreComing: Bool), Error>
    ) {
      switch result {
      case let .success(tuple): self.codableResult = .success(.init(serverChangeTokenArchive: CloudKitServerChangeTokenArchive(token: tuple.serverChangeToken), moreComing: tuple.moreComing))
      case let .failure(error): self.codableResult = .failure(CanopyError(from: error))
      }
    }
    
    var result: Result<(serverChangeToken: CKServerChangeToken, moreComing: Bool), Error> {
      switch codableResult {
      case let .failure(error): return .failure(error.ckError)
      case let .success(success): return .success((serverChangeToken: success.serverChangeTokenArchive.token, moreComing: success.moreComing))
      }
    }
  }
  
  public struct FetchDatabaseChangesOperationResult: Codable, Sendable {
    /// A successful result that indicates no changes.
    ///
    /// Useful to use in tests and previews where you don’t need to inject any results, to save some typing.
    public static let blank = FetchDatabaseChangesOperationResult(
      changedRecordZoneIDs: [],
      deletedRecordZoneIDs: [],
      purgedRecordZoneIDs: [],
      fetchDatabaseChangesResult: .success
    )
    
    let changedRecordZoneIDsArchive: CloudKitRecordZoneIDArchive
    let deletedRecordZoneIDsArchive: CloudKitRecordZoneIDArchive
    let purgedRecordZoneIDsArchive: CloudKitRecordZoneIDArchive
    let fetchDatabaseChangesResult: FetchDatabaseChangesResult
    
    public init(
      changedRecordZoneIDs: [CKRecordZone.ID],
      deletedRecordZoneIDs: [CKRecordZone.ID],
      purgedRecordZoneIDs: [CKRecordZone.ID],
      fetchDatabaseChangesResult: FetchDatabaseChangesResult
    ) {
      self.changedRecordZoneIDsArchive = CloudKitRecordZoneIDArchive(zoneIDs: changedRecordZoneIDs)
      self.deletedRecordZoneIDsArchive = CloudKitRecordZoneIDArchive(zoneIDs: deletedRecordZoneIDs)
      self.purgedRecordZoneIDsArchive = CloudKitRecordZoneIDArchive(zoneIDs: purgedRecordZoneIDs)
      self.fetchDatabaseChangesResult = fetchDatabaseChangesResult
    }
  }
  
  internal func runFetchDatabaseChangesOperation(
    _ operation: CKFetchDatabaseChangesOperation,
    operationResult: FetchDatabaseChangesOperationResult,
    sleep: Float?
  ) async {
    if let sleep {
      try? await Task.sleep(nanoseconds: UInt64(sleep * Float(NSEC_PER_SEC)))
    }
    
    for changedRecordZoneID in operationResult.changedRecordZoneIDsArchive.zoneIDs {
      operation.recordZoneWithIDChangedBlock?(changedRecordZoneID)
    }
    
    for deletedRecordZoneID in operationResult.deletedRecordZoneIDsArchive.zoneIDs {
      operation.recordZoneWithIDWasDeletedBlock?(deletedRecordZoneID)
    }
    
    for purgedRecordZoneID in operationResult.purgedRecordZoneIDsArchive.zoneIDs {
      operation.recordZoneWithIDWasPurgedBlock?(purgedRecordZoneID)
    }
    
    operation.fetchDatabaseChangesResultBlock?(operationResult.fetchDatabaseChangesResult.result)
  }
}
