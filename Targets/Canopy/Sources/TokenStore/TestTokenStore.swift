import CloudKit

public class TestTokenStore: TokenStoreType {
  public init() {}
  
  /// How many times "storeToken:forDatabaseScope:" has been called.
  private(set) var storeTokenForDatabaseScopeCalls = 0
  
  /// How many times "tokenForDatabaseScope" has been called.
  private(set) var getTokenForDatabaseScopeCalls = 0
  
  private(set) var storeTokenForRecordZoneCalls = 0
  private(set) var getTokenForRecordZoneCalls = 0
  
  public func storeToken(_ token: CKServerChangeToken?, forDatabaseScope scope: CKDatabase.Scope) {
    storeTokenForDatabaseScopeCalls += 1
  }
  
  public func tokenForDatabaseScope(_ scope: CKDatabase.Scope) -> CKServerChangeToken? {
    getTokenForDatabaseScopeCalls += 1
    return nil
  }
  
  public func storeToken(_ token: CKServerChangeToken?, forRecordZoneID zoneID: CKRecordZone.ID) {
    storeTokenForRecordZoneCalls += 1
  }
  
  public func tokenForRecordZoneID(_ zoneID: CKRecordZone.ID) -> CKServerChangeToken? {
    getTokenForRecordZoneCalls += 1
    return nil
  }
  
  public func clear() async {}
}
