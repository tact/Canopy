import Canopy
import CloudKit
import Testing

@Suite struct FetchDatabaseChangesResultTests {
  @Test func test_codes() throws {
    let result = FetchDatabaseChangesResult(
      changedRecordZoneIDs: [.init(zoneName: "changedZone", ownerName: "owner1")],
      deletedRecordZoneIDs: [.init(zoneName: "deletedZone", ownerName: "owner2")],
      purgedRecordZoneIDs: [.init(zoneName: "purgedZone", ownerName: "owner3")]
    )
    let coded = try JSONEncoder().encode(result)
    let decoded = try JSONDecoder().decode(FetchDatabaseChangesResult.self, from: coded)
    #expect(decoded.changedRecordZoneIDs[0].zoneName == "changedZone")
    #expect(decoded.deletedRecordZoneIDs[0].zoneName == "deletedZone")
    #expect(decoded.purgedRecordZoneIDs[0].zoneName == "purgedZone")
  }
  
  @Test func test_empty() {
    let result = FetchDatabaseChangesResult.empty
    #expect(result.changedRecordZoneIDs.isEmpty == true)
    #expect(result.deletedRecordZoneIDs.isEmpty == true)
    #expect(result.purgedRecordZoneIDs.isEmpty == true)
  }
  
  @Test func test_throws_on_changed_data_error() throws {
    let badJson = "{\"deletedRecordZoneIDs\":\"YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGnCwwSHB0eJFUkbnVsbNINDg8RWk5TLm9iamVjdHNWJGNsYXNzoRCAAoAG1RMUFRYOFxgZGhtfEBBkYXRhYmFzZVNjb3BlS2V5XxARYW5vbnltb3VzQ0tVc2VySURZb3duZXJOYW1lWFpvbmVOYW1lEACAAIAEgAOABVtkZWxldGVkWm9uZVZvd25lcjLSHyAhIlokY2xhc3NuYW1lWCRjbGFzc2VzXkNLUmVjb3JkWm9uZUlEoiEjWE5TT2JqZWN00h8gJSZXTlNBcnJheaIlIwAIABEAGgAkACkAMgA3AEkATABRAFMAWwBhAGYAcQB4AHoAfAB+AIkAnACwALoAwwDFAMcAyQDLAM0A2QDgAOUA8AD5AQgBCwEUARkBIQAAAAAAAAIBAAAAAAAAACcAAAAAAAAAAAAAAAAAAAEk\",\"changedRecordZoneIDs\":\"deadbeef\",\"purgedRecordZoneIDs\":\"YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGnCwwSHB0eJFUkbnVsbNINDg8RWk5TLm9iamVjdHNWJGNsYXNzoRCAAoAG1RMUFRYOFxgZGhtfEBBkYXRhYmFzZVNjb3BlS2V5XxARYW5vbnltb3VzQ0tVc2VySURZb3duZXJOYW1lWFpvbmVOYW1lEACAAIAEgAOABVpwdXJnZWRab25lVm93bmVyM9IfICEiWiRjbGFzc25hbWVYJGNsYXNzZXNeQ0tSZWNvcmRab25lSUSiISNYTlNPYmplY3TSHyAlJldOU0FycmF5oiUjAAgAEQAaACQAKQAyADcASQBMAFEAUwBbAGEAZgBxAHgAegB8AH4AiQCcALAAugDDAMUAxwDJAMsAzQDYAN8A5ADvAPgBBwEKARMBGAEgAAAAAAAAAgEAAAAAAAAAJwAAAAAAAAAAAAAAAAAAASM=\"}"
    let data = badJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(FetchDatabaseChangesResult.self, from: data)
    } catch DecodingError.dataCorrupted(let context) {
      #expect(context.debugDescription == "Invalid changed record zone IDs value in source data")
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }
  
