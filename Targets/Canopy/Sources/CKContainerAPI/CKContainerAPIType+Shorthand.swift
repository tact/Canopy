import CloudKit

public extension CKContainerAPIType {
  /// Shorthand fetchShareParticipants.
  func fetchShareParticipants(
    with lookupInfos: [CKUserIdentity.LookupInfo],
    qualityOfService: QualityOfService = .default
  ) async -> Result<[CKShare.Participant], CKRecordError> {
    await fetchShareParticipants(
      with: lookupInfos,
      qos: qualityOfService
    )
  }
  
  /// Shorthand acceptShares.
  func acceptShares(
    with metadatas: [CKShare.Metadata],
    qualityOfService: QualityOfService = .default
  ) async -> Result<[CKShare], CKRecordError> {
    await acceptShares(
      with: metadatas,
      qos: qualityOfService
    )
  }
}
