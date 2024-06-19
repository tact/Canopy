import CanopyTypes
import CloudKit
import Foundation

/// Main Canopy implementation.
///
/// You construct Canopy with injected CloudKit container and databases, token store, and settings provider.
/// Canopy has reasonable defaults for all of these, and you need to only override the ones that need to use
/// a different value from the default.
@available(iOS 16.4, macOS 13.3, *)
public actor Canopy: CanopyType {
  private let containerProvider: @Sendable () -> CKContainerType
  private let publicCloudDatabaseProvider: @Sendable () -> CKDatabaseType
  private let privateCloudDatabaseProvider: @Sendable () -> CKDatabaseType
  private let sharedCloudDatabaseProvider: @Sendable () -> CKDatabaseType
  private let settingsProvider: @Sendable () -> CanopySettingsType
  private let tokenStoreProvider: @Sendable () -> TokenStoreType
  
  private var containerAPI: CKContainerAPI?
  private var databaseAPIs: [CKDatabase.Scope: CKDatabaseAPI] = [:]

  /// Initialize the live Canopy API.
  ///
  /// - Parameters:
  ///   - container: A real or mock `CKContainer`.
  ///   - publicCloudDatabase: a real or mock `CKDatabase` instance representing the public CloudKit database.
  ///   - privateCloudDatabase: a real or mock `CKDatabase` instance representing the private CloudKit database.
  ///   - privateCloudDatabase: a real or mock `CKDatabase` instance representing the shared CloudKit database.
  ///   - settings: a closure that returns Canopy settings.
  ///   Canopy requests settings from the closure every time that it runs a request whose behavior might be altered by the settings.
  ///   This is designed as a closure because the settings may change during application runtime.
  ///   - tokenStore: an object that stores and returns zone and database tokens for the requests that work with the tokens.
  ///   Canopy only interacts with the token store when using the ``CKDatabaseAPIType/fetchDatabaseChanges(qualityOfService:)`` and ``CKDatabaseAPIType/fetchZoneChanges(recordZoneIDs:fetchMethod:qualityOfService:)`` APIs. If you don’t use these APIs, you can ignore this parameter.
  public init(
    container: @escaping @autoclosure @Sendable () -> CKContainerType = CKContainer.default(),
    publicCloudDatabase: @escaping @autoclosure @Sendable () -> CKDatabaseType = CKContainer.default().publicCloudDatabase,
    privateCloudDatabase: @escaping @autoclosure @Sendable () -> CKDatabaseType = CKContainer.default().privateCloudDatabase,
    sharedCloudDatabase: @escaping @autoclosure @Sendable () -> CKDatabaseType = CKContainer.default().sharedCloudDatabase,
    settings: @escaping @Sendable () -> CanopySettingsType = { CanopySettings() },
    tokenStore: @escaping @autoclosure @Sendable () -> TokenStoreType = UserDefaultsTokenStore()
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
      databaseAPI = api(using: publicCloudDatabaseProvider(), scope: .public)
    case .private:
      databaseAPI = api(using: privateCloudDatabaseProvider(), scope: .private)
    case .shared:
      databaseAPI = api(using: sharedCloudDatabaseProvider(), scope: .shared)
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
      let newContainerAPI = CKContainerAPI(
        container: containerProvider(),
        accountChangedSequence: .live
      )
      containerAPI = newContainerAPI
      return newContainerAPI
    }
  }

  private func api(using database: CKDatabaseType, scope: CKDatabase.Scope) -> CKDatabaseAPI {
    CKDatabaseAPI(
      database: database,
      databaseScope: scope,
      settingsProvider: settingsProvider,
      tokenStore: tokenStoreProvider()
    )
  }
}
