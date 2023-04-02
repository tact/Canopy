import CloudKit

public extension CKContainerAPIType {
  func fetchShareParticipants(
    with lookupInfos: [CKUserIdentity.LookupInfo],
    qualityOfService: QualityOfService = .default
  ) async -> Result<[CKShare.Participant], CKRecordError> {
    await fetchShareParticipants(
      with: lookupInfos,
      qualityOfService: qualityOfService
    )
  }
  
  func acceptShares(
    with metadatas: [CKShare.Metadata],
    qualityOfService: QualityOfService = .default
  ) async -> Result<[CKShare], CKRecordError> {
    await acceptShares(
      with: metadatas,
      qualityOfService: qualityOfService
    )
  }
}
