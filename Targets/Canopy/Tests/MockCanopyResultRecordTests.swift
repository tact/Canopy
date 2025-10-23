@testable import Canopy
import CloudKit
import Foundation
import Testing

@Suite struct MockCanopyResultRecordTests {
  let date = Date()
  @Test func test_codes_complete_record() throws {
    let record = MockCanopyResultRecord(
      recordID: CKRecord.ID(recordName: "someName"),
      recordType: "SomeRecordType",
      creationDate: date,
      creatorUserRecordID: .init(recordName: "creator"),
      modificationDate: date,
      lastModifiedUserRecordID: .init(recordName: "last modifier"),
      recordChangeTag: "changeTag",
      parent: .init(recordID: .init(recordName: "parentRecordName"), action: .none),
      share: .init(recordID: .init(recordName: "shareRecordName"), action: .none),
      values: [
        "key1": "String 1"
      ],
      encryptedValues: [
        "encrypted1": "Encrypted String 1"
      ]
    )
    let data = try JSONEncoder().encode(record)
    let decodedRecord = try JSONDecoder().decode(MockCanopyResultRecord.self, from: data)
    #expect(decodedRecord.recordID.recordName == "someName")
    #expect(decodedRecord.recordType == "SomeRecordType")
    #expect(decodedRecord["key1"] as! String == "String 1")
    #expect(decodedRecord.encryptedValues["encrypted1"] as! String == "Encrypted String 1")
    #expect(decodedRecord.creationDate == date)
    #expect(decodedRecord.modificationDate == date)
    #expect(decodedRecord.recordChangeTag == "changeTag")
    #expect(decodedRecord.creatorUserRecordID?.recordName == "creator")
    #expect(decodedRecord.lastModifiedUserRecordID!.recordName == "last modifier")
    #expect(decodedRecord.parent?.recordID.recordName == "parentRecordName")
    #expect(decodedRecord.share?.recordID.recordName == "shareRecordName")
  }
  
  @Test func test_codes_minimal_record() throws {
    let record = MockCanopyResultRecord(recordType: "MinimalType")
    let data = try JSONEncoder().encode(record)
    let decodedRecord = try JSONDecoder().decode(MockCanopyResultRecord.self, from: data)
    #expect(decodedRecord.recordType == "MinimalType")
  }
  
  @Test func test_invalid_record_id_throws() {
    let brokenJson = "{\"recordType\":\"MinimalType\",\"valuesStore\":[],\"recordID\":\"deadbeef\",\"encryptedValuesStore\":[]}"
    
    do {
      let data = brokenJson.data(using: .utf8)!
      let _ = try JSONDecoder().decode(MockCanopyResultRecord.self, from: data)
    } catch {
      let decodingError = error as! DecodingError
      switch (decodingError) {
      case .dataCorrupted(let context):
        #expect(context.debugDescription == "Invalid record ID")
      default:
        Issue.record("Unexpected error: \(error)")
      }
    }
  }
  
  @Test func test_invalid_creator_user_record_id_throws() {
    let brokenJson = "{\"recordType\":\"MinimalType\",\"valuesStore\":[],\"recordID\":\"YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGoCwwTFB4fICZVJG51bGzTDQ4PEBESViRjbGFzc1pSZWNvcmROYW1lVlpvbmVJRIAHgAKAA15tb2NrUmVjb3JkTmFtZdUVFhcYDRkaGxwdXxAQZGF0YWJhc2VTY29wZUtleV8QEWFub255bW91c0NLVXNlcklEWW93bmVyTmFtZVhab25lTmFtZRAAgACABYAEgAZcX2RlZmF1bHRab25lXxAQX19kZWZhdWx0T3duZXJfX9IhIiMkWiRjbGFzc25hbWVYJGNsYXNzZXNeQ0tSZWNvcmRab25lSUSiIyVYTlNPYmplY3TSISInKFpDS1JlY29yZElEoiclAAgAEQAaACQAKQAyADcASQBMAFEAUwBcAGIAaQBwAHsAggCEAIYAiACXAKIAtQDJANMA3ADeAOAA4gDkAOYA8wEGAQsBFgEfAS4BMQE6AT8BSgAAAAAAAAIBAAAAAAAAACkAAAAAAAAAAAAAAAAAAAFN\",\"encryptedValuesStore\":[],\"creatorUserRecordID\":\"deadbeef\"}"
    
    do {
      let data = brokenJson.data(using: .utf8)!
      let _ = try JSONDecoder().decode(MockCanopyResultRecord.self, from: data)
    } catch {
      let decodingError = error as! DecodingError
      switch (decodingError) {
      case .dataCorrupted(let context):
        #expect(context.debugDescription == "Invalid creator user record ID")
      default:
        Issue.record("Unexpected error: \(error)")
      }
    }
  }
  
