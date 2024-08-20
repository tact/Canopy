import CloudKit
import Foundation

public struct ModifyZonesResult: Equatable, Sendable {
  public let savedZones: [CKRecordZone]
  public let deletedZoneIDs: [CKRecordZone.ID]
  
  public init(savedZones: [CKRecordZone], deletedZoneIDs: [CKRecordZone.ID]) {
    self.savedZones = savedZones
    self.deletedZoneIDs = deletedZoneIDs
  }
}

extension ModifyZonesResult: Codable {
  enum CodingKeys: CodingKey {
    case savedZones
    case deletedZoneIDs
  }
  
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    let savedZonesData = try container.decode(Data.self, forKey: .savedZones)
    if let savedZones = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [CKRecordZone.self, NSArray.self], from: savedZonesData) as? [CKRecordZone] {
      self.savedZones = savedZones
    } else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: [CodingKeys.savedZones],
          debugDescription: "Invalid saved zones value in source data"
        )
      )
    }

    let deletedZoneIDsData = try container.decode(Data.self, forKey: .deletedZoneIDs)
    if let deletedZoneIDs = try? NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: CKRecordZone.ID.self, from: deletedZoneIDsData) {
      self.deletedZoneIDs = deletedZoneIDs
    } else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: [CodingKeys.deletedZoneIDs],
          debugDescription: "Invalid deleted record zone IDs value in source data"
        )
      )
    }
  }
  
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    let savedZonesData = try NSKeyedArchiver.archivedData(withRootObject: savedZones, requiringSecureCoding: true)
    try container.encode(savedZonesData, forKey: .savedZones)
    let deletedZoneIDsData = try NSKeyedArchiver.archivedData(withRootObject: deletedZoneIDs, requiringSecureCoding: true)
    try container.encode(deletedZoneIDsData, forKey: .deletedZoneIDs)
  }
}
