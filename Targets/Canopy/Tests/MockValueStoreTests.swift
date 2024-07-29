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
  
  func test_codes_int() throws {
    let sut = MockValueStore(values: [
      "intKey": 42
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(MockValueStore.self, from: data)
    let intValue = outcome["intKey"] as? Int
    
    XCTAssertEqual(intValue, 42)
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
}
