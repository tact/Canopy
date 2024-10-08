import CloudKit

/// A static mock version of Canopy, appropriate for using in tests or other contexts
/// where you need to isolate the CloudKit dependency and provide a
/// deterministic view of CloudKit data with simulated mock data.
///
/// You initialize MockCanopy with instances of mock CKContainer and CKDatabases.
/// The Canopy API then receives API calls and plays back the responses to those
/// requests, without any interaction with real CloudKit.
///
/// You only need to inject the containers and databases that your tests actually use.
/// If you try to use a dependency that’s not been injected correctly, MockCanopy crashes
/// with an error message indicating that.
///
/// MockCanopyWithCKMocks is mostly appropriate to use as a testing tool for Canopy’s
/// own logic, or when you need to inject your own Canopy settings for various behaviors.
/// For using in your own tests, `MockCanopy` is more appropriate and simpler to use.
@available(iOS 16.4, macOS 13.3, *)
public struct MockCanopyWithCKMocks: CanopyType {
  private let mockPrivateCKDatabase: CKDatabaseType?
  private let mockSharedCKDatabase: CKDatabaseType?
  private let mockPublicCKDatabase: CKDatabaseType?
  private let mockCKContainer: CKContainerType?
  private let settingsProvider: @Sendable () async -> CanopySettingsType
  
  public init(
    mockPrivateCKDatabase: CKDatabaseType? = nil,
    mockSharedCKDatabase: CKDatabaseType? = nil,
    mockPublicCKDatabase: CKDatabaseType? = nil,
    mockCKContainer: CKContainerType? = nil,
    settingsProvider: @escaping @Sendable () async -> CanopySettingsType = { CanopySettings() }
  ) {
    self.mockPublicCKDatabase = mockPublicCKDatabase
    self.mockSharedCKDatabase = mockSharedCKDatabase
    self.mockPrivateCKDatabase = mockPrivateCKDatabase
    self.mockCKContainer = mockCKContainer
    self.settingsProvider = settingsProvider
  }
  
  public func databaseAPI(usingDatabaseScope scope: CKDatabase.Scope) -> CKDatabaseAPIType {
    switch scope {
    case .public:
      guard let db = mockPublicCKDatabase else { fatalError("Requested public database which wasn’t correctly injected") }
      return CKDatabaseAPI(
        database: db,
        databaseScope: .public,
        settingsProvider: settingsProvider,
        tokenStore: TestTokenStore()
      )
    case .private:
      guard let db = mockPrivateCKDatabase else { fatalError("Requested private database which wasn’t correctly injected") }
      return CKDatabaseAPI(
        database: db,
        databaseScope: .private,
        settingsProvider: settingsProvider,
        tokenStore: TestTokenStore()
      )
    case .shared:
      guard let db = mockSharedCKDatabase else { fatalError("Requested shared database which wasn’t correctly injected") }
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
    guard let container = mockCKContainer else { fatalError("Requested CKContainer which wasn’t correctly injected") }
    return CKContainerAPI(
      container: container,
      accountChangedSequence: .mock(elementsToProduce: 1)
    )
  }
}
