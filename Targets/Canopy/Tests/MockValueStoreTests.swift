@testable import CanopyTypes
import CloudKit
import Foundation
import XCTest

typealias ValueStore = MockCanopyResultRecord.MockValueStore

final class MockValueStoreTests: XCTestCase {
  
  // MARK: - Invididual data types
  
  func test_codes_string() throws {
    let sut = ValueStore(values: [
      "key1": "Hello world",
      "key2": "Another value",
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let key1Value = outcome["key1"] as? String
    let key2Value = outcome["key2"] as? String

    XCTAssertEqual(key1Value, "Hello world")
    XCTAssertEqual(key2Value, "Another value")
  }
  
  func test_codes_nsstring() throws {
    let sut = ValueStore(values: [
      "_force_nstype_key1": NSString(string: "Hello world"),
      "_force_nstype_key2": NSString(string: "Another value"),
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let key1Value = outcome["_force_nstype_key1"] as? NSString
    let key2Value = outcome["_force_nstype_key2"] as? NSString

    XCTAssertEqual(key1Value, "Hello world")
    XCTAssertEqual(key2Value, "Another value")
  }
  
  func test_codes_ints() throws {
    let sut = ValueStore(values: [
      "intKey": Int(42),
      "zeroKey": Int(0),
      "oneKey": Int(1),
      "twoKey": Int(2),
      "int8Key": Int8(9),
      "int16Key": Int16(17),
      "int32Key": Int32(33),
      "int64Key": Int64(65)
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    
    XCTAssertEqual(outcome["intKey"] as! Int, 42)
    XCTAssertEqual(outcome["zeroKey"] as! Int, 0)
    XCTAssertEqual(outcome["oneKey"] as! Int, 1)
    XCTAssertEqual(outcome["twoKey"] as! Int, 2)
    XCTAssertEqual(outcome["int8Key"] as! Int8, 9)
    XCTAssertEqual(outcome["int16Key"] as! Int16, 17)
    XCTAssertEqual(outcome["int32Key"] as! Int32, 33)
    XCTAssertEqual(outcome["int64Key"] as! Int64, 65)
  }
  
  func test_codes_uints() throws {
    let sut = ValueStore(values: [
      "zeroKey": UInt(0),
      "oneKey": UInt(1),
      "twoKey": UInt(2),
      "uint8Key": UInt8(9),
      "uint16Key": UInt16(17),
      "uint32Key": UInt32(33),
      "uint64Key": UInt64(65)
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    
    XCTAssertEqual(outcome["zeroKey"] as! UInt, 0)
    XCTAssertEqual(outcome["oneKey"] as! UInt, 1)
    XCTAssertEqual(outcome["twoKey"] as! UInt, 2)
    XCTAssertEqual(outcome["uint8Key"] as! UInt8, 9)
    XCTAssertEqual(outcome["uint16Key"] as! UInt16, 17)
    XCTAssertEqual(outcome["uint32Key"] as! UInt32, 33)
    XCTAssertEqual(outcome["uint64Key"] as! UInt64, 65)
  }
  
  func test_codes_double() throws {
    let sut = ValueStore(values: [
      "doubleKey": Double(3.14)
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let doubleValue = outcome["doubleKey"] as? Double
    
    XCTAssertEqual(doubleValue, 3.14)
  }
  
  func test_codes_float() throws {
    let sut = ValueStore(values: [
      "floatKey": Float(3.14)
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let floatValue = outcome["floatKey"] as? Float
    
    XCTAssertEqual(floatValue, 3.14)
  }
  
  func test_codes_bool() throws {
    let sut = ValueStore(values: [
      "trueValue": true,
      "falseValue": false
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let trueValue = outcome["trueValue"] as! Bool
    let falseValue = outcome["falseValue"] as! Bool
    
    XCTAssertTrue(trueValue)
    XCTAssertFalse(falseValue)
  }
  
  func test_codes_nsnumber() throws {
    let sut = ValueStore(values: [
      "_force_nstype_numberKey": NSNumber(floatLiteral: 2.5)
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let numberValue = outcome["_force_nstype_numberKey"] as? NSNumber
    
    let expected = NSNumber(floatLiteral: 2.5)
    XCTAssertEqual(numberValue, expected)
  }
    
  func test_codes_array() throws {
    let sut = ValueStore(values: [
      "texts": ["one", "two", "three"]
    ])
    
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let arrayValue = outcome["texts"] as? Array<String>
    
    XCTAssertEqual(arrayValue, ["one", "two", "three"])
  }
  
  func test_codes_nsArray() throws {
    let sut = ValueStore(values: [
      "texts": NSArray(array: ["one", "two", "three"])
    ])
    
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let arrayValue = outcome["texts"] as? Array<String>
    
    XCTAssertEqual(arrayValue, ["one", "two", "three"])
  }
  
  func test_codes_date() throws {
    let date = Date()
    let sut = ValueStore(values: [
      "dateKey": date
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let dateValue = outcome["dateKey"] as? Date
    
    XCTAssertEqual(dateValue, date)
  }
  
  func test_codes_nsDate() throws {
    let nsDate = NSDate()
    let sut = ValueStore(values: [
      "_force_nstype_dateKey": nsDate
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let nsDateValue = outcome["_force_nstype_dateKey"] as? NSDate
    
    XCTAssertEqual(nsDateValue, nsDate)
  }
  
  func test_codes_data() throws {
    let sut = ValueStore(values: [
      "dataKey": Data([2, 4, 7])
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let dataValue = outcome["dataKey"] as? Data
    
    XCTAssertEqual(dataValue, Data([2, 4, 7]))
  }
  
  func test_codes_nsData() throws {
    let nsData = NSData(bytes: [0x01, 0x02, 0x04] as [UInt8], length: 3)
    let sut = ValueStore(values: [
      "_force_nstype_dataKey": nsData
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let nsDataValue = outcome["_force_nstype_dataKey"] as? NSData
    
    XCTAssertEqual(nsDataValue, NSData(bytes: [0x01, 0x02, 0x04] as [UInt8], length: 3))
  }
  
  func test_codes_ckAsset() throws {
    let url = Bundle.module.url(forResource: "textFile", withExtension: "txt")!
    let ckAsset = CKAsset(fileURL: url)
    let sut = ValueStore(values: [
      "assetKey": ckAsset
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let asset = outcome["assetKey"] as? CKAsset
    XCTAssertEqual(asset!.fileURL!.lastPathComponent, "textFile.txt")
  }
  
  func test_codes_clLocation() throws {
    let location = CLLocation(latitude: 37.332939350106514, longitude: -122.00488014474543)
    let sut = ValueStore(values: [
      "locationKey": location
    ])
    
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let locationValue = outcome["locationKey"] as? CLLocation
    XCTAssertEqual(locationValue!.distance(from: location), 0)
  }
  
  func test_codes_ckRecordReference() throws {
    let reference = CKRecord.Reference(recordID: .init(recordName: "demoRecord"), action: .none)
    let sut = ValueStore(values: [
      "recordReferenceKey": reference
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let referenceValue = outcome["recordReferenceKey"] as? CKRecord.Reference
    XCTAssertEqual(referenceValue?.recordID.recordName, "demoRecord")
  }
  
  func test_codes_ckRecordReference_array() throws {
    let reference1 = CKRecord.Reference(recordID: .init(recordName: "demoRecord1"), action: .none)
    let reference2 = CKRecord.Reference(recordID: .init(recordName: "demoRecord2"), action: .none)
    let sut = ValueStore(values: [
      "recordReferenceArrayKey": [reference1, reference2]
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let references = outcome["recordReferenceArrayKey"] as? [CKRecord.Reference]
    XCTAssertEqual(references![0].recordID.recordName, "demoRecord1")
    XCTAssertEqual(references![1].recordID.recordName, "demoRecord2")
  }
  
  // MARK: - Error and invalid data handling
  
  func test_throws_on_invalid_data_type() {
    let brokenTypeJson = "[{\"value\":42,\"key\":\"intKey\",\"type\":\"BrokenType\"}]"
    let data = brokenTypeJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(ValueStore.self, from: data)
    } catch {
      let dataCorruptedError = error as! DecodingError
      switch dataCorruptedError {
      case .dataCorrupted(let context):
        XCTAssertEqual(context.debugDescription, "Invalid data type: BrokenType")
      default:
        XCTFail("Unexpected error: \(dataCorruptedError)")
      }
    }
  }
  
  func test_throws_on_invalid_nsnumber_data() {
    let brokenTypeJson = "[{\"value\":\"deadbeef\",\"key\":\"intKey\",\"type\":\"nsNumber\"}]"
    let data = brokenTypeJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(ValueStore.self, from: data)
    } catch {
      let dataCorruptedError = error as! DecodingError
      switch dataCorruptedError {
      case .dataCorrupted(let context):
        XCTAssertEqual(context.debugDescription, "Invalid NSNumber value in source data")
      default:
        XCTFail("Unexpected error: \(dataCorruptedError)")
      }
    }
  }
  
  func test_throws_on_invalid_nsstring_data() {
    let brokenTypeJson = "[{\"value\":\"deadbeef\",\"key\":\"intKey\",\"type\":\"nsString\"}]"
    let data = brokenTypeJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(ValueStore.self, from: data)
    } catch {
      let dataCorruptedError = error as! DecodingError
      switch dataCorruptedError {
      case .dataCorrupted(let context):
        XCTAssertEqual(context.debugDescription, "Invalid NSString value in source data")
      default:
        XCTFail("Unexpected error: \(dataCorruptedError)")
      }
    }
  }
  
  func test_throws_on_invalid_nsdate_data() {
    let brokenTypeJson = "[{\"value\":\"deadbeef\",\"key\":\"dateKey\",\"type\":\"nsDate\"}]"
    let data = brokenTypeJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(ValueStore.self, from: data)
    } catch {
      let dataCorruptedError = error as! DecodingError
      switch dataCorruptedError {
      case .dataCorrupted(let context):
        XCTAssertEqual(context.debugDescription, "Invalid NSDate value in source data")
      default:
        XCTFail("Unexpected error: \(dataCorruptedError)")
      }
    }
  }
  
  func test_throws_on_invalid_nsdata_data() {
    let brokenTypeJson = "[{\"value\":\"deadbeef\",\"key\":\"dataKey\",\"type\":\"nsData\"}]"
    let data = brokenTypeJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(ValueStore.self, from: data)
    } catch {
      let dataCorruptedError = error as! DecodingError
      switch dataCorruptedError {
      case .dataCorrupted(let context):
        XCTAssertEqual(context.debugDescription, "Invalid NSData value in source data")
      default:
        XCTFail("Unexpected error: \(dataCorruptedError)")
      }
    }
  }
  
  func test_throws_on_invalid_location_data() {
    let brokenTypeJson = "[{\"value\":\"deadbeef\",\"key\":\"dataKey\",\"type\":\"clLocation\"}]"
    let data = brokenTypeJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(ValueStore.self, from: data)
    } catch {
      let dataCorruptedError = error as! DecodingError
      switch dataCorruptedError {
      case .dataCorrupted(let context):
        XCTAssertEqual(context.debugDescription, "Invalid CLLocation value in source data")
      default:
        XCTFail("Unexpected error: \(dataCorruptedError)")
      }
    }
  }
  
  func test_throws_on_invalid_ckRecordReference_data() {
    let brokenTypeJson = "[{\"value\":\"deadbeef\",\"key\":\"dataKey\",\"type\":\"ckRecordReference\"}]"
    let data = brokenTypeJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(ValueStore.self, from: data)
    } catch {
      let dataCorruptedError = error as! DecodingError
      switch dataCorruptedError {
      case .dataCorrupted(let context):
        XCTAssertEqual(context.debugDescription, "Invalid CKRecord.Reference value in source data")
      default:
        XCTFail("Unexpected error: \(dataCorruptedError)")
      }
    }
  }
  
  func test_invalid_ckAsset_url() {
    // CKAsset API says that “if the system can’t create the asset” (and I’d expect
    // the URL pointing to nonexistent file to tigger this), the return value
    // will be nil.
    //
    // In reality, there seems to be no file validation at asset creation
    // time, and the system will happily construct a CKAsset with a nonexistent path.
    // Presumably, CloudKit API-s will return errors if you actually try to do
    // something with this asset.
    let brokenAssetJson = "[{\"key\":\"assetKey\",\"type\":\"ckAsset\",\"value\":\"file:\\/\\/\\/some\\/nonexistent\\/path\\/textFile.txt\"}]"
    let data = brokenAssetJson.data(using: .utf8)!
    let store = try? JSONDecoder().decode(ValueStore.self, from: data)
    let asset = store!["assetKey"] as? CKAsset
    XCTAssertEqual(asset!.fileURL!.lastPathComponent, "textFile.txt")
  }
}
