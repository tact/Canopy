@testable import Canopy
import CloudKit
import Foundation
import Testing

typealias ValueStore = MockCanopyResultRecord.MockValueStore

@Suite struct MockValueStoreTests {
  
  // MARK: - Invididual data types
  
  @Test func test_codes_string() throws {
    let sut = ValueStore(values: [
      "key1": "Hello world",
      "key2": "Another value",
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let key1Value = outcome["key1"] as? String
    let key2Value = outcome["key2"] as? String

    #expect(key1Value == "Hello world")
    #expect(key2Value == "Another value")
  }
  
  @Test func test_codes_nsstring() throws {
    let sut = ValueStore(values: [
      "_force_nstype_key1": NSString(string: "Hello world"),
      "_force_nstype_key2": NSString(string: "Another value"),
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let key1Value = outcome["_force_nstype_key1"] as? NSString
    let key2Value = outcome["_force_nstype_key2"] as? NSString

    #expect(key1Value == "Hello world")
    #expect(key2Value == "Another value")
  }
  
  @Test func test_codes_ints() throws {
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
    
    #expect(outcome["intKey"] as! Int == 42)
    #expect(outcome["zeroKey"] as! Int == 0)
    #expect(outcome["oneKey"] as! Int == 1)
    #expect(outcome["twoKey"] as! Int == 2)
    #expect(outcome["int8Key"] as! Int8 == 9)
    #expect(outcome["int16Key"] as! Int16 == 17)
    #expect(outcome["int32Key"] as! Int32 == 33)
    #expect(outcome["int64Key"] as! Int64 == 65)
  }
  
  @Test func test_codes_uints() throws {
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
    
    #expect(outcome["zeroKey"] as! UInt == 0)
    #expect(outcome["oneKey"] as! UInt == 1)
    #expect(outcome["twoKey"] as! UInt == 2)
    #expect(outcome["uint8Key"] as! UInt8 == 9)
    #expect(outcome["uint16Key"] as! UInt16 == 17)
    #expect(outcome["uint32Key"] as! UInt32 == 33)
    #expect(outcome["uint64Key"] as! UInt64 == 65)
  }
  
  @Test func test_codes_double() throws {
    let sut = ValueStore(values: [
      "doubleKey": Double(3.14)
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let doubleValue = outcome["doubleKey"] as? Double
    
    #expect(doubleValue == 3.14)
  }
  
  @Test func test_codes_float() throws {
    let sut = ValueStore(values: [
      "floatKey": Float(3.14)
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let floatValue = outcome["floatKey"] as? Float
    
    #expect(floatValue == 3.14)
  }
  
  @Test func test_codes_bool() throws {
    let sut = ValueStore(values: [
      "trueValue": true,
      "falseValue": false
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let trueValue = outcome["trueValue"] as! Bool
    let falseValue = outcome["falseValue"] as! Bool
    
    #expect(trueValue == true)
    #expect(falseValue == false)
  }
  
  @Test func test_codes_nsnumber() throws {
    let sut = ValueStore(values: [
      "_force_nstype_numberKey": NSNumber(floatLiteral: 2.5)
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let numberValue = outcome["_force_nstype_numberKey"] as? NSNumber
    
    let expected = NSNumber(floatLiteral: 2.5)
    #expect(numberValue == expected)
  }
    
  @Test func test_codes_array() throws {
    let sut = ValueStore(values: [
      "texts": ["one", "two", "three"]
    ])
    
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let arrayValue = outcome["texts"] as? Array<String>
    
    #expect(arrayValue == ["one", "two", "three"])
  }
  
  @Test func test_codes_nsArray() throws {
    let sut = ValueStore(values: [
      "texts": NSArray(array: ["one", "two", "three"])
    ])
    
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let arrayValue = outcome["texts"] as? Array<String>
    
    #expect(arrayValue == ["one", "two", "three"])
  }
  
  @Test func test_codes_date() throws {
    let date = Date()
    let sut = ValueStore(values: [
      "dateKey": date
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let dateValue = outcome["dateKey"] as? Date
    
    #expect(dateValue == date)
  }
  
  @Test func test_codes_nsDate() throws {
    let nsDate = NSDate()
    let sut = ValueStore(values: [
      "_force_nstype_dateKey": nsDate
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let nsDateValue = outcome["_force_nstype_dateKey"] as? NSDate
    
    #expect(nsDateValue == nsDate)
  }
  
  @Test func test_codes_data() throws {
    let sut = ValueStore(values: [
      "dataKey": Data([2, 4, 7])
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let dataValue = outcome["dataKey"] as? Data
    
    #expect(dataValue == Data([2, 4, 7]))
  }
  
  @Test func test_codes_nsData() throws {
    let nsData = NSData(bytes: [0x01, 0x02, 0x04] as [UInt8], length: 3)
    let sut = ValueStore(values: [
      "_force_nstype_dataKey": nsData
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let nsDataValue = outcome["_force_nstype_dataKey"] as? NSData
    
    #expect(nsDataValue == NSData(bytes: [0x01, 0x02, 0x04] as [UInt8], length: 3))
  }
  
  @Test func test_codes_ckAsset() throws {
    let url = Bundle.module.url(forResource: "textFile", withExtension: "txt")!
    let ckAsset = CKAsset(fileURL: url)
    let sut = ValueStore(values: [
      "assetKey": ckAsset
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let asset = outcome["assetKey"] as? CKAsset
    #expect(asset!.fileURL!.lastPathComponent == "textFile.txt")
  }
  
  @Test func test_codes_clLocation() throws {
    let location = CLLocation(latitude: 37.332939350106514, longitude: -122.00488014474543)
    let sut = ValueStore(values: [
      "locationKey": location
    ])
    
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let locationValue = outcome["locationKey"] as? CLLocation
    #expect(locationValue!.distance(from: location) == 0)
  }
  
  @Test func test_codes_ckRecordReference() throws {
    let reference = CKRecord.Reference(recordID: .init(recordName: "demoRecord"), action: .none)
    let sut = ValueStore(values: [
      "recordReferenceKey": reference
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let referenceValue = outcome["recordReferenceKey"] as? CKRecord.Reference
    #expect(referenceValue?.recordID.recordName == "demoRecord")
  }
  
  @Test func test_codes_ckRecordReference_array() throws {
    let reference1 = CKRecord.Reference(recordID: .init(recordName: "demoRecord1"), action: .none)
    let reference2 = CKRecord.Reference(recordID: .init(recordName: "demoRecord2"), action: .none)
    let sut = ValueStore(values: [
      "recordReferenceArrayKey": [reference1, reference2]
    ])
    let data = try JSONEncoder().encode(sut)
    let outcome = try JSONDecoder().decode(ValueStore.self, from: data)
    let references = outcome["recordReferenceArrayKey"] as? [CKRecord.Reference]
    #expect(references![0].recordID.recordName == "demoRecord1")
    #expect(references![1].recordID.recordName == "demoRecord2")
  }
  
  // MARK: - Error and invalid data handling
  
  @Test func test_throws_on_invalid_data_type() {
    let brokenTypeJson = "[{\"value\":42,\"key\":\"intKey\",\"type\":\"BrokenType\"}]"
    let data = brokenTypeJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(ValueStore.self, from: data)
    } catch {
      let dataCorruptedError = error as! DecodingError
      switch dataCorruptedError {
      case .dataCorrupted(let context):
        #expect(context.debugDescription == "Invalid data type: BrokenType")
      default:
        Issue.record("Unexpected error: \(dataCorruptedError)")
      }
    }
  }
  
  @Test func test_throws_on_invalid_nsnumber_data() {
    let brokenTypeJson = "[{\"value\":\"deadbeef\",\"key\":\"intKey\",\"type\":\"nsNumber\"}]"
    let data = brokenTypeJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(ValueStore.self, from: data)
    } catch {
      let dataCorruptedError = error as! DecodingError
      switch dataCorruptedError {
      case .dataCorrupted(let context):
        #expect(context.debugDescription == "Invalid NSNumber value in source data")
      default:
        Issue.record("Unexpected error: \(dataCorruptedError)")
      }
    }
  }
  
  @Test func test_throws_on_invalid_nsstring_data() {
    let brokenTypeJson = "[{\"value\":\"deadbeef\",\"key\":\"intKey\",\"type\":\"nsString\"}]"
    let data = brokenTypeJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(ValueStore.self, from: data)
    } catch {
      let dataCorruptedError = error as! DecodingError
      switch dataCorruptedError {
      case .dataCorrupted(let context):
        #expect(context.debugDescription == "Invalid NSString value in source data")
      default:
        Issue.record("Unexpected error: \(dataCorruptedError)")
      }
    }
  }
  
  @Test func test_throws_on_invalid_nsdate_data() {
    let brokenTypeJson = "[{\"value\":\"deadbeef\",\"key\":\"dateKey\",\"type\":\"nsDate\"}]"
    let data = brokenTypeJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(ValueStore.self, from: data)
    } catch {
      let dataCorruptedError = error as! DecodingError
      switch dataCorruptedError {
      case .dataCorrupted(let context):
        #expect(context.debugDescription == "Invalid NSDate value in source data")
      default:
        Issue.record("Unexpected error: \(dataCorruptedError)")
      }
    }
  }
  
  @Test func test_throws_on_invalid_nsdata_data() {
    let brokenTypeJson = "[{\"value\":\"deadbeef\",\"key\":\"dataKey\",\"type\":\"nsData\"}]"
    let data = brokenTypeJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(ValueStore.self, from: data)
    } catch {
      let dataCorruptedError = error as! DecodingError
      switch dataCorruptedError {
      case .dataCorrupted(let context):
        #expect(context.debugDescription == "Invalid NSData value in source data")
      default:
        Issue.record("Unexpected error: \(dataCorruptedError)")
      }
    }
  }
  
  @Test func test_throws_on_invalid_location_data() {
    let brokenTypeJson = "[{\"value\":\"deadbeef\",\"key\":\"dataKey\",\"type\":\"clLocation\"}]"
    let data = brokenTypeJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(ValueStore.self, from: data)
    } catch {
      let dataCorruptedError = error as! DecodingError
      switch dataCorruptedError {
      case .dataCorrupted(let context):
        #expect(context.debugDescription == "Invalid CLLocation value in source data")
      default:
        Issue.record("Unexpected error: \(dataCorruptedError)")
      }
    }
  }
  
  @Test func test_throws_on_invalid_ckRecordReference_data() {
    let brokenTypeJson = "[{\"value\":\"deadbeef\",\"key\":\"dataKey\",\"type\":\"ckRecordReference\"}]"
    let data = brokenTypeJson.data(using: .utf8)!
    do {
      let _ = try JSONDecoder().decode(ValueStore.self, from: data)
    } catch {
      let dataCorruptedError = error as! DecodingError
      switch dataCorruptedError {
      case .dataCorrupted(let context):
        #expect(context.debugDescription == "Invalid CKRecord.Reference value in source data")
      default:
        Issue.record("Unexpected error: \(dataCorruptedError)")
      }
    }
  }
  
  @Test func test_invalid_ckAsset_url() {
    // CKAsset API says that “if the system can’t create the asset” (and I’d expect
    // the URL pointing to nonexistent file to trigger this), the return value
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
    #expect(asset!.fileURL!.lastPathComponent == "textFile.txt")
  }
}
