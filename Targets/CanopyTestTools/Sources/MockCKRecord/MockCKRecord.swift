import CloudKit
import Foundation

public protocol CKRecordMocking {
  var recordID: CKRecord.ID { get }
}

/// Mock version of CKRecord, suitable for using in tests.
///
/// This behaves similarly to CKRecord, but lets you override some fields
/// that are set by CloudKit on the server side: most importantly,
/// creator user record name, creation and modification times, and change tag.
/// This is useful for testing where you need to test with the content of these fields
/// present, but are constructing the records locally as test fixtures
/// instead of obtaining them from the server.
public class MockCKRecord: CKRecord, CKRecordMocking {
  public static let testingCreatorUserRecordNameKey = "testingCreatorUserRecordNameKey"
  public static let testingCreatedAtKey = "testingCreatedAtKey"
  public static let testingModifiedAtKey = "testingModifiedAtKey"
  public static let testingRecordChangeTag = "testingRecordChangeTag"
  
  override public var creatorUserRecordID: CKRecord.ID? {
    guard let testing = self[MockCKRecord.testingCreatorUserRecordNameKey] as? String else {
      return nil
    }

    return CKRecord.ID(recordName: testing)
  }
  
  override public var creationDate: Date? {
    guard let testing = self[MockCKRecord.testingCreatedAtKey] as? Date else {
      return nil
    }
    return testing
  }
  
  override public var modificationDate: Date? {
    guard let testing = self[MockCKRecord.testingModifiedAtKey] as? Date else {
      return nil
    }
    return testing
  }
  
  override public var recordChangeTag: String? {
    guard let testing = self[MockCKRecord.testingRecordChangeTag] as? String else {
      return nil
    }
    return testing
  }

  override public class var supportsSecureCoding: Bool {
    true
  }

  public static func mock(
    recordType: String,
    recordID: CKRecord.ID,
    parentRecordID: CKRecord.ID? = nil,
    creatorUserRecordName: String = UUID().uuidString,
    recordChangeTag: String? = nil,
    properties: [String: CKRecordValueProtocol?]
  ) -> MockCKRecord {
    let record = MockCKRecord(recordType: recordType, recordID: recordID)

    if let parentID = parentRecordID {
      record.parent = CKRecord.Reference(recordID: parentID, action: .none)
    }

    record[testingCreatorUserRecordNameKey] = creatorUserRecordName
    record[testingRecordChangeTag] = recordChangeTag
    
    for (key, value) in properties {
      record[key] = value
    }

    return record
  }

  public static func mock(record: CKRecord) -> MockCKRecord {
    let mock = MockCKRecord(recordType: record.recordType, recordID: record.recordID)

    if let parentID = record.parent?.recordID {
      mock.parent = CKRecord.Reference(recordID: parentID, action: .none)
    }

    mock[testingCreatorUserRecordNameKey] = record.creatorUserRecordID?.recordName
    mock[testingRecordChangeTag] = record.recordChangeTag
    
    for key in mock.allKeys() {
      mock[key] = record[key]
    }

    return mock
  }
}
