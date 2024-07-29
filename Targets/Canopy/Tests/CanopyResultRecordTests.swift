@testable import Canopy
import CloudKit
import XCTest

final class CanopyResultRecordTests: XCTestCase {
  func test_init_with_ckrecord() {
    let ckRecord = CKRecord(recordType: "SomeRecordType", recordID: .init(recordName: "someRecordName"))
    ckRecord["textValue"] = "someTextValue"
    ckRecord.encryptedValues["encryptedTextValue"] = "someEncryptedTextValue"
    let canopyResultRecord = CanopyResultRecord(ckRecord: ckRecord)
    
    XCTAssertEqual(canopyResultRecord.recordType, "SomeRecordType")
    XCTAssertEqual(canopyResultRecord.recordID.recordName, "someRecordName")
    XCTAssertEqual(canopyResultRecord["textValue"] as? String, "someTextValue")
    XCTAssertEqual(canopyResultRecord.encryptedValuesView["encryptedTextValue"] as? String, "someEncryptedTextValue")
    XCTAssertNil(canopyResultRecord.recordChangeTag)
    XCTAssertNil(canopyResultRecord.creationDate)
    XCTAssertNil(canopyResultRecord.modificationDate)
    XCTAssertNil(canopyResultRecord.creatorUserRecordID)
    XCTAssertNil(canopyResultRecord.lastModifiedUserRecordID)
    XCTAssertNil(canopyResultRecord.parent)
    XCTAssertNil(canopyResultRecord.share)
  }
  
  func test_init_with_mock() {
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
    XCTAssertEqual(canopyResultRecord.recordID.recordName, "mockRecordName")
    XCTAssertEqual(canopyResultRecord.recordType, "MockRecord")
    XCTAssertEqual(canopyResultRecord.creatorUserRecordID!.recordName, "creatorRecordID")
    XCTAssertEqual(canopyResultRecord.lastModifiedUserRecordID!.recordName, "modifierRecordID")
    XCTAssertEqual(canopyResultRecord.creationDate, creationDate)
    XCTAssertEqual(canopyResultRecord.modificationDate, modificationDate)
    XCTAssertEqual(canopyResultRecord["textValue"] as? String, "someTextValue")
    XCTAssertEqual(canopyResultRecord.encryptedValuesView["encryptedTextValue"] as? String, "someEncryptedTextValue")
    XCTAssertEqual(canopyResultRecord.recordChangeTag, "changeTag")
    XCTAssertEqual(canopyResultRecord.parent!.recordID.recordName, "parentRecordID")
    XCTAssertEqual(canopyResultRecord.share!.recordID.recordName, "shareRecordID")
  }
  
  func test_codes_ckrecord() throws {
    let ckRecord = CKRecord(recordType: "SomeRecordType", recordID: .init(recordName: "someRecordName"))
    ckRecord["textValue"] = "someTextValue"
    ckRecord.encryptedValues["encryptedTextValue"] = "someEncryptedTextValue"
    let canopyResultRecord = CanopyResultRecord(ckRecord: ckRecord)
    let coded = try JSONEncoder().encode(canopyResultRecord)
    let string = String(data: coded, encoding: .utf8)!
    print("JSON: \(string)")
    let decodedRecord = try JSONDecoder().decode(CanopyResultRecord.self, from: coded)
    XCTAssertEqual(decodedRecord.recordType, "SomeRecordType")
    XCTAssertEqual(decodedRecord.recordID.recordName, "someRecordName")
  }
  
  func test_codes_mock() throws {
    let mock = MockCanopyResultRecord(recordType: "MockRecordType")
    let canopyResultRecord = CanopyResultRecord(mock: mock)
    let coded = try JSONEncoder().encode(canopyResultRecord)
    let string = String(data: coded, encoding: .utf8)!
    print("JSON: \(string)")
    let decodedRecord = try JSONDecoder().decode(CanopyResultRecord.self, from: coded)
    XCTAssertEqual(decodedRecord.recordType, "MockRecordType")
  }
  
  func test_throws_on_invalid_type() {
    let badJson = "{\"backingValue\":{\"recordType\":\"MockRecordType\",\"encryptedValuesStore\":[],\"valuesStore\":[],\"recordID\":\"deadbeef\"},\"type\":\"badType\"}"
    let data = badJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(CanopyResultRecord.self, from: data)
    } catch {
      let dataCorruptedError = error as! DecodingError
      switch dataCorruptedError {
      case .dataCorrupted(let context):
        XCTAssertEqual(context.debugDescription, "Invalid backing value type: badType")
      default:
        XCTFail("Unexpected error: \(dataCorruptedError)")
      }
    }
  }
  
  func test_throws_on_bad_ckrecord_data() {
    let badJson = "{\"type\":\"ckRecord\",\"backingValue\":\"deadbeef\"}"
    let data = badJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(CanopyResultRecord.self, from: data)
    } catch {
      let dataCorruptedError = error as! DecodingError
      switch dataCorruptedError {
      case .dataCorrupted(let context):
        XCTAssertEqual(context.debugDescription, "Invalid data for CKRecord")
      default:
        XCTFail("Unexpected error: \(dataCorruptedError)")
      }
    }
  }
}
