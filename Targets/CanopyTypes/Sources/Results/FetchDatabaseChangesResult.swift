import CloudKit
import Foundation

public struct FetchDatabaseChangesResult: Equatable, Sendable {
  public let changedRecordZoneIDs: [CKRecordZone.ID]
  public let deletedRecordZoneIDs: [CKRecordZone.ID]
  public let purgedRecordZoneIDs: [CKRecordZone.ID]

  public static var empty: FetchDatabaseChangesResult {
    FetchDatabaseChangesResult(
      changedRecordZoneIDs: [],
      deletedRecordZoneIDs: [],
      purgedRecordZoneIDs: []
    )
  }
  
  public init(
    changedRecordZoneIDs: [CKRecordZone.ID],
    deletedRecordZoneIDs: [CKRecordZone.ID],
    purgedRecordZoneIDs: [CKRecordZone.ID]
  ) {
    self.changedRecordZoneIDs = changedRecordZoneIDs
    self.deletedRecordZoneIDs = deletedRecordZoneIDs
    self.purgedRecordZoneIDs = purgedRecordZoneIDs
  }
}

extension FetchDatabaseChangesResult: Codable {
  enum CodingKeys: CodingKey {
    case changedRecordZoneIDs
    case deletedRecordZoneIDs
    case purgedRecordZoneIDs
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    let changedRecordZoneIDsData = try container.decode(Data.self, forKey: .changedRecordZoneIDs)
    if let changedRecordZoneIDs = try? NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: CKRecordZone.ID.self, from: changedRecordZoneIDsData) {
      self.changedRecordZoneIDs = changedRecordZoneIDs
    } else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: [CodingKeys.changedRecordZoneIDs],
          debugDescription: "Invalid changed record zone IDs value in source data"
        )
      )
    }
    
    let deletedRecordZoneIDsData = try container.decode(Data.self, forKey: .deletedRecordZoneIDs)
    if let deletedRecordZoneIDs = try? NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: CKRecordZone.ID.self, from: deletedRecordZoneIDsData) {
      self.deletedRecordZoneIDs = deletedRecordZoneIDs
    } else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: [CodingKeys.deletedRecordZoneIDs],
          debugDescription: "Invalid deleted record zone IDs value in source data"
        )
      )
    }
    
    let purgedRecordZoneIDsData = try container.decode(Data.self, forKey: .purgedRecordZoneIDs)
    if let purgedRecordZoneIDs = try? NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: CKRecordZone.ID.self, from: purgedRecordZoneIDsData) {
      self.purgedRecordZoneIDs = purgedRecordZoneIDs
    } else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: [CodingKeys.purgedRecordZoneIDs],
          debugDescription: "Invalid purged record zone IDs value in source data"
        )
      )
    }
  }
  
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    let changedRecordZoneIDsData = try NSKeyedArchiver.archivedData(withRootObject: changedRecordZoneIDs, requiringSecureCoding: true)
    try container.encode(changedRecordZoneIDsData, forKey: .changedRecordZoneIDs)
    let deletedRecordZoneIDsData = try NSKeyedArchiver.archivedData(withRootObject: deletedRecordZoneIDs, requiringSecureCoding: true)
    try container.encode(deletedRecordZoneIDsData, forKey: .deletedRecordZoneIDs)
    let purgedRecordZoneIDsData = try NSKeyedArchiver.archivedData(withRootObject: purgedRecordZoneIDs, requiringSecureCoding: true)
    try container.encode(purgedRecordZoneIDsData, forKey: .purgedRecordZoneIDs)
  }
}
