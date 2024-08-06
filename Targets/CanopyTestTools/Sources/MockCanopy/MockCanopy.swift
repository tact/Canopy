import CanopyTypes
import CloudKit

/// MockCanopy lets you use Canopy with deterministic responses without any external
/// dependencies like CloudKit on the cloud.
///
/// You initialize MockCanopy with static container and databases, perhaps instances
/// of `ReplayingMockContainer` and `ReplayingMockDatabase`, and
/// then plays back their static content in response to Canopy API calls.
public struct MockCanopy: CanopyType {
  private let container: CKContainerAPIType
  private let privateDatabase: CKDatabaseAPIType
  private let publicDatabase: CKDatabaseAPIType
  private let sharedDatabase: CKDatabaseAPIType
  
  public func containerAPI() async -> CKContainerAPIType {
    container
  }
  
  public func databaseAPI(usingDatabaseScope scope: CKDatabase.Scope) async -> CKDatabaseAPIType {
    switch scope {
    case .public: publicDatabase
    case .private: privateDatabase
    case .shared: sharedDatabase
    @unknown default: fatalError("Requested unknown database type: \(scope)")
    }
  }
}
