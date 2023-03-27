import CloudKit
import Foundation

public struct CloudKitRecordZoneArchive: Codable {
  private let data: Data

  public var zones: [CKRecordZone] {
    do {
      let decodedRecords = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)
      return decodedRecords as? [CKRecordZone] ?? []
    } catch {
      return []
    }
  }

  public init(zones: [CKRecordZone]) {
    guard !zones.isEmpty else {
      data = Data()
      return
    }

    do {
      data = try NSKeyedArchiver.archivedData(withRootObject: zones, requiringSecureCoding: true)
    } catch {
      data = Data()
    }
  }
}
