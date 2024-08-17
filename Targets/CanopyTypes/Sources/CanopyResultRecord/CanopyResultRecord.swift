import CloudKit

public struct CanopyResultRecord: Sendable {
  enum Kind {
    case mock(MockCanopyResultRecord)
    case ckRecord(CKRecord, CKRecordEncryptedValuesReader)
  }
  
  struct CKRecordEncryptedValuesReader: CanopyRecordValueGetting {
    let record: CKRecord
    subscript(key: String) -> CKRecordValueProtocol? {
      record.encryptedValues[key]
    }
  }
  
  let kind: Kind
  
  public init(ckRecord: CKRecord) {
    kind = .ckRecord(ckRecord, .init(record: ckRecord))
  }
  
  public init(mock: MockCanopyResultRecord) {
    kind = .mock(mock)
  }
  
  /// Return this record as a CKShare, if it looks like a CKShare.
  ///
  /// CKShare is an important CKRecord subclass that handles sharing and permissions. CanopyResultRecord
  /// does currently not yet implement strong support for CKShares, but it lets you unpack and cast a real share
  /// like this.
  public var asCKShare: CKShare? {
    switch kind {
    case .ckRecord(let record, _): record as? CKShare
    case .mock: nil
    }
  }
}

extension CanopyResultRecord: Equatable {
  public static func == (lhs: CanopyResultRecord, rhs: CanopyResultRecord) -> Bool {
    // Note that CKRecord equality is by reference, not value
    // CKRecords are equal only if they are the same object reference
    // MockCanopyResultRecord equality, though, is by values
    switch (lhs.kind, rhs.kind) {
    case (.ckRecord(let lhsRecord, _), .ckRecord(let rhsRecord, _)): lhsRecord == rhsRecord
    case (.mock(let lhsMock), .mock(let rhsMock)): lhsMock == rhsMock
    default: false
    }
  }
}

extension CanopyResultRecord: Codable {
  enum CodingKeys: CodingKey {
    case type
    case backingValue
  }
  
  enum KindType: String {
    case mock
    case ckRecord
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let kindTypeString = try container.decode(String.self, forKey: .type)
    guard let type = KindType(rawValue: kindTypeString) else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: [CodingKeys.type],
          debugDescription: "Invalid backing value type: \(kindTypeString)"
        )
      )
    }
    switch type {
    case .mock:
      let mock = try container.decode(MockCanopyResultRecord.self, forKey: .backingValue)
      kind = .mock(mock)
    case .ckRecord:
      let ckRecordData = try container.decode(Data.self, forKey: .backingValue)
      guard let ckRecord = try? NSKeyedUnarchiver.unarchivedObject(
        ofClass: CKRecord.self,
        from: ckRecordData
      ) else {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: [CodingKeys.backingValue],
            debugDescription: "Invalid data for CKRecord"
          )
        )
      }
      kind = .ckRecord(ckRecord, CKRecordEncryptedValuesReader(record: ckRecord))
    }
  }
  
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch kind {
    case .mock(let mock):
      try container.encode(KindType.mock.rawValue, forKey: .type)
      try container.encode(mock, forKey: .backingValue)
    case .ckRecord(let ckRecord, _):
      try container.encode(KindType.ckRecord.rawValue, forKey: .type)
      let ckRecordData = try NSKeyedArchiver.archivedData(
        withRootObject: ckRecord,
        requiringSecureCoding: true
      )
      try container.encode(ckRecordData, forKey: .backingValue)
    }
  }
}

extension CanopyResultRecord: CanopyResultRecordType {
  public var recordID: CKRecord.ID {
    switch kind {
    case .mock(let mock): mock.recordID
    case .ckRecord(let ckRecord, _): ckRecord.recordID
    }
  }
  
  public var recordType: CKRecord.RecordType {
    switch kind {
    case .mock(let mock): mock.recordType
    case .ckRecord(let ckRecord, _): ckRecord.recordType
    }
  }
  
  public var creationDate: Date? {
    switch kind {
    case .mock(let mock): mock.creationDate
    case .ckRecord(let ckRecord, _): ckRecord.creationDate
    }
  }
  
  public var creatorUserRecordID: CKRecord.ID? {
    switch kind {
    case .mock(let mock): mock.creatorUserRecordID
    case .ckRecord(let ckRecord, _): ckRecord.creatorUserRecordID
    }
  }
  
  public var modificationDate: Date? {
    switch kind {
    case .mock(let mock): mock.modificationDate
    case .ckRecord(let ckRecord, _): ckRecord.modificationDate
    }
  }
  
  public var lastModifiedUserRecordID: CKRecord.ID? {
    switch kind {
    case .mock(let mock): mock.lastModifiedUserRecordID
    case .ckRecord(let ckRecord, _): ckRecord.lastModifiedUserRecordID
    }
  }
  
  public var recordChangeTag: String? {
    switch kind {
    case .mock(let mock): mock.recordChangeTag
    case .ckRecord(let ckRecord, _): ckRecord.recordChangeTag
    }
  }
  
  public var parent: CKRecord.Reference? {
    switch kind {
    case .mock(let mock): mock.parent
    case .ckRecord(let ckRecord, _): ckRecord.parent
    }
  }
  
  public var share: CKRecord.Reference? {
    switch kind {
    case .mock(let mock): mock.share
    case .ckRecord(let ckRecord, _): ckRecord.share
    }
  }
  
  public subscript(key: String) -> (any CKRecordValueProtocol)? {
    switch kind {
    case .mock(let mock): mock[key]
    case .ckRecord(let ckRecord, _): ckRecord[key]
    }
  }
  
  public var encryptedValues: any CanopyRecordValueGetting {
    switch kind {
    case .mock(let mock): mock.encryptedValues
    case .ckRecord(_, let reader): reader
    }
  }
}
