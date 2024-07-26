import CloudKit

struct MockValueStore: CanopyRecordValueGetting, Sendable {
  let values: [String: CanopyRecordValueProtocol]
  
  init(values: [String : CanopyRecordValueProtocol]) {
    self.values = values
  }
  
  subscript(_ key: String) -> (any CanopyRecordValueProtocol)? {
    values[key]
  }
}

struct MockCanopyResultRecord: CanopyResultRecordType, Sendable {
  let encryptedValuesStore: MockValueStore
  let valuesStore: MockValueStore
  
  let recordID: CKRecord.ID
  let recordType: CKRecord.RecordType
  let creationDate: Date?
  let creatorUserRecordID: CKRecord.ID?
  let modificationDate: Date?
  let lastModifiedUserRecordID: CKRecord.ID?
  let recordChangeTag: String?
  let parent: CKRecord.Reference?
  let share: CKRecord.Reference?
  
  init(
    recordID: CKRecord.ID = .init(recordName: "mockRecordName"),
    recordType: CKRecord.RecordType,
    creationDate: Date? = nil,
    creatorUserRecordID: CKRecord.ID? = nil,
    modificationDate: Date? = nil,
    lastModifiedUserRecordID: CKRecord.ID? = nil,
    recordChangeTag: String? = nil,
    parent: CKRecord.Reference? = nil,
    share: CKRecord.Reference? = nil,
    values: [String: CanopyRecordValueProtocol] = [:],
    encryptedValues: [String: CanopyRecordValueProtocol] = [:]
  ) {
    self.recordID = recordID
    self.recordType = recordType
    self.creationDate = creationDate
    self.creatorUserRecordID = creatorUserRecordID
    self.modificationDate = modificationDate
    self.lastModifiedUserRecordID = lastModifiedUserRecordID
    self.recordChangeTag = recordChangeTag
    self.parent = parent
    self.share = share
    valuesStore = MockValueStore(values: values)
    encryptedValuesStore = MockValueStore(values: encryptedValues)
  }
  
  subscript(_ key: String) -> (any CanopyRecordValueProtocol)? {
    valuesStore[key]
  }
  
  var encryptedValuesView: CanopyRecordValueGetting {
    encryptedValuesStore
  }
}
