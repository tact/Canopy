@testable import CanopyTypes
import Foundation
import XCTest

final class MockValueStoreTests: XCTestCase {
  func test_codes_string_and_int() throws {
    let sut = MockValueStore(values: [
      "key1": "Hello world",
      "key2": "Another value",
      "intKey": 42
    ])
    let jsonEncoder = JSONEncoder()
    let data = try jsonEncoder.encode(sut)
    let jsonString = String(decoding: data, as: UTF8.self)
    print("JSON string: \(jsonString)")
    
    let jsonDecoder = JSONDecoder()
    let outcome = try jsonDecoder.decode(MockValueStore.self, from: data)
    let key1Value = outcome["key1"] as? String
    XCTAssertEqual(key1Value, "Hello world")
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
}
