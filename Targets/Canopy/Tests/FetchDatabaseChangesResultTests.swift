import CanopyTypes
import CloudKit
import XCTest

final class FetchDatabaseChangesResultTests: XCTestCase {
  func test_codes() throws {
    let result = FetchDatabaseChangesResult(
      changedRecordZoneIDs: [.init(zoneName: "changedZone", ownerName: "owner1")],
      deletedRecordZoneIDs: [.init(zoneName: "deletedZone", ownerName: "owner2")],
      purgedRecordZoneIDs: [.init(zoneName: "purgedZone", ownerName: "owner3")]
    )
    let coded = try JSONEncoder().encode(result)
    print("Coded: \(String(data: coded, encoding: .utf8)!)")
    let decoded = try JSONDecoder().decode(FetchDatabaseChangesResult.self, from: coded)
    XCTAssertEqual(decoded.changedRecordZoneIDs[0].zoneName, "changedZone")
    XCTAssertEqual(decoded.deletedRecordZoneIDs[0].zoneName, "deletedZone")
    XCTAssertEqual(decoded.purgedRecordZoneIDs[0].zoneName, "purgedZone")
  }
  
  func test_empty() {
    let result = FetchDatabaseChangesResult.empty
    XCTAssertTrue(result.changedRecordZoneIDs.isEmpty)
    XCTAssertTrue(result.deletedRecordZoneIDs.isEmpty)
    XCTAssertTrue(result.purgedRecordZoneIDs.isEmpty)
  }
  
