import CloudKit

/// Successful result for a function call to fetch records.
public struct FetchRecordsResult: Equatable, Sendable {
  /// Records that were found.
  public let foundRecords: [CanopyResultRecord]
  
  /// Records that were not found based on the ID, but the operation was otherwise successful.
  public let notFoundRecordIDs: [CKRecord.ID]
  
  public init(foundRecords: [CanopyResultRecord], notFoundRecordIDs: [CKRecord.ID]) {
    self.foundRecords = foundRecords
    self.notFoundRecordIDs = notFoundRecordIDs
  }
}

extension FetchRecordsResult: Codable {
  enum CodingKeys: CodingKey {
    case foundRecords
    case notFoundRecordIDs
  }
  
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    foundRecords = try container.decode([CanopyResultRecord].self, forKey: .foundRecords)
    let notFoundRecordIDsData = try container.decode(Data.self, forKey: .notFoundRecordIDs)
    if let notFoundRecordIDs = try? NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: CKRecord.ID.self, from: notFoundRecordIDsData) {
      self.notFoundRecordIDs = notFoundRecordIDs
    } else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: [CodingKeys.notFoundRecordIDs],
          debugDescription: "Invalid not found record IDs value in source data"
        )
      )
    }
  }
  
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(foundRecords, forKey: .foundRecords)
    let notFoundRecordIDsData = try NSKeyedArchiver.archivedData(withRootObject: notFoundRecordIDs, requiringSecureCoding: true)
    try container.encode(notFoundRecordIDsData, forKey: .notFoundRecordIDs)
  }
}
