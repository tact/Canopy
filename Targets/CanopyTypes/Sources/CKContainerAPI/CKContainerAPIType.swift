import CloudKit

public enum CKContainerAPIError: Int, Error, Codable, Sendable {
  /// There can only be one listener to the account status stream.
  case onlyOneAccountStatusStreamSupported
}

/// Canopy API provider for CKContainer.
///
/// [CKContainer](https://developer.apple.com/documentation/cloudkit/ckcontainer)
/// is the main unit of abstaction for your app’s data in CloudKit. It has methods to get information about the
/// current CloudKit user and other users.
///
/// Some methods of this protocol have a preferred shorthand way of calling them via a protocol extension,
/// which lets you skip specifying some parameters and provides reasonable default values for them.
///
/// To access your app’s actual data in CloudKit, see ``CKDatabaseAPIType``.
public protocol CKContainerAPIType: Sendable {
  /// Obtain the user record ID for the current CloudKit user.
  ///
  /// You don’t need to do this for regular CloudKit use. Your app doesn’t need to know anything about the current user,
  /// including their record ID, to use CloudKit.
  ///
  /// Knowing the current user record ID may be useful in scenarios related to record sharing and other communication
  /// between your app’s CloudKit users.
  ///
  /// You can also store the record ID and compare it with future sessions of your app. The record ID may change if
  /// the current user logs out in the device’s iCloud Settings, and another user logs in.
  ///
  /// The reported user ID is unique for the current user, your app, and CloudKit environment. CloudKit reports the same user record ID
  /// for a given iCloud user across all of their devices.
  var userRecordID: Result<CKRecord.ID?, CKRecordError> { get async }
  
  /// Obtain CloudKit account status for the current user.
  var accountStatus: Result<CKAccountStatus, CanopyError> { get async }
  
  /// Obtain a stream of CloudKit account statuses of the current user.
  ///
  /// To obtain this info with vanilla CloudKit API, you must listen to [CKAccountChanged](https://developer.apple.com/documentation/foundation/nsnotification/name/1399172-ckaccountchanged)
  /// notifications. Whenever you get one, you need to use the [accountStatus](https://developer.apple.com/documentation/cloudkit/ckcontainer/1399180-accountstatus)
  /// API of the CKContainer to find out what the actual status is.
  ///
  /// Canopy does all of this work internally, and provides you a simple stream of the account statuses.
  var accountStatusStream: Result<AsyncStream<CKAccountStatus>, CKContainerAPIError> { get async }
  
  /// See ``CKContainerAPIType/fetchShareParticipants(with:qualityOfService:)`` for preferred way of calling this API.
  func fetchShareParticipants(
    with lookupInfos: [CKUserIdentity.LookupInfo],
    qos: QualityOfService
  ) async -> Result<[CKShare.Participant], CKRecordError>

  /// See ``CKContainerAPIType/acceptShares(with:qualityOfService:)`` for preferred way of calling this API.
  func acceptShares(
    with metadatas: [CKShare.Metadata],
    qos: QualityOfService
  ) async -> Result<[CKShare], CKRecordError>
}
