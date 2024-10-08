import CloudKit
import Foundation

public struct CloudKitLookupInfoArchive: Codable, Sendable {
  private let data: Data

  public var lookupInfos: [CKUserIdentity.LookupInfo] {
    do {
      let decodedRecords = try NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: CKUserIdentity.LookupInfo.self, from: data)
      return decodedRecords ?? []
    } catch {
      return []
    }
  }

  public init(lookupInfos: [CKUserIdentity.LookupInfo]) {
    guard !lookupInfos.isEmpty else {
      self.data = Data()
      return
    }

    do {
      self.data = try NSKeyedArchiver.archivedData(withRootObject: lookupInfos, requiringSecureCoding: true)
    } catch {
      self.data = Data()
    }
  }
}

public extension CloudKitLookupInfoArchive {
  static func + (lhs: CloudKitLookupInfoArchive, rhs: CloudKitLookupInfoArchive) -> CloudKitLookupInfoArchive {
    CloudKitLookupInfoArchive(lookupInfos: lhs.lookupInfos + rhs.lookupInfos)
  }
}
