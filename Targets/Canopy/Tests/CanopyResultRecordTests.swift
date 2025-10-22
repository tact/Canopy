@testable import Canopy
import CanopyTestTools
import CloudKit
import Testing

@Suite final class CanopyResultRecordTests {
  @Test func test_init_with_ckrecord() {
    let ckRecord = CKRecord(recordType: "SomeRecordType", recordID: .init(recordName: "someRecordName"))
    ckRecord["textValue"] = "someTextValue"
    ckRecord.encryptedValues["encryptedTextValue"] = "someEncryptedTextValue"
    let canopyResultRecord = CanopyResultRecord(ckRecord: ckRecord)
    
    #expect(canopyResultRecord.recordType == "SomeRecordType")
    #expect(canopyResultRecord.recordID.recordName == "someRecordName")
    #expect(canopyResultRecord["textValue"] as? String == "someTextValue")
    #expect(canopyResultRecord.encryptedValues["encryptedTextValue"] as? String == "someEncryptedTextValue")
    #expect(canopyResultRecord.recordChangeTag == nil)
    #expect(canopyResultRecord.creationDate == nil)
    #expect(canopyResultRecord.modificationDate == nil)
    #expect(canopyResultRecord.creatorUserRecordID == nil)
    #expect(canopyResultRecord.lastModifiedUserRecordID == nil)
    #expect(canopyResultRecord.parent == nil)
    #expect(canopyResultRecord.share == nil)
  }
  
  @Test func test_init_with_mock() {
    let creationDate = Date()
    let modificationDate = Date()
    let parent = CKRecord.Reference(recordID: .init(recordName: "parentRecordID"), action: .none)
    let share = CKRecord.Reference(recordID: .init(recordName: "shareRecordID"), action: .none)
    let mockRecord = MockCanopyResultRecord(
      recordID: .init(recordName: "mockRecordName"),
      recordType: "MockRecord",
      creationDate: creationDate,
      creatorUserRecordID: .init(recordName: "creatorRecordID"),
      modificationDate: modificationDate,
      lastModifiedUserRecordID: .init(recordName: "modifierRecordID"),
      recordChangeTag: "changeTag",
      parent: parent,
      share: share,
      values: ["textValue": "someTextValue"],
      encryptedValues: ["encryptedTextValue": "someEncryptedTextValue"]
    )
    let canopyResultRecord = CanopyResultRecord(mock: mockRecord)
    #expect(canopyResultRecord.recordID.recordName == "mockRecordName")
    #expect(canopyResultRecord.recordType == "MockRecord")
    #expect(canopyResultRecord.creatorUserRecordID!.recordName == "creatorRecordID")
    #expect(canopyResultRecord.lastModifiedUserRecordID!.recordName == "modifierRecordID")
    #expect(canopyResultRecord.creationDate == creationDate)
    #expect(canopyResultRecord.modificationDate == modificationDate)
    #expect(canopyResultRecord["textValue"] as? String == "someTextValue")
    #expect(canopyResultRecord.encryptedValues["encryptedTextValue"] as? String == "someEncryptedTextValue")
    #expect(canopyResultRecord.recordChangeTag == "changeTag")
    #expect(canopyResultRecord.parent!.recordID.recordName == "parentRecordID")
    #expect(canopyResultRecord.share!.recordID.recordName == "shareRecordID")
  }
  
  @Test func test_codes_ckrecord() throws {
    let ckRecord = CKRecord(recordType: "SomeRecordType", recordID: .init(recordName: "someRecordName"))
    ckRecord["textValue"] = "someTextValue"
    ckRecord.encryptedValues["encryptedTextValue"] = "someEncryptedTextValue"
    let canopyResultRecord = CanopyResultRecord(ckRecord: ckRecord)
    let coded = try JSONEncoder().encode(canopyResultRecord)
    let decodedRecord = try JSONDecoder().decode(CanopyResultRecord.self, from: coded)
    #expect(decodedRecord.recordType == "SomeRecordType")
    #expect(decodedRecord.recordID.recordName == "someRecordName")
  }
  
  @Test func test_codes_mock() throws {
    let mock = MockCanopyResultRecord(recordType: "MockRecordType")
    let canopyResultRecord = CanopyResultRecord(mock: mock)
    let coded = try JSONEncoder().encode(canopyResultRecord)
    let decodedRecord = try JSONDecoder().decode(CanopyResultRecord.self, from: coded)
    #expect(decodedRecord.recordType == "MockRecordType")
  }
  