  @Test func test_invalid_last_modified_user_record_id_throws() {
    let brokenJson = "{\"recordType\":\"MinimalType\",\"valuesStore\":[],\"recordID\":\"YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGoCwwTFB4fICZVJG51bGzTDQ4PEBESViRjbGFzc1pSZWNvcmROYW1lVlpvbmVJRIAHgAKAA15tb2NrUmVjb3JkTmFtZdUVFhcYDRkaGxwdXxAQZGF0YWJhc2VTY29wZUtleV8QEWFub255bW91c0NLVXNlcklEWW93bmVyTmFtZVhab25lTmFtZRAAgACABYAEgAZcX2RlZmF1bHRab25lXxAQX19kZWZhdWx0T3duZXJfX9IhIiMkWiRjbGFzc25hbWVYJGNsYXNzZXNeQ0tSZWNvcmRab25lSUSiIyVYTlNPYmplY3TSISInKFpDS1JlY29yZElEoiclAAgAEQAaACQAKQAyADcASQBMAFEAUwBcAGIAaQBwAHsAggCEAIYAiACXAKIAtQDJANMA3ADeAOAA4gDkAOYA8wEGAQsBFgEfAS4BMQE6AT8BSgAAAAAAAAIBAAAAAAAAACkAAAAAAAAAAAAAAAAAAAFN\",\"encryptedValuesStore\":[],\"lastModifiedUserRecordID\":\"deadbeef\"}"
    
    do {
      let data = brokenJson.data(using: .utf8)!
      let _ = try JSONDecoder().decode(MockCanopyResultRecord.self, from: data)
    } catch {
      let decodingError = error as! DecodingError
      switch (decodingError) {
      case .dataCorrupted(let context):
        #expect(context.debugDescription == "Invalid last modified user record ID")
      default:
        Issue.record("Unexpected error: \(error)")
      }
    }
  }
  
  @Test func test_invalid_parent_throws() {
    let brokenJson = "{\"recordType\":\"MinimalType\",\"valuesStore\":[],\"recordID\":\"YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGoCwwTFB4fICZVJG51bGzTDQ4PEBESViRjbGFzc1pSZWNvcmROYW1lVlpvbmVJRIAHgAKAA15tb2NrUmVjb3JkTmFtZdUVFhcYDRkaGxwdXxAQZGF0YWJhc2VTY29wZUtleV8QEWFub255bW91c0NLVXNlcklEWW93bmVyTmFtZVhab25lTmFtZRAAgACABYAEgAZcX2RlZmF1bHRab25lXxAQX19kZWZhdWx0T3duZXJfX9IhIiMkWiRjbGFzc25hbWVYJGNsYXNzZXNeQ0tSZWNvcmRab25lSUSiIyVYTlNPYmplY3TSISInKFpDS1JlY29yZElEoiclAAgAEQAaACQAKQAyADcASQBMAFEAUwBcAGIAaQBwAHsAggCEAIYAiACXAKIAtQDJANMA3ADeAOAA4gDkAOYA8wEGAQsBFgEfAS4BMQE6AT8BSgAAAAAAAAIBAAAAAAAAACkAAAAAAAAAAAAAAAAAAAFN\",\"encryptedValuesStore\":[],\"parent\":\"deadbeef\"}"
    
    do {
      let data = brokenJson.data(using: .utf8)!
      let _ = try JSONDecoder().decode(MockCanopyResultRecord.self, from: data)
    } catch {
      let decodingError = error as! DecodingError
      switch (decodingError) {
      case .dataCorrupted(let context):
        #expect(context.debugDescription == "Invalid parent")
      default:
        Issue.record("Unexpected error: \(error)")
      }
    }
  }
  
