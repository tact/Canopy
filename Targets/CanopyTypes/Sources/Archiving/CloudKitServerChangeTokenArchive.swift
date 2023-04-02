import CloudKit
import Foundation

public struct CloudKitServerChangeTokenArchive: Codable {
  private let data: Data

  public var token: CKServerChangeToken {
    let decodedRecord = try! NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)!
    return decodedRecord
  }

  public init(token: CKServerChangeToken) {
    self.data = try! NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
  }
}
