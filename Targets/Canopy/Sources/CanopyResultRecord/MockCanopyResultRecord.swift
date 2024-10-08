import CloudKit

public struct MockCanopyResultRecord: CanopyResultRecordType, Sendable {
  let encryptedValuesStore: MockValueStore
  let valuesStore: MockValueStore
  
  public let recordID: CKRecord.ID
  public let recordType: CKRecord.RecordType
  public let creationDate: Date?
  public let creatorUserRecordID: CKRecord.ID?
  public let modificationDate: Date?
  public let lastModifiedUserRecordID: CKRecord.ID?
  public let recordChangeTag: String?
  public let parent: CKRecord.Reference?
  public let share: CKRecord.Reference?
  
  public init(
    recordID: CKRecord.ID = .init(recordName: "mockRecordName"),
    recordType: CKRecord.RecordType,
    creationDate: Date? = nil,
    creatorUserRecordID: CKRecord.ID? = nil,
    modificationDate: Date? = nil,
    lastModifiedUserRecordID: CKRecord.ID? = nil,
    recordChangeTag: String? = nil,
    parent: CKRecord.Reference? = nil,
    share: CKRecord.Reference? = nil,
    values: [String: CKRecordValueProtocol?] = [:],
    encryptedValues: [String: CKRecordValueProtocol?] = [:]
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
    valuesStore = MockValueStore(values: values.compactMapValues { $0 })
    encryptedValuesStore = MockValueStore(values: encryptedValues.compactMapValues { $0 })
  }
  
  public static func from(ckRecord: CKRecord) -> MockCanopyResultRecord {
    var values: [String: CKRecordValueProtocol] = [:]
    var encryptedValues: [String: CKRecordValueProtocol] = [:]
    for valueKey in ckRecord.allKeys() {
      if let value = ckRecord[valueKey] as? CKRecordValueProtocol {
        values[valueKey] = value
      }
    }
    for encryptedValueKey in ckRecord.encryptedValues.allKeys() {
      if let value = ckRecord.encryptedValues[encryptedValueKey] as? CKRecordValueProtocol {
        encryptedValues[encryptedValueKey] = value
      }
    }
    
    return MockCanopyResultRecord(
      recordID: ckRecord.recordID,
      recordType: ckRecord.recordType,
      creationDate: ckRecord.creationDate,
      creatorUserRecordID: ckRecord.creatorUserRecordID,
      modificationDate: ckRecord.modificationDate,
      lastModifiedUserRecordID: ckRecord.lastModifiedUserRecordID,
      recordChangeTag: ckRecord.recordChangeTag,
      parent: ckRecord.parent,
      share: ckRecord.share,
      values: values,
      encryptedValues: encryptedValues
    )
  }
  
  public subscript(_ key: String) -> (any CKRecordValueProtocol)? {
    valuesStore[key]
  }
  
  public var encryptedValues: CanopyRecordValueGetting {
    encryptedValuesStore
  }
}

extension MockCanopyResultRecord: Equatable {
  public static func == (lhs: MockCanopyResultRecord, rhs: MockCanopyResultRecord) -> Bool {
    lhs.recordID == rhs.recordID &&
    lhs.recordType == rhs.recordType &&
    lhs.creationDate == rhs.creationDate &&
    lhs.creatorUserRecordID == rhs.creatorUserRecordID &&
    lhs.modificationDate == rhs.modificationDate &&
    lhs.lastModifiedUserRecordID == rhs.lastModifiedUserRecordID &&
    lhs.recordChangeTag == rhs.recordChangeTag &&
    lhs.parent == rhs.parent &&
    lhs.share == rhs.share
    // Note: not comparing values stores here.
    // So two mocks with different value stores but everything else matching above
    // will be considered equal.
  }
}

extension MockCanopyResultRecord: Codable {
  enum CodingKeys: String, CodingKey {
    case recordID
    case recordType
    case valuesStore
    case encryptedValuesStore
    case creationDate
    case modificationDate
    case recordChangeTag
    case creatorUserRecordID
    case lastModifiedUserRecordID
    case parent
    case share
  }
  
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    recordType = try container.decode(CKRecord.RecordType.self, forKey: .recordType)
    
