import CloudKit
import Foundation

public struct CloudKitLookupInfoArchive: Codable {
  private let data: Data

  public var lookupInfos: [CKUserIdentity.LookupInfo] {
    do {
      let decodedRecords = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)
      return decodedRecords as? [CKUserIdentity.LookupInfo] ?? []
    } catch {
      return []
    }
  }

  public init(lookupInfos: [CKUserIdentity.LookupInfo]) {
    guard !lookupInfos.isEmpty else {
      data = Data()
      return
    }

    do {
      data = try NSKeyedArchiver.archivedData(withRootObject: lookupInfos, requiringSecureCoding: true)
    } catch {
      data = Data()
    }
  }
}

extension CloudKitLookupInfoArchive {
  public static func + (lhs: CloudKitLookupInfoArchive, rhs: CloudKitLookupInfoArchive) -> CloudKitLookupInfoArchive {
    CloudKitLookupInfoArchive(lookupInfos: lhs.lookupInfos + rhs.lookupInfos)
  }
}
