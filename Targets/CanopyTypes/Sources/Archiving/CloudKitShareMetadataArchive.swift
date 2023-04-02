import CloudKit
import Foundation

public struct CloudKitShareMetadataArchive: Codable {
  private let data: Data

  public var shareMetadatas: [CKShare.Metadata] {
    do {
      let decodedShareMetadatas = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)
      return decodedShareMetadatas as? [CKShare.Metadata] ?? []
    } catch {
      return []
    }
  }

  public init(shareMetadatas: [CKShare.Metadata]) {
    guard !shareMetadatas.isEmpty else {
      self.data = Data()
      return
    }

    do {
      self.data = try NSKeyedArchiver.archivedData(withRootObject: shareMetadatas, requiringSecureCoding: true)
    } catch {
      self.data = Data()
    }
  }
}

extension CloudKitShareMetadataArchive {
  static func + (lhs: CloudKitShareMetadataArchive, rhs: CloudKitShareMetadataArchive) -> CloudKitShareMetadataArchive {
    CloudKitShareMetadataArchive(shareMetadatas: lhs.shareMetadatas + rhs.shareMetadatas)
  }
}
