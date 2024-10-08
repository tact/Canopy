import Canopy
import CanopyTestTools
import CloudKit
import XCTest

final class ModifyZonesResultTests: XCTestCase {
  func test_codes() throws {
    let savedZones = [
      CKRecordZone(zoneID: .init(zoneName: "someZone1", ownerName: "someOwner")),
      CKRecordZone(zoneID: .init(zoneName: "someZone2", ownerName: "someOwner"))
    ]
    let deletedZoneIDs = [
      CKRecordZone.ID(zoneName: "deletedId1"),
      CKRecordZone.ID(zoneName: "deletedId2")
    ]
    let modifyZonesResult = ModifyZonesResult(
      savedZones: savedZones,
      deletedZoneIDs: deletedZoneIDs
    )
    let coded = try JSONEncoder().encode(modifyZonesResult)
    let decoded = try JSONDecoder().decode(ModifyZonesResult.self, from: coded)
    XCTAssertEqual(decoded.savedZones[1].zoneID.zoneName, "someZone2")
    XCTAssertEqual(decoded.deletedZoneIDs[1].zoneName, "deletedId2")
  }
  
  func test_throws_on_bad_saved_zones_data() {
    let badJson = "{\"deletedZoneIDs\":\"\",\"savedZones\":\"deadbeef\"}"
    let data = badJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(ModifyZonesResult.self, from: data)
    } catch DecodingError.dataCorrupted(let context) {
      XCTAssertEqual(context.debugDescription, "Invalid saved zones value in source data")
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func test_throws_on_bad_deleted_zoneIDs_data() {
    let badJson = "{\"savedZones\":\"YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGtCwwTNj9AQSpHSlpfYFUkbnVsbNINDg8SWk5TLm9iamVjdHNWJGNsYXNzohARgAKACYAM3xASFBUWFxgZGhscHR4fICEiDiMkJSUlJSkqJSUtKiUvLSUyMyUlWFBDU0tleUlEXFpvbmVpc2hLZXlJRF8QEUNsaWVudENoYW5nZVRva2VuXlNoYXJlUmVmZXJlbmNlW0RldmljZUNvdW50XxAPQXNzZXRRdW90YVVzYWdlXkV4cGlyYXRpb25EYXRlXxATUENTTW9kaWZpY2F0aW9uRGF0ZVdFeHBpcmVkXxASTWV0YWRhdGFRdW90YVVzYWdlXxAWUHJldmlvdXNQcm90ZWN0aW9uRXRhZ1Zab25lSURfEBRIYXNVcGRhdGVkRXhwaXJhdGlvbl8QEVVwZGF0ZWRFeHBpcmF0aW9uXENhcGFiaWxpdGllc18QE0ludml0ZWRLZXlzVG9SZW1vdmVfEBhDdXJyZW50U2VydmVyQ2hhbmdlVG9rZW6AAIAAgACAABAAEACAAIAACIAAgAMIgACAB4AIgACAANU3ODk6DiolPD0+XxAQZGF0YWJhc2VTY29wZUtleV8QEWFub255bW91c0NLVXNlcklEWW93bmVyTmFtZVhab25lTmFtZYAAgAWABIAGWXNvbWVab25lMVlzb21lT3duZXLSQkNERVokY2xhc3NuYW1lWCRjbGFzc2VzXkNLUmVjb3JkWm9uZUlEokRGWE5TT2JqZWN00kJDSElcQ0tSZWNvcmRab25lokhG3xASFBUWFxgZGhscHR4fICEiDiMkJSUlJSkqJSUtKiVTLSUyMyUlgACAAIAAgACAAIAACIAAgAoIgACAB4AIgACAANU3ODk6DiolPF0+gACABYALgAZZc29tZVpvbmUy0kJDYWJXTlNBcnJheaJhRgAIABEAGgAkACkAMgA3AEkATABRAFMAYQBnAGwAdwB+AIEAgwCFAIcArgC3AMQA2ADnAPMBBQEUASoBMgFHAWABZwF+AZIBnwG1AdAB0gHUAdYB2AHaAdwB3gHgAeEB4wHlAeYB6AHqAewB7gHwAfsCDgIiAiwCNQI3AjkCOwI9AkcCUQJWAmECagJ5AnwChQKKApcCmgLBAsMCxQLHAskCywLNAs4C0ALSAtMC1QLXAtkC2wLdAugC6gLsAu4C8AL6Av8DBwAAAAAAAAIBAAAAAAAAAGMAAAAAAAAAAAAAAAAAAAMK\",\"deletedZoneIDs\":\"deadbeef\"}"
    let data = badJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(ModifyZonesResult.self, from: data)
    } catch DecodingError.dataCorrupted(let context) {
      XCTAssertEqual(context.debugDescription, "Invalid deleted record zone IDs value in source data")
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}
