import CloudKit

public struct CanopyResultRecord {
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
  
  public var encryptedValuesView: any CanopyRecordValueGetting {
    switch kind {
    case .mock(let mock): mock.encryptedValuesView
    case .ckRecord(_, let reader): reader
    }
  }
}