  @Test func test_invalid_share_throws() {
    let brokenJson = "{\"recordType\":\"MinimalType\",\"valuesStore\":[],\"recordID\":\"YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGoCwwTFB4fICZVJG51bGzTDQ4PEBESViRjbGFzc1pSZWNvcmROYW1lVlpvbmVJRIAHgAKAA15tb2NrUmVjb3JkTmFtZdUVFhcYDRkaGxwdXxAQZGF0YWJhc2VTY29wZUtleV8QEWFub255bW91c0NLVXNlcklEWW93bmVyTmFtZVhab25lTmFtZRAAgACABYAEgAZcX2RlZmF1bHRab25lXxAQX19kZWZhdWx0T3duZXJfX9IhIiMkWiRjbGFzc25hbWVYJGNsYXNzZXNeQ0tSZWNvcmRab25lSUSiIyVYTlNPYmplY3TSISInKFpDS1JlY29yZElEoiclAAgAEQAaACQAKQAyADcASQBMAFEAUwBcAGIAaQBwAHsAggCEAIYAiACXAKIAtQDJANMA3ADeAOAA4gDkAOYA8wEGAQsBFgEfAS4BMQE6AT8BSgAAAAAAAAIBAAAAAAAAACkAAAAAAAAAAAAAAAAAAAFN\",\"encryptedValuesStore\":[],\"share\":\"deadbeef\"}"
    
    do {
      let data = brokenJson.data(using: .utf8)!
      let _ = try JSONDecoder().decode(MockCanopyResultRecord.self, from: data)
    } catch {
      let decodingError = error as! DecodingError
      switch (decodingError) {
      case .dataCorrupted(let context):
        #expect(context.debugDescription == "Invalid share")
      default:
        Issue.record("Unexpected error: \(error)")
      }
    }
  }
  
  @Test func test_compact_map_values() throws {
    let mock = MockCanopyResultRecord(
      recordType: "MockRecord",
      values: [
        "key1": "value1",
        "nullKey": nil
      ],
      encryptedValues: [
        "encryptedKey1": "encryptedValue1",
        "nullEncryptedKey": nil
      ]
    )
      
    #expect(mock["key1"] as! String == "value1")
    #expect(mock["nullKey"] == nil)
    
    #expect(mock.encryptedValues["encryptedKey1"] as! String == "encryptedValue1")
    #expect(mock["nullEncryptedKey"] == nil)
  }
  
  @Test func test_equatable() {
    let creationDate = Date().advanced(by: -10)
    let modificationDate = Date()
    
    let record1 = MockCanopyResultRecord(
      recordID: .init(recordName: "myRecord"),
      recordType: "MockRecord",
      creationDate: creationDate,
      creatorUserRecordID: .init(recordName: "creatorId"),
      modificationDate: modificationDate,
      lastModifiedUserRecordID: .init(recordName: "modifierId"),
      recordChangeTag: "changeTag",
      parent: .init(recordID: .init(recordName: "parentId"), action: .none),
      share: .init(recordID: .init(recordName: "shareId"), action: .none)
    )
    
    let record2 = MockCanopyResultRecord(
      recordID: .init(recordName: "myRecord"),
      recordType: "MockRecord",
      creationDate: creationDate,
      creatorUserRecordID: .init(recordName: "creatorId"),
      modificationDate: modificationDate,
      lastModifiedUserRecordID: .init(recordName: "modifierId"),
      recordChangeTag: "changeTag",
      parent: .init(recordID: .init(recordName: "parentId"), action: .none),
      share: .init(recordID: .init(recordName: "shareId"), action: .none)
    )
    
    let record3 = MockCanopyResultRecord(
      recordID: .init(recordName: "anotherId"),
      recordType: "MockRecord",
      creationDate: creationDate,
      creatorUserRecordID: .init(recordName: "creatorId"),
      modificationDate: modificationDate,
      lastModifiedUserRecordID: .init(recordName: "modifierId"),
      recordChangeTag: "changeTag",
      parent: .init(recordID: .init(recordName: "parentId"), action: .none),
      share: .init(recordID: .init(recordName: "shareId"), action: .none)
    )
    
    #expect(record1 == record2)
    #expect(record1 != record3)
  }
  
  @Test func test_from_ckrecord() {
    let ckRecord = CKRecord(recordType: "MyType", recordID: .init(recordName: "myRecordName"))
    ckRecord["key1"] = "value1"
    ckRecord.encryptedValues["encryptedKey1"] = "encryptedValue1"
    let mock = MockCanopyResultRecord.from(ckRecord: ckRecord)
    #expect(mock.recordID.recordName == "myRecordName")
    #expect(mock["key1"] as! String == "value1")
    #expect(mock.encryptedValues["encryptedKey1"] as! String == "encryptedValue1")
  }
}