  func test_throws_on_changed_data_error() throws {
    let badJson = "{\"deletedRecordZoneIDs\":\"YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGnCwwSHB0eJFUkbnVsbNINDg8RWk5TLm9iamVjdHNWJGNsYXNzoRCAAoAG1RMUFRYOFxgZGhtfEBBkYXRhYmFzZVNjb3BlS2V5XxARYW5vbnltb3VzQ0tVc2VySURZb3duZXJOYW1lWFpvbmVOYW1lEACAAIAEgAOABVtkZWxldGVkWm9uZVZvd25lcjLSHyAhIlokY2xhc3NuYW1lWCRjbGFzc2VzXkNLUmVjb3JkWm9uZUlEoiEjWE5TT2JqZWN00h8gJSZXTlNBcnJheaIlIwAIABEAGgAkACkAMgA3AEkATABRAFMAWwBhAGYAcQB4AHoAfAB+AIkAnACwALoAwwDFAMcAyQDLAM0A2QDgAOUA8AD5AQgBCwEUARkBIQAAAAAAAAIBAAAAAAAAACcAAAAAAAAAAAAAAAAAAAEk\",\"changedRecordZoneIDs\":\"deadbeef\",\"purgedRecordZoneIDs\":\"YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGnCwwSHB0eJFUkbnVsbNINDg8RWk5TLm9iamVjdHNWJGNsYXNzoRCAAoAG1RMUFRYOFxgZGhtfEBBkYXRhYmFzZVNjb3BlS2V5XxARYW5vbnltb3VzQ0tVc2VySURZb3duZXJOYW1lWFpvbmVOYW1lEACAAIAEgAOABVpwdXJnZWRab25lVm93bmVyM9IfICEiWiRjbGFzc25hbWVYJGNsYXNzZXNeQ0tSZWNvcmRab25lSUSiISNYTlNPYmplY3TSHyAlJldOU0FycmF5oiUjAAgAEQAaACQAKQAyADcASQBMAFEAUwBbAGEAZgBxAHgAegB8AH4AiQCcALAAugDDAMUAxwDJAMsAzQDYAN8A5ADvAPgBBwEKARMBGAEgAAAAAAAAAgEAAAAAAAAAJwAAAAAAAAAAAAAAAAAAASM=\"}"
    let data = badJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(FetchDatabaseChangesResult.self, from: data)
    } catch DecodingError.dataCorrupted(let context) {
      XCTAssertEqual(context.debugDescription, "Invalid changed record zone IDs value in source data")
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
  
  func test_throws_on_deleted_data_error() throws {
    let badJson = "{\"deletedRecordZoneIDs\":\"deadbeef\",\"changedRecordZoneIDs\":\"YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGnCwwSHB0eJFUkbnVsbNINDg8RWk5TLm9iamVjdHNWJGNsYXNzoRCAAoAG1RMUFRYOFxgZGhtfEBBkYXRhYmFzZVNjb3BlS2V5XxARYW5vbnltb3VzQ0tVc2VySURZb3duZXJOYW1lWFpvbmVOYW1lEACAAIAEgAOABVtjaGFuZ2VkWm9uZVZvd25lcjHSHyAhIlokY2xhc3NuYW1lWCRjbGFzc2VzXkNLUmVjb3JkWm9uZUlEoiEjWE5TT2JqZWN00h8gJSZXTlNBcnJheaIlIwAIABEAGgAkACkAMgA3AEkATABRAFMAWwBhAGYAcQB4AHoAfAB+AIkAnACwALoAwwDFAMcAyQDLAM0A2QDgAOUA8AD5AQgBCwEUARkBIQAAAAAAAAIBAAAAAAAAACcAAAAAAAAAAAAAAAAAAAEk\",\"purgedRecordZoneIDs\":\"YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGnCwwSHB0eJFUkbnVsbNINDg8RWk5TLm9iamVjdHNWJGNsYXNzoRCAAoAG1RMUFRYOFxgZGhtfEBBkYXRhYmFzZVNjb3BlS2V5XxARYW5vbnltb3VzQ0tVc2VySURZb3duZXJOYW1lWFpvbmVOYW1lEACAAIAEgAOABVpwdXJnZWRab25lVm93bmVyM9IfICEiWiRjbGFzc25hbWVYJGNsYXNzZXNeQ0tSZWNvcmRab25lSUSiISNYTlNPYmplY3TSHyAlJldOU0FycmF5oiUjAAgAEQAaACQAKQAyADcASQBMAFEAUwBbAGEAZgBxAHgAegB8AH4AiQCcALAAugDDAMUAxwDJAMsAzQDYAN8A5ADvAPgBBwEKARMBGAEgAAAAAAAAAgEAAAAAAAAAJwAAAAAAAAAAAAAAAAAAASM=\"}"
    let data = badJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(FetchDatabaseChangesResult.self, from: data)
    } catch DecodingError.dataCorrupted(let context) {
      XCTAssertEqual(context.debugDescription, "Invalid deleted record zone IDs value in source data")
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
  
  func test_throws_on_purged_data_error() throws {
    let badJson = "{\"deletedRecordZoneIDs\":\"YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGnCwwSHB0eJFUkbnVsbNINDg8RWk5TLm9iamVjdHNWJGNsYXNzoRCAAoAG1RMUFRYOFxgZGhtfEBBkYXRhYmFzZVNjb3BlS2V5XxARYW5vbnltb3VzQ0tVc2VySURZb3duZXJOYW1lWFpvbmVOYW1lEACAAIAEgAOABVtkZWxldGVkWm9uZVZvd25lcjLSHyAhIlokY2xhc3NuYW1lWCRjbGFzc2VzXkNLUmVjb3JkWm9uZUlEoiEjWE5TT2JqZWN00h8gJSZXTlNBcnJheaIlIwAIABEAGgAkACkAMgA3AEkATABRAFMAWwBhAGYAcQB4AHoAfAB+AIkAnACwALoAwwDFAMcAyQDLAM0A2QDgAOUA8AD5AQgBCwEUARkBIQAAAAAAAAIBAAAAAAAAACcAAAAAAAAAAAAAAAAAAAEk\",\"changedRecordZoneIDs\":\"YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGnCwwSHB0eJFUkbnVsbNINDg8RWk5TLm9iamVjdHNWJGNsYXNzoRCAAoAG1RMUFRYOFxgZGhtfEBBkYXRhYmFzZVNjb3BlS2V5XxARYW5vbnltb3VzQ0tVc2VySURZb3duZXJOYW1lWFpvbmVOYW1lEACAAIAEgAOABVtjaGFuZ2VkWm9uZVZvd25lcjHSHyAhIlokY2xhc3NuYW1lWCRjbGFzc2VzXkNLUmVjb3JkWm9uZUlEoiEjWE5TT2JqZWN00h8gJSZXTlNBcnJheaIlIwAIABEAGgAkACkAMgA3AEkATABRAFMAWwBhAGYAcQB4AHoAfAB+AIkAnACwALoAwwDFAMcAyQDLAM0A2QDgAOUA8AD5AQgBCwEUARkBIQAAAAAAAAIBAAAAAAAAACcAAAAAAAAAAAAAAAAAAAEk\",\"purgedRecordZoneIDs\":\"deadbeef\"}"
    let data = badJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(FetchDatabaseChangesResult.self, from: data)
    } catch DecodingError.dataCorrupted(let context) {
      XCTAssertEqual(context.debugDescription, "Invalid purged record zone IDs value in source data")
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}
