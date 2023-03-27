import CloudKit

public struct ModifyRecordsResult: Equatable {
  public let savedRecords: [CKRecord]
  public let deletedRecordIDs: [CKRecord.ID]
  
  public init(savedRecords: [CKRecord], deletedRecordIDs: [CKRecord.ID]) {
    self.savedRecords = savedRecords
    self.deletedRecordIDs = deletedRecordIDs
  }
}
