import CanopyTypes
import CloudKit

public enum CKContainerAPIError: Error {
  /// There can only be one listener to the account status stream.
  case onlyOneAccountStatusStreamSupported
}

/// Canopy overlay to the CKContainer API.
public protocol CKContainerAPIType {
  /// Obtain the user record ID for the current CloudKit user.
  var userRecordID: Result<CKRecord.ID?, CKRecordError> { get async }
  
  /// Obtain CloudKit account status for the current user.
  var accountStatus: Result<CKAccountStatus, CanopyError> { get async }
  
  /// Obtain a stream of CloudKit account statuses of the current user.
  ///
  /// To obtain this info with vanilla CloudKit API, you must listen to `CKAccountChanged` notifications,
  /// and whenever you get one, use the `accountStatus` API of the CKContainer to find out what the
  /// actual status is.
  ///
  /// Canopy does all this internally, and provides you a stream of the statuses.
  var accountStatusStream: Result<AsyncStream<CKAccountStatus>, CKContainerAPIError> { get async }
  
  /// Fetch CKShare.Participant based on user record name or other info.
  ///
  /// After fetching a participant (or several participants), you can add them to CKShare.
  /// This is the primary method how a shared record owner adds other members to the resource.
  func fetchShareParticipants(
    with lookupInfos: [CKUserIdentity.LookupInfo],
    qos: QualityOfService
  ) async -> Result<[CKShare.Participant], CKRecordError>
  
  func acceptShares(
    with metadatas: [CKShare.Metadata],
    qos: QualityOfService
  ) async -> Result<[CKShare], CKRecordError>
}