    let recordIDData = try container.decode(Data.self, forKey: .recordID)
    if let unarchivedRecordID = try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKRecord.ID.self, from: recordIDData) {
      recordID = unarchivedRecordID
    } else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: [CodingKeys.recordID],
          debugDescription: "Invalid record ID"
        )
      )
    }
    
    valuesStore = try container.decode(MockValueStore.self, forKey: .valuesStore)
    encryptedValuesStore = try container.decode(MockValueStore.self, forKey: .encryptedValuesStore)
    creationDate = try container.decodeIfPresent(Date.self, forKey: .creationDate)
    modificationDate = try container.decodeIfPresent(Date.self, forKey: .modificationDate)
    recordChangeTag = try container.decodeIfPresent(String.self, forKey: .recordChangeTag)

    if let creatorUserRecordIDData = try container.decodeIfPresent(
      Data.self,
      forKey: .creatorUserRecordID
    ) {
      if let unarchivedCreatorUserRecordID = try? NSKeyedUnarchiver.unarchivedObject(
        ofClass: CKRecord.ID.self,
        from: creatorUserRecordIDData
      ) {
        creatorUserRecordID = unarchivedCreatorUserRecordID
      } else {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: [CodingKeys.creatorUserRecordID],
            debugDescription: "Invalid creator user record ID"
          )
        )
      }
    } else {
      creatorUserRecordID = nil
    }
    
    if let lastModifiedRecordIDData = try container.decodeIfPresent(
      Data.self,
      forKey: .lastModifiedUserRecordID
    ) {
      if let unarchivedLastModifiedUserRecordID = try? NSKeyedUnarchiver.unarchivedObject(
        ofClass: CKRecord.ID.self,
        from: lastModifiedRecordIDData
      ) {
        lastModifiedUserRecordID = unarchivedLastModifiedUserRecordID
      } else {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: [CodingKeys.lastModifiedUserRecordID],
            debugDescription: "Invalid last modified user record ID"
          )
        )
      }
    } else {
      lastModifiedUserRecordID = nil
    }
    
    if let parentData = try container.decodeIfPresent(
      Data.self,
      forKey: .parent
    ) {
      if let unarchivedParent = try? NSKeyedUnarchiver.unarchivedObject(
        ofClass: CKRecord.Reference.self,
        from: parentData
      ) {
        parent = unarchivedParent
      } else {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: [CodingKeys.parent],
            debugDescription: "Invalid parent"
          )
        )
      }
    } else {
      parent = nil
    }

    if let shareData = try container.decodeIfPresent(
      Data.self,
      forKey: .share
    ) {
      if let unarchivedShare = try? NSKeyedUnarchiver.unarchivedObject(
        ofClass: CKRecord.Reference.self,
        from: shareData
      ) {
        share = unarchivedShare
      } else {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: [CodingKeys.share],
            debugDescription: "Invalid share"
          )
        )
      }
    } else {
      share = nil
    }
  }
  
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    
    let recordIDData = try NSKeyedArchiver.archivedData(
      withRootObject: recordID,
      requiringSecureCoding: true
    )
    try container.encode(recordIDData, forKey: .recordID)
    
    if let creatorUserRecordID {
      let creatorUserRecordIDData = try NSKeyedArchiver.archivedData(
        withRootObject: creatorUserRecordID,
        requiringSecureCoding: true
      )
      try container.encode(creatorUserRecordIDData, forKey: .creatorUserRecordID)
    }
    
    if let lastModifiedUserRecordID {
      let lastModifiedUserRecordIDData = try NSKeyedArchiver.archivedData(
        withRootObject: lastModifiedUserRecordID,
        requiringSecureCoding: true
      )
      try container.encode(lastModifiedUserRecordIDData, forKey: .lastModifiedUserRecordID)
    }
    
    if let parent {
      let parentData = try NSKeyedArchiver.archivedData(
        withRootObject: parent,
        requiringSecureCoding: true
      )
      try container.encode(parentData, forKey: .parent)
    }
    
    if let share {
      let shareData = try NSKeyedArchiver.archivedData(
        withRootObject: share,
        requiringSecureCoding: true
      )
      try container.encode(shareData, forKey: .share)
    }
    
    try container.encode(recordType, forKey: .recordType)
    try container.encode(valuesStore, forKey: .valuesStore)
    try container.encode(encryptedValuesStore, forKey: .encryptedValuesStore)
    try container.encodeIfPresent(creationDate, forKey: .creationDate)
    try container.encodeIfPresent(modificationDate, forKey: .modificationDate)
    try container.encodeIfPresent(recordChangeTag, forKey: .recordChangeTag)
  }
}
