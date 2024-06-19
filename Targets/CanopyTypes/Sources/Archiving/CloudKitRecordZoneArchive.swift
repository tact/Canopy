import CloudKit
import Foundation

public struct CloudKitRecordZoneArchive: Codable, Sendable {
  private let data: Data

  public var zones: [CKRecordZone] {
    do {
      let decodedRecords = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, CKRecordZone.self], from: data)
      return decodedRecords as? [CKRecordZone] ?? []
    } catch {
      return []
    }
  }

  public init(zones: [CKRecordZone]) {
    guard !zones.isEmpty else {
      self.data = Data()
      return
    }

    do {
      self.data = try NSKeyedArchiver.archivedData(withRootObject: zones, requiringSecureCoding: true)
    } catch {
      self.data = Data()
    }
  }
}