  @Test func test_throws_on_invalid_type() {
    let badJson = "{\"backingValue\":{\"recordType\":\"MockRecordType\",\"encryptedValuesStore\":[],\"valuesStore\":[],\"recordID\":\"deadbeef\"},\"type\":\"badType\"}"
    let data = badJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(CanopyResultRecord.self, from: data)
    } catch {
      let dataCorruptedError = error as! DecodingError
      switch dataCorruptedError {
      case .dataCorrupted(let context):
        #expect(context.debugDescription == "Invalid backing value type: badType")
      default:
        Issue.record("Unexpected error: \(dataCorruptedError)")
      }
    }
  }
  
  @Test func test_throws_on_bad_ckrecord_data() {
    let badJson = "{\"type\":\"ckRecord\",\"backingValue\":\"deadbeef\"}"
    let data = badJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(CanopyResultRecord.self, from: data)
    } catch {
      let dataCorruptedError = error as! DecodingError
      switch dataCorruptedError {
      case .dataCorrupted(let context):
        #expect(context.debugDescription == "Invalid data for CKRecord")
      default:
        Issue.record("Unexpected error: \(dataCorruptedError)")
      }
    }
  }
  
  @Test func test_returns_real_ckshare() {
    let record = CanopyResultRecord(ckRecord: CKShare.mock_owned_by_current_user)
    let share = record.asCKShare!
    #expect(share.participants.count == 3)
  }
  
  @Test func test_does_not_return_ckshare_for_mock() {
    let record = CanopyResultRecord(mock: .init(recordType: "SomeType"))
    #expect(record.asCKShare == nil)
  }
  
  @Test func test_does_not_return_ckshare_for_ckrecord() {
    let ckRecord = CKRecord(recordType: "SomeType", recordID: .init(recordName: "recordName"))
    let record = CanopyResultRecord(ckRecord: ckRecord)
    #expect(record.asCKShare == nil)
  }
  
  @Test func test_equatable() {
    let ckRecord1 = CKRecord(recordType: "SomeType", recordID: .init(recordName: "recordName"))
    let record1 = CanopyResultRecord(ckRecord: ckRecord1)
    let record2 = CanopyResultRecord(ckRecord: ckRecord1)
    let mockRecord1 = CanopyResultRecord(
      mock: .init(
        recordID: .init(recordName: "name"),
        recordType: "Type1"
      )
    )
    let mockRecord2 = CanopyResultRecord(
      mock: .init(
        recordID: .init(recordName: "name"),
        recordType: "Type1"
      )
    )
    #expect(record1 == record2)
    #expect(mockRecord1 == mockRecord2)
    #expect(record1 != mockRecord1)
  }
  
  @Test func test_boolforkey_bool_ckrecord() throws {
    let ckRecord = CKRecord(recordType: "SomeType", recordID: .init(recordName: "recordName"))
    ckRecord["myBool"] = true
    let record = CanopyResultRecord(ckRecord: ckRecord)
    let boolValue = record.boolForKey("myBool")
    #expect(boolValue == true)
  }
  
  @Test func test_boolforkey_bool_mock() throws {
    let mock = MockCanopyResultRecord(recordType: "SomeType", values: ["myBool": true])
    let record = CanopyResultRecord(mock: mock)
    let boolValue = record.boolForKey("myBool")
    #expect(boolValue == true)
  }
  
  @Test func test_boolforkey_int() throws {
    let ckRecord = CKRecord(recordType: "SomeType", recordID: .init(recordName: "recordName"))
    ckRecord["myInt64"] = Int64(1)
    let record = CanopyResultRecord(ckRecord: ckRecord)
    let boolValue = record.boolForKey("myInt64")
    #expect(boolValue == true)
  }
  
  @Test func test_boolforkey_int_false() throws {
    let ckRecord = CKRecord(recordType: "SomeType", recordID: .init(recordName: "recordName"))
    ckRecord["myInt"] = Int(0)
    let record = CanopyResultRecord(ckRecord: ckRecord)
    let boolValue = record.boolForKey("myInt")
    #expect(boolValue == false)
  }

  @Test func test_boolforkey_missing() throws {
    let ckRecord = CKRecord(recordType: "SomeType", recordID: .init(recordName: "recordName"))
    ckRecord["myInt"] = Int(0)
    let record = CanopyResultRecord(ckRecord: ckRecord)
    #expect(record.boolForKey("nonexistentValue") == nil)
  }

  
  @Test func test_boolforkey_string() {
    let ckRecord = CKRecord(recordType: "SomeType", recordID: .init(recordName: "recordName"))
    ckRecord["stringValue"] = "Hello"
    let record = CanopyResultRecord(ckRecord: ckRecord)
    #expect(record.boolForKey("stringValue") == nil)
  }
}
