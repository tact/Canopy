import CloudKit

public extension CKContainerAPIType {
  /// Fetch `CKShare.Participant` based on user record name or other info.
  ///
  /// This is one step of implementing a custom record sharing interface. You obtain share participants and add them to a `CKShare`.
  ///
  /// For more info, see [CKFetchShareParticipantsOperation](https://developer.apple.com/documentation/cloudkit/ckfetchshareparticipantsoperation/).
  /// Canopy internally calls this operation to execute this function.
  ///
  /// - Parameters:
  ///   - lookupInfos: An array of user lookup infos to resolve into share participants.
  ///   - qualityOfService: The desired quality of service of the request. Defaults to `.default` if not provided.
  ///
  /// - Returns:
  ///     An array of `CKShare.Participant` values for the requested look up infos, or `CKRecordError` if there
  ///     was an error with the request.
  func fetchShareParticipants(
    with lookupInfos: [CKUserIdentity.LookupInfo],
    qualityOfService: QualityOfService = .default
  ) async -> Result<[CKShare.Participant], CKRecordError> {
    await fetchShareParticipants(
      with: lookupInfos,
      qos: qualityOfService
    )
  }
  
  /// Obtain access to a CKShare after the system has prompted the user to accept the share.
  ///
  /// After the user uses the OS-provided interface to accept joining a shared record in CloudKit, your app is called with the share metadata.
  /// You must then use this `acceptShares` call, to convert the metadata into a real share which you then have access to.
  ///
  /// For more info, see [CKAcceptSharesOperation.](https://developer.apple.com/documentation/cloudkit/ckacceptsharesoperation)
  /// Canopy internally calls this operation to execute this function.
  ///
  /// - Parameters:
  ///   - with: An array of `CKShare.Metadata` that you received e.g from the underlying system, which to convert into shares.
  ///   - qualityOfService: The desired quality of service of the request. Defaults to `.default` if not provided.
  ///
  /// - Returns:
  ///   An array of `CKShare` that corresponds to the array of given metadatas, or `CKRecordError` if there was an error with the request.
  ///
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
