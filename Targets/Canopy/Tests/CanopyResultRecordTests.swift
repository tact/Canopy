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
}
