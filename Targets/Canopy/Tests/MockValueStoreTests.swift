@testable import CanopyTypes
import Foundation
import XCTest

final class MockValueStoreTests: XCTestCase {
  
  // MARK: - Invididual data types
  
  func test_codes_string() throws {
    let sut = MockValueStore(values: [
      "key1": "Hello world",
      "key2": "Another value",
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(MockValueStore.self, from: data)
    let key1Value = outcome["key1"] as? String
    let key2Value = outcome["key2"] as? String

    XCTAssertEqual(key1Value, "Hello world")
    XCTAssertEqual(key2Value, "Another value")
  }
  
  func test_codes_nsstring() throws {
    let sut = MockValueStore(values: [
      "_force_nstype_key1": NSString(string: "Hello world"),
      "_force_nstype_key2": NSString(string: "Another value"),
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(MockValueStore.self, from: data)
    let key1Value = outcome["_force_nstype_key1"] as? NSString
    let key2Value = outcome["_force_nstype_key2"] as? NSString

    XCTAssertEqual(key1Value, "Hello world")
    XCTAssertEqual(key2Value, "Another value")
  }
  
  func test_codes_ints() throws {
    let sut = MockValueStore(values: [
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
    let outcome = try JSONDecoder().decode(MockValueStore.self, from: data)
    
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
    let sut = MockValueStore(values: [
      "zeroKey": UInt(0),
      "oneKey": UInt(1),
      "twoKey": UInt(2),
      "uint8Key": UInt8(9),
      "uint16Key": UInt16(17),
      "uint32Key": UInt32(33),
      "uint64Key": UInt64(65)
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(MockValueStore.self, from: data)
    
    XCTAssertEqual(outcome["zeroKey"] as! UInt, 0)
    XCTAssertEqual(outcome["oneKey"] as! UInt, 1)
    XCTAssertEqual(outcome["twoKey"] as! UInt, 2)
    XCTAssertEqual(outcome["uint8Key"] as! UInt8, 9)
    XCTAssertEqual(outcome["uint16Key"] as! UInt16, 17)
    XCTAssertEqual(outcome["uint32Key"] as! UInt32, 33)
    XCTAssertEqual(outcome["uint64Key"] as! UInt64, 65)
  }
  
  func test_codes_double() throws {
    let sut = MockValueStore(values: [
      "doubleKey": Double(3.14)
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(MockValueStore.self, from: data)
    let doubleValue = outcome["doubleKey"] as? Double
    
    XCTAssertEqual(doubleValue, 3.14)
  }
  
  func test_codes_bool() throws {
    let sut = MockValueStore(values: [
      "trueValue": true,
      "falseValue": false
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(MockValueStore.self, from: data)
    let trueValue = outcome["trueValue"] as! Bool
    let falseValue = outcome["falseValue"] as! Bool
    
    XCTAssertTrue(trueValue)
    XCTAssertFalse(falseValue)
  }
  
  func test_codes_nsnumber() throws {
    let sut = MockValueStore(values: [
      "_force_nstype_numberKey": NSNumber(floatLiteral: 2.5)
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(MockValueStore.self, from: data)
    let numberValue = outcome["_force_nstype_numberKey"] as? NSNumber
    
    let expected = NSNumber(floatLiteral: 2.5)
    XCTAssertEqual(numberValue, expected)
  }
    
  func test_codes_array() throws {
    let sut = MockValueStore(values: [
      "texts": ["one", "two", "three"]
    ])
    
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(MockValueStore.self, from: data)
    let arrayValue = outcome["texts"] as? Array<String>
    
    XCTAssertEqual(arrayValue, ["one", "two", "three"])
  }
  
  // MARK: - Error and invalid data handling
  
  func test_throws_on_invalid_data_type() {
    let brokenTypeJson = "[{\"value\":42,\"key\":\"intKey\",\"type\":\"BrokenType\"}]"
    let data = brokenTypeJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(MockValueStore.self, from: data)
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
      let _ = try JSONDecoder().decode(MockValueStore.self, from: data)
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
      let _ = try JSONDecoder().decode(MockValueStore.self, from: data)
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
}