  @Test func test_throws_on_deleted_data_error() throws {
    let badJson = "{\"deletedRecordZoneIDs\":\"deadbeef\",\"changedRecordZoneIDs\":\"YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGnCwwSHB0eJFUkbnVsbNINDg8RWk5TLm9iamVjdHNWJGNsYXNzoRCAAoAG1RMUFRYOFxgZGhtfEBBkYXRhYmFzZVNjb3BlS2V5XxARYW5vbnltb3VzQ0tVc2VySURZb3duZXJOYW1lWFpvbmVOYW1lEACAAIAEgAOABVtjaGFuZ2VkWm9uZVZvd25lcjHSHyAhIlokY2xhc3NuYW1lWCRjbGFzc2VzXkNLUmVjb3JkWm9uZUlEoiEjWE5TT2JqZWN00h8gJSZXTlNBcnJheaIlIwAIABEAGgAkACkAMgA3AEkATABRAFMAWwBhAGYAcQB4AHoAfAB+AIkAnACwALoAwwDFAMcAyQDLAM0A2QDgAOUA8AD5AQgBCwEUARkBIQAAAAAAAAIBAAAAAAAAACcAAAAAAAAAAAAAAAAAAAEk\",\"purgedRecordZoneIDs\":\"YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGnCwwSHB0eJFUkbnVsbNINDg8RWk5TLm9iamVjdHNWJGNsYXNzoRCAAoAG1RMUFRYOFxgZGhtfEBBkYXRhYmFzZVNjb3BlS2V5XxARYW5vbnltb3VzQ0tVc2VySURZb3duZXJOYW1lWFpvbmVOYW1lEACAAIAEgAOABVpwdXJnZWRab25lVm93bmVyM9IfICEiWiRjbGFzc25hbWVYJGNsYXNzZXNeQ0tSZWNvcmRab25lSUSiISNYTlNPYmplY3TSHyAlJldOU0FycmF5oiUjAAgAEQAaACQAKQAyADcASQBMAFEAUwBbAGEAZgBxAHgAegB8AH4AiQCcALAAugDDAMUAxwDJAMsAzQDYAN8A5ADvAPgBBwEKARMBGAEgAAAAAAAAAgEAAAAAAAAAJwAAAAAAAAAAAAAAAAAAASM=\"}"
    let data = badJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(FetchDatabaseChangesResult.self, from: data)
    } catch DecodingError.dataCorrupted(let context) {
      #expect(context.debugDescription == "Invalid deleted record zone IDs value in source data")
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }
  
  @Test func test_throws_on_purged_data_error() throws {
    let badJson = "{\"deletedRecordZoneIDs\":\"YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGnCwwSHB0eJFUkbnVsbNINDg8RWk5TLm9iamVjdHNWJGNsYXNzoRCAAoAG1RMUFRYOFxgZGhtfEBBkYXRhYmFzZVNjb3BlS2V5XxARYW5vbnltb3VzQ0tVc2VySURZb3duZXJOYW1lWFpvbmVOYW1lEACAAIAEgAOABVtkZWxldGVkWm9uZVZvd25lcjLSHyAhIlokY2xhc3NuYW1lWCRjbGFzc2VzXkNLUmVjb3JkWm9uZUlEoiEjWE5TT2JqZWN00h8gJSZXTlNBcnJheaIlIwAIABEAGgAkACkAMgA3AEkATABRAFMAWwBhAGYAcQB4AHoAfAB+AIkAnACwALoAwwDFAMcAyQDLAM0A2QDgAOUA8AD5AQgBCwEUARkBIQAAAAAAAAIBAAAAAAAAACcAAAAAAAAAAAAAAAAAAAEk\",\"changedRecordZoneIDs\":\"YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGnCwwSHB0eJFUkbnVsbNINDg8RWk5TLm9iamVjdHNWJGNsYXNzoRCAAoAG1RMUFRYOFxgZGhtfEBBkYXRhYmFzZVNjb3BlS2V5XxARYW5vbnltb3VzQ0tVc2VySURZb3duZXJOYW1lWFpvbmVOYW1lEACAAIAEgAOABVtjaGFuZ2VkWm9uZVZvd25lcjHSHyAhIlokY2xhc3NuYW1lWCRjbGFzc2VzXkNLUmVjb3JkWm9uZUlEoiEjWE5TT2JqZWN00h8gJSZXTlNBcnJheaIlIwAIABEAGgAkACkAMgA3AEkATABRAFMAWwBhAGYAcQB4AHoAfAB+AIkAnACwALoAwwDFAMcAyQDLAM0A2QDgAOUA8AD5AQgBCwEUARkBIQAAAAAAAAIBAAAAAAAAACcAAAAAAAAAAAAAAAAAAAEk\",\"purgedRecordZoneIDs\":\"deadbeef\"}"
    let data = badJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(FetchDatabaseChangesResult.self, from: data)
    } catch DecodingError.dataCorrupted(let context) {
      #expect(context.debugDescription == "Invalid purged record zone IDs value in source data")
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }
}
