import CloudKit

/// Successful result of record modification and deletion functions, containing details about saved and deleted records.
public struct ModifyRecordsResult: Equatable, Sendable {
  /// An array of saved records. The records likely have different metadata from the records that you gave to the modification function
  /// as input, because CloudKit updates the record modification timestamp and change tag on the server side when saving records.
  public let savedRecords: [CanopyResultRecord]
  
  /// Array of deleted record ID-s. This matches the array record ID-s that you gave to the function as input.
  public let deletedRecordIDs: [CKRecord.ID]
  
  public init(savedRecords: [CanopyResultRecord], deletedRecordIDs: [CKRecord.ID]) {
    self.savedRecords = savedRecords
    self.deletedRecordIDs = deletedRecordIDs
  }
}

extension ModifyRecordsResult: Codable {
  enum CodingKeys: CodingKey {
    case savedRecords
    case deletedRecordIDs
  }
  
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    savedRecords = try container.decode([CanopyResultRecord].self, forKey: .savedRecords)
    let deletedRecordIDsData = try container.decode(Data.self, forKey: .deletedRecordIDs)
    if let deletedRecordIDs = try? NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: CKRecord.ID.self, from: deletedRecordIDsData) {
      self.deletedRecordIDs = deletedRecordIDs
    } else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: [CodingKeys.deletedRecordIDs],
          debugDescription: "Invalid deleted record IDs value in source data"
        )
      )
    }
  }
  
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(savedRecords, forKey: .savedRecords)
    let deletedRecordIDsData = try NSKeyedArchiver.archivedData(withRootObject: deletedRecordIDs, requiringSecureCoding: true)
    try container.encode(deletedRecordIDsData, forKey: .deletedRecordIDs)
  }
}
