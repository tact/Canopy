import CloudKit

/// Successful result of record modification and deletion functions, containing details about saved and deleted records.
public struct ModifyRecordsResult: Equatable {
  /// An array of saved records. The records likely have different metadata from the records that you gave to the modification function
  /// as input, because CloudKit updates the record modification timestamp and change tag on the server side when saving records.
  public let savedRecords: [CKRecord]
  
  /// Array of deleted record ID-s. This matches the array record ID-s that you gave to the function as input.
  public let deletedRecordIDs: [CKRecord.ID]
  
  public init(savedRecords: [CKRecord], deletedRecordIDs: [CKRecord.ID]) {
    self.savedRecords = savedRecords
    self.deletedRecordIDs = deletedRecordIDs
  }
}
