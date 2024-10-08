import CloudKit
import Foundation

/// The main Canopy entry point, providing you access to the container and database APIs
/// for performing real or simulated CloudKit requests.
///
/// This is the most appropriate type to use throughout your application to refer to Canopy. You inject the real or mock objects
/// conforming to this protocol into your features. Inside the features, you obtain the container or database interfaces
/// with the API provided in this protocol, and use those obtained APIs to perform actual CloudKit requests.
///
/// It’s best if you keep a reference to this top-level `Canopy` object in your app, and don’t keep a reference to the
/// database and container APIs that it vends. Instead, just request the database and container API every time when
/// you need to run API requests.
///
/// For testability, you should build your features in a way where they interact with Canopy CloudKit APIs, without needing
/// to know whether they are talking to a real or mock backend.
public protocol CanopyType: Sendable {
  
  /// Get the API provider to run requests against a CloudKit container.
  func containerAPI() async -> CKContainerAPIType

  /// Get the API provider to run requests against a CloudKit database.
  func databaseAPI(usingDatabaseScope scope: CKDatabase.Scope) async -> CKDatabaseAPIType
}
