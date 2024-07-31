import CloudKit

/// Successful result for a function call to fetch records.
public struct FetchRecordsResult: Sendable {
  /// Records that were found.
  public let foundRecords: [CanopyResultRecord]
  
  /// Records that were not found based on the ID, but the operation was otherwise successful.
  public let notFoundRecordIDs: [CKRecord.ID]
  
  public init(foundRecords: [CanopyResultRecord], notFoundRecordIDs: [CKRecord.ID]) {
    self.foundRecords = foundRecords
    self.notFoundRecordIDs = notFoundRecordIDs
  }
}
