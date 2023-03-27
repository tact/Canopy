import CloudKit
import Foundation

// Re-export the types, so `import Canopy` also imports the types.
@_exported import CanopyTypes

/// The main Canopy entry point, providing you access to the container and database API-s
/// for performing real or simulated CloudKit requests.
///
/// This is the most appropriate type to use throughout your application to refer to Canopy. You inject the real or mock objects
/// conforming to this protocol into your features. Inside the features, you obtain the container or database interfaces
/// with the API provided in this protocol, and use those obtained API-s to perform actual CloudKit requests.
///
/// For testability, your features should built in a way where they interact with Canopy CloudKit API-s, without needing
/// to know whether they are talking to a real or mock backend.
public protocol CanopyType {
  func containerAPI() async -> CKContainerAPIType
  func databaseAPI(usingDatabaseScope scope: CKDatabase.Scope) async -> CKDatabaseAPIType
}
