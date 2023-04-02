import CanopyTypes
import CloudKit
import Foundation

/// Main Canopy implementation.
///
/// You construct it with injected CloudKit container and databases, token store, and settings provider closure.
/// Canopy has reasonable defaults for all of these, and you need to only override the ones that need to use
/// a different value from the default.
public actor Canopy: CanopyType {
  private let containerProvider: () -> CKContainerType
  private let publicCloudDatabaseProvider: () -> CKDatabaseType
  private let privateCloudDatabaseProvider: () -> CKDatabaseType
  private let sharedCloudDatabaseProvider: () -> CKDatabaseType
  private let settingsProvider: () -> CanopySettingsType
  private let tokenStoreProvider: () -> TokenStoreType
  
  private var containerAPI: CKContainerAPI?
  private var databaseAPIs: [CKDatabase.Scope: CKDatabaseAPI] = [:]

  public init(
    container: @escaping @autoclosure () -> CKContainerType = CKContainer.default(),
    publicCloudDatabase: @escaping @autoclosure () -> CKDatabaseType = CKContainer.default().publicCloudDatabase,
    privateCloudDatabase: @escaping @autoclosure () -> CKDatabaseType = CKContainer.default().privateCloudDatabase,
    sharedCloudDatabase: @escaping @autoclosure () -> CKDatabaseType = CKContainer.default().sharedCloudDatabase,
    settings: @escaping () -> CanopySettingsType = { CanopySettings() },
    tokenStore: @escaping @autoclosure () -> TokenStoreType = UserDefaultsTokenStore()
  ) {
    self.containerProvider = container
    self.publicCloudDatabaseProvider = publicCloudDatabase
    self.privateCloudDatabaseProvider = privateCloudDatabase
    self.sharedCloudDatabaseProvider = sharedCloudDatabase
    self.settingsProvider = settings
    self.tokenStoreProvider = tokenStore
  }

  public func databaseAPI(usingDatabaseScope scope: CKDatabase.Scope) async -> CKDatabaseAPIType {
    if let existingAPI = databaseAPIs[scope] {
      return existingAPI
    }
    let databaseAPI: CKDatabaseAPI
    switch scope {
    case .public:
      databaseAPI = api(using: publicCloudDatabaseProvider())
    case .private:
      databaseAPI = api(using: privateCloudDatabaseProvider())
    case .shared:
      databaseAPI = api(using: sharedCloudDatabaseProvider())
    @unknown default:
      fatalError("Unknown CKDatabase scope: \(scope)")
    }
    databaseAPIs[scope] = databaseAPI
    return databaseAPI
  }
  
  public func containerAPI() async -> CKContainerAPIType {
    if let containerAPI {
      return containerAPI
    } else {
      let newContainerAPI = CKContainerAPI(containerProvider(), accountChangedSequence: .live)
      containerAPI = newContainerAPI
      return newContainerAPI
    }
  }

  private func api(using database: CKDatabaseType) -> CKDatabaseAPI {
    CKDatabaseAPI(database, settingsProvider: settingsProvider, tokenStore: tokenStoreProvider())
  }
}
