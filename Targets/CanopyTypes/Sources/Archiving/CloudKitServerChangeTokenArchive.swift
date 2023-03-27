import CloudKit
import Foundation

public struct CloudKitServerChangeTokenArchive: Codable {
  private let data: Data

  public var token: CKServerChangeToken {
    let decodedRecord = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)
    return decodedRecord as! CKServerChangeToken
  }

  public init(token: CKServerChangeToken) {
    data = try! NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
  }
}
