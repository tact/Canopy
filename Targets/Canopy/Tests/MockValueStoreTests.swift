@testable import CanopyTypes
import Foundation
import XCTest

final class MockValueStoreTests: XCTestCase {
  func test_codes_string_and_double() throws {
    let sut = MockValueStore(values: [
      "key1": "Hello world",
      "key2": "Another value",
      "intKey": 42,
      "doubleKey": Double(3.14)
    ])
    let jsonEncoder = JSONEncoder()
    let data = try jsonEncoder.encode(sut)
    let jsonString = String(decoding: data, as: UTF8.self)
    print("JSON string: \(jsonString)")
    
    let jsonDecoder = JSONDecoder()
    let outcome = try jsonDecoder.decode(MockValueStore.self, from: data)
    let key1Value = outcome["key1"] as? String
    let intValue = outcome["intKey"] as? Int
    let doubleValue = outcome["doubleKey"] as? Double
    
    XCTAssertEqual(key1Value, "Hello world")
    XCTAssertEqual(intValue, 42)
    XCTAssertEqual(doubleValue, 3.14)
  }
  
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
  
  func test_codes_nsnumber() throws {
    let sut = MockValueStore(values: [
      "numberKey": NSNumber(value: 2.5)
    ])
    let jsonEncoder = JSONEncoder()
    let data = try jsonEncoder.encode(sut)
    let jsonString = String(decoding: data, as: UTF8.self)
    print("JSON string: \(jsonString)")
    
    let jsonDecoder = JSONDecoder()
    let outcome = try jsonDecoder.decode(MockValueStore.self, from: data)
    let numberValue = outcome["numberKey"] as? NSNumber
    
    let expected = NSNumber(floatLiteral: 2.5)
    XCTAssertEqual(numberValue, expected)
  }
}
