/// Behavior for Canopy CloudKit requests, controlled by the caller.
///
/// You can affect the behavior of Canopy requests from both caller and server side.
/// On the server side, you can initialize Canopy with mock replaying databases and
/// containers for controlled test results.
///
/// On the caller side, you can inform Canopy to simulate failures of the requests,
/// regardless of whether it works against a real or simulated backends. The use for this
/// is to let you test failed requests in a real client environment. You could have a
/// “developer switch” somewhere in your app to simulate errors, to see how your app
/// responds to errors in a real build.
public enum RequestBehavior: Equatable, Sendable {
  /// Regular behavior. Attempt to run the request against the backend. If the optional
  /// associated value is present, the request is delayed for the given number of seconds,
  /// somewhat simulating slow network conditions and letting you see how your UI
  /// behaves if the request takes time.
  case regular(Double?)
  
  /// Return a simulated failure without touching the backend. If the optional associated
  /// value is present, the request is delayed for the given number of seconds, before
  /// returning a failure.
  case simulatedFail(Double?)
  
  /// Same as simulated fail, but also simulate partial errors for the requests where it is applicable.
  case simulatedFailWithPartialErrors(Double?)
}

/// Canopy settings that modify the behavior from the caller (request) side.
///
/// By default, Canopy uses reasonable defaults for all these settings. If you would like
/// to modify Canopy behavior, you can construct Canopy with a `CanopySettings` struct
/// which has some of the values modified, or pass any custom value that implements this protocol.
public protocol CanopySettingsType: Sendable {
  /// Behavior for “modify records” request.
  ///
  /// Applies to both saving and deleting records.
  var modifyRecordsBehavior: RequestBehavior { get async }
  
  /// Behavior for “fetch database changes” request.
  var fetchDatabaseChangesBehavior: RequestBehavior { get async }
  
  /// Behavior for “fetch zone changes” request.
  var fetchZoneChangesBehavior: RequestBehavior { get async }
  
  /// Resend a modification request if the initial batch is too large.
  ///
  /// If a modification operation is too large, CloudKit responds with a
  /// `limitExceeded` error. The caller should then re-send its request
  /// into smaller batches.
  ///
  /// Canopy does this by default. If you wish, you can turn this off.
  /// You will then get `limitExceeded` error returned.
  var autoBatchTooLargeModifyOperations: Bool { get async }
  
  /// Retry failed operations that are retriable.
  ///
  /// Some CloudKit operations can fail, but CloudKit indicates that you can retry them.
  /// For example, modification operations can fail because there is no network,
  /// or a zone is busy (multiple writes to a record zone are happening on the cloud side).
  ///
  /// CloudKit indicates such situations with an error code, and also indicates
  /// a delay after which it advises to try again.
  ///
  /// If this is true (the default value), Canopy tries a retriable operation up to
  /// 3 times before giving up and returning an error.
  ///
  /// Currently this is implemented in Canopy only for modifying records.
  /// All other requests fail immediately without retrying if there is an error.
  var autoRetryForRetriableErrors: Bool { get async }
}
