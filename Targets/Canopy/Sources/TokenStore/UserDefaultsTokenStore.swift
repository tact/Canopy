import CloudKit
import os.log

public struct UserDefaultsTokenStore: TokenStoreType {
  
  private let logger = Logger(subsystem: "Canopy", category: "UserDefaultsTokenStore")
  
  public init() {}
  
  public func storeToken(_ token: CKServerChangeToken?, forDatabaseScope scope: CKDatabase.Scope) {
    guard let token else {
      UserDefaults.standard.removeObject(forKey: defaultsKeyForDatabaseScope(scope))
      return
    }
    do {
      let tokenData = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: false)
      UserDefaults.standard.set(tokenData, forKey: defaultsKeyForDatabaseScope(scope))
    } catch {
      logger.error("Error encoding CloudKit database change token for storage: \(error)")
    }
  }
  
  public func tokenForDatabaseScope(_ scope: CKDatabase.Scope) -> CKServerChangeToken? {
    if let tokenData = UserDefaults.standard.data(forKey: defaultsKeyForDatabaseScope(scope)),
       let token = try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: tokenData)
    {
      return token
    }
    return nil
  }
  
  public func storeToken(_ token: CKServerChangeToken?, forRecordZoneID zoneID: CKRecordZone.ID) {
    guard let token else {
      UserDefaults.standard.removeObject(forKey: defaultsKeyForZoneID(zoneID))
      return
    }
    do {
      let tokenData = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: false)
      UserDefaults.standard.set(tokenData, forKey: defaultsKeyForZoneID(zoneID))
    } catch {
      logger.error("Error encoding CloudKit record zone change token for storage: \(error)")
    }
  }
  
  public func tokenForRecordZoneID(_ zoneID: CKRecordZone.ID) -> CKServerChangeToken? {
    if let tokenData = UserDefaults.standard.data(forKey: defaultsKeyForZoneID(zoneID)),
       let token = try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: tokenData)
    {
      return token
    }
    return nil
  }
  
  public func clear() async {
    let scopes: [CKDatabase.Scope] = [.private, .public, .shared]
    for scope in scopes {
      UserDefaults.standard.removeObject(forKey: defaultsKeyForDatabaseScope(scope))
    }
    
    for key in UserDefaults.standard.dictionaryRepresentation().keys {
      if key.hasPrefix("recordZoneServerChangeToken:") {
        UserDefaults.standard.removeObject(forKey: key)
      }
    }
  }
  
  private func defaultsKeyForDatabaseScope(_ scope: CKDatabase.Scope) -> String {
    switch scope {
    case .public: return "publicCKDatabaseServerChangeToken"
    case .private: return "privateCKDatabaseServerChangeToken"
    case .shared: return "sharedCKDatabaseServerChangeToken"
    @unknown default: fatalError("Unknown CKDatabase scope")
    }
  }
  
  private func defaultsKeyForZoneID(_ zoneID: CKRecordZone.ID) -> String {
    "recordZoneServerChangeToken:\(zoneID.ckDatabaseScope.asString):\(zoneID.ownerName):\(zoneID.zoneName)"
  }
}
