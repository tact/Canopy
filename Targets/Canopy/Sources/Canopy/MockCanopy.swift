import CanopyTypes
import CloudKit

/// A static mock version of Canopy, appropriate for using in tests or other contexts
/// where you need to isolate the CloudKit dependency and provide a
/// deterministic view of CloudKit data with simulated mock data.
///
/// You initialize MockCanopy with instances of mock container and databases.
/// The Canopy API then receives API calls and plays back the responses to those
/// requests, without any interaction with real CloudKit.
///
/// You only need to inject the containers and databases that your tests actually use.
/// If you try to use a dependency that’s not been injected correctly, MockCanopy crashes
/// with an error message indicating that.
public struct MockCanopy: CanopyType {
  private let mockPrivateDatabase: CKDatabaseType?
  private let mockSharedDatabase: CKDatabaseType?
  private let mockPublicDatabase: CKDatabaseType?
  private let mockContainer: CKContainerType?
  private let settingsProvider: () async -> CanopySettingsType
  
  public init(
    mockPrivateDatabase: CKDatabaseType? = nil,
    mockSharedDatabase: CKDatabaseType? = nil,
    mockPublicDatabase: CKDatabaseType? = nil,
    mockContainer: CKContainerType? = nil,
    settingsProvider: @escaping () async -> CanopySettingsType = { CanopySettings() }
  ) {
    self.mockPublicDatabase = mockPublicDatabase
    self.mockSharedDatabase = mockSharedDatabase
    self.mockPrivateDatabase = mockPrivateDatabase
    self.mockContainer = mockContainer
    self.settingsProvider = settingsProvider
  }
  
  public func databaseAPI(usingDatabaseScope scope: CKDatabase.Scope) -> CKDatabaseAPIType {
    switch scope {
    case .public:
      guard let db = mockPublicDatabase else { fatalError("Requested public database which wasn’t correctly injected") }
      return CKDatabaseAPI(
        database: db,
        databaseScope: .public,
        settingsProvider: settingsProvider,
        tokenStore: TestTokenStore()
      )
    case .private:
      guard let db = mockPrivateDatabase else { fatalError("Requested private database which wasn’t correctly injected") }
      return CKDatabaseAPI(
        database: db,
        databaseScope: .private,
        settingsProvider: settingsProvider,
        tokenStore: TestTokenStore()
      )
    case .shared:
      guard let db = mockSharedDatabase else { fatalError("Requested shared database which wasn’t correctly injected") }
      return CKDatabaseAPI(
        database: db,
        databaseScope: .shared,
        settingsProvider: settingsProvider,
        tokenStore: TestTokenStore()
      )
    @unknown default:
      fatalError("Unknown CloudKit database scope")
    }
  }
  
  public func containerAPI() -> CKContainerAPIType {
    guard let container = mockContainer else { fatalError("Requested CKContainer which wasn’t correctly injected") }
    return CKContainerAPI(
      container: container,
      accountChangedSequence: .mock(elementsToProduce: 1)
    )
  }
}
