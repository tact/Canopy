import CloudKit

/// TokenStore provides a local storage interface to CloudKit database and record zone tokens.
///
/// When you fetch changes to a CloudKit database or record zone, you provide a previous “change token”
/// to indicate a point in time from which onwards you want to receive the changes. CloudKit then fetches
/// you the changes from the time point identified by the token until “now”, and provides you a new token
/// for “now”. You store the token and provide it to CloudKit in future requests.
///
/// If you do not provide a change token, CloudKit gives you the changes “from the beginning of time”,
/// which may be large and take a while in case of a bigger data set. If you use the “fetch changes” APIs,
/// it is a good idea to use these tokens.
///
/// TokenStore provides a storage interface to these tokens. Canopy provides a UserDefaults-based store
/// which is good enough for many applications, as well as a test store that does not persist anything.
///
/// TokenStore and Canopy currently assume that the application works with only one CKContainer.
/// There is currently no facility to distinguish between multiple CKContainers. This is a good enough assumption
/// for most CloudKit applications.
public protocol TokenStoreType: Sendable {
  /// Store a token for the given database scope.
  ///
  /// - Parameter token: token to be stored. May be nil if it needs to be removed from storage for whatever reason.
  /// If receiving a nil token, the store should remove the known token for this scope.
  func storeToken(_ token: CKServerChangeToken?, forDatabaseScope scope: CKDatabase.Scope) async

  /// Return the token for the requested scope, if there is one.
  func tokenForDatabaseScope(_ scope: CKDatabase.Scope) async -> CKServerChangeToken?
  
  /// Store a token for the given record zone ID.
  ///
  /// - Parameter token: token to be stored. May be nil if it needs to be removed from storage for whatever reason.
  /// If receiving a nil token, the store should remove the known token for this record zone ID.
  func storeToken(_ token: CKServerChangeToken?, forRecordZoneID zoneID: CKRecordZone.ID) async
  
  /// Return the token for the requested record zone ID, if there is one.
  func tokenForRecordZoneID(_ zoneID: CKRecordZone.ID) async -> CKServerChangeToken?
  
  /// Clear the content of the token store and go back to the initial state.
  ///
  /// Canopy never calls this, since it does not manage the client side state and does not know when is the right time to call it.
  /// You should call this yourself from your own app when you need to reset your client to a state where it doesn’t have any tokens stored
  /// and should start over from a fresh state.
  func clear() async
}
