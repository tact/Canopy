import CloudKit

/// Read-only representation of one CloudKit record.
///
/// May be constructed with either a CKRecord (coming from CloudKit or created locally),
/// or ``MockCanopyResultRecord``.
///
/// Read the fields and metadata of the record with the getters defined in the ``CanopyResultRecordType`` protocol.
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
  
  /// Return a Boolean value if the record property value for a given key can be represented as a bool,
  /// otherwise return nil.
  ///
  /// CloudKit does not have a boolean data type. Booleans can be stored as integers in CloudKit. When you
  /// store a bool value using a CKRecord, it gets stored as Int64 on the CloudKit side. Ohter integer data types
  /// may be similarly used as bools, with the common convention that 0 maps to false and any other integer value
  /// maps to true.
  ///
  /// This function lets you retrieve the bool value if you are treating a given record property value as a bool in your own
  /// data model, regardless of which exact Integer type was used on the CloudKit side.
  ///
  /// If the record property value does not exist, or is backed by some other type that is neither a Boolean or Integer
  /// and can’t be cast to a Boolean value, this function returns nil.
  ///
  /// You commonly should not see native Boolean values returned from CloudKit, but it is fine to use them as part of
  /// MockCanopyResultRecord values. So if you use a boolean in your mock record, while it is backed by an integer type
  /// on the CloudKit side in real use, this function will behave predictably and consistently for both cases.
  public func boolForKey(_ key: String) -> Bool? {
    let boolCandidate = self[key]
    if let boolValue = boolCandidate as? Bool {
      return boolValue
    } else if let binaryIntegerValue = boolCandidate as? any BinaryInteger {
      return binaryIntegerValue.boolValue
    } else {
      return nil
    }
  }
}

extension BinaryInteger {
  var boolValue: Bool {
    // https://forums.swift.org/t/how-would-you-test-an-arbitrary-value-for-boolness/75045
    self == Self.zero ? false : true
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
