import CanopyTypes
import CloudKit

public struct NewMockCanopy: CanopyType {
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
