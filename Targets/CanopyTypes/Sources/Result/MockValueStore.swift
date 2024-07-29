import CloudKit

/// A key-value store for values that are permissible to have as values stored in a CKRecord.
///
/// The primary use for this type is static mocks to back `MockCanopyResultRecord`
/// encrypted and non-encrypted value store.
///
/// The sendability cannot be enforced by the compiler, because some values may actually
/// be mutable, and we can’t reasonably check for them being sendable here. Since this is
/// anyway meant to be just a testing tool that you construct with static immutable data,
/// we declare `@unchecked Sendable` here, and trust the call sites to
/// not do anything weird.
struct MockValueStore: CanopyRecordValueGetting, @unchecked Sendable {
  let values: [String: CKRecordValueProtocol]
  
  init(values: [String : CKRecordValueProtocol]) {
    self.values = values
  }
  
  subscript(_ key: String) -> (any CKRecordValueProtocol)? {
    values[key]
  }
}

extension MockValueStore: Codable {
  private enum CodingKeys: String, CodingKey {
    case key
    case type
    case value
  }
  
  private enum DataType: String {
    // https://developer.apple.com/documentation/cloudkit/ckrecordvalueprotocol
    case array
    case bool
    case ckAsset
    case ckRecordReference
    case clLocation
    case data
    case date
    case double
    case float
    case int
    case int16
    case int32
    case int64
    case int8
    case nsData
    case nsDate
    case nsNumber
    case nsString
    case string
    case uint
    case uint16
    case uint32
    case uint64
    case uint8
    
    // CKRecordValueProtocol also includes NSArray. However, MockValueStore
    // cannot support NSArray because keyed container only supports
    // unarchiving arrays when arrays contain one specific non-protocol type.
    //
    // NSArrays are bridged to Swift arrays, and coded and returned as
    // Swift arrays by MockValue store. There is `test_codes_nsArray` unit test
    // for this.
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    for (key, value) in values {
      var nestedContainer = container.nestedContainer(keyedBy: CodingKeys.self)
      try encodeOneValue(
        container: &nestedContainer,
        key: key,
        value: value
      )
    }
  }
  
  private func encodeOneValue(
    container: inout KeyedEncodingContainer<CodingKeys>,
    key: String? = nil,
    value: CKRecordValueProtocol
  ) throws {
    if let key {
      try container.encode(key, forKey: .key)
    }
    if let arrayValue = value as? Array<CKRecordValueProtocol> {
      try container.encode(DataType.array.rawValue, forKey: .type)
      var arrayContainer = container.nestedUnkeyedContainer(forKey: .value)
      for item in arrayValue {
        var arrayItemContainer = arrayContainer.nestedContainer(keyedBy: CodingKeys.self)
        try encodeOneValue(container: &arrayItemContainer, value: item)
      }
    } else if let stringValue = value as? String, !should_force_nsType(key: key) {
      try container.encode(DataType.string.rawValue, forKey: .type)
      try container.encode(stringValue, forKey: .value)
    } else if let boolValue = value as? Bool {
      try container.encode(DataType.bool.rawValue, forKey: .type)
      try container.encode(boolValue, forKey: .value)
    } else if let uint8Value = value as? UInt8, !should_force_nsType(key: key) {
      try container.encode(DataType.uint8.rawValue, forKey: .type)
      try container.encode(uint8Value, forKey: .value)
    } else if let uint16Value = value as? UInt16, !should_force_nsType(key: key) {
      try container.encode(DataType.uint16.rawValue, forKey: .type)
      try container.encode(uint16Value, forKey: .value)
    } else if let uint32Value = value as? UInt32, !should_force_nsType(key: key) {
      try container.encode(DataType.uint32.rawValue, forKey: .type)
      try container.encode(uint32Value, forKey: .value)
    } else if let uint64Value = value as? UInt64, !should_force_nsType(key: key) {
      try container.encode(DataType.uint64.rawValue, forKey: .type)
      try container.encode(uint64Value, forKey: .value)
    } else if let uintValue = value as? UInt, !should_force_nsType(key: key) {
      try container.encode(DataType.uint.rawValue, forKey: .type)
      try container.encode(uintValue, forKey: .value)
    } else if let int8Value = value as? Int8, !should_force_nsType(key: key) {
      try container.encode(DataType.int8.rawValue, forKey: .type)
      try container.encode(int8Value, forKey: .value)
    } else if let int16Value = value as? Int16, !should_force_nsType(key: key) {
      try container.encode(DataType.int16.rawValue, forKey: .type)
      try container.encode(int16Value, forKey: .value)
    } else if let int32Value = value as? Int32, !should_force_nsType(key: key) {
      try container.encode(DataType.int32.rawValue, forKey: .type)
      try container.encode(int32Value, forKey: .value)
    } else if let int64Value = value as? Int64, !should_force_nsType(key: key) {
      try container.encode(DataType.int64.rawValue, forKey: .type)
      try container.encode(int64Value, forKey: .value)
    } else if let intValue = value as? Int, !should_force_nsType(key: key) {
      try container.encode(DataType.int.rawValue, forKey: .type)
      try container.encode(intValue, forKey: .value)
    } else if let doubleValue = value as? Double, !should_force_nsType(key: key) {
      try container.encode(DataType.double.rawValue, forKey: .type)
      try container.encode(doubleValue, forKey: .value)
    } else if let floatValue = value as? Float, !should_force_nsType(key: key) {
      try container.encode(DataType.float.rawValue, forKey: .type)
      try container.encode(floatValue, forKey: .value)
    } else if let dataValue = value as? Data, !should_force_nsType(key: key) {
      try container.encode(DataType.data.rawValue, forKey: .type)
      try container.encode(dataValue, forKey: .value)
    } else if let numberValue = value as? NSNumber {
      try container.encode(DataType.nsNumber.rawValue, forKey: .type)
      let data = try NSKeyedArchiver.archivedData(
        withRootObject: numberValue,
        requiringSecureCoding: true
      )
      try container.encode(data, forKey: .value)
    } else if let nsStringValue = value as? NSString {
      try container.encode(DataType.nsString.rawValue, forKey: .type)
      let data = try NSKeyedArchiver.archivedData(
        withRootObject: nsStringValue,
        requiringSecureCoding: true
      )
      try container.encode(data, forKey: .value)
    } else if let dateValue = value as? Date, !should_force_nsType(key: key) {
      try container.encode(DataType.date.rawValue, forKey: .type)
      try container.encode(dateValue, forKey: .value)
    } else if let nsDataValue = value as? NSData {
      try container.encode(DataType.nsData.rawValue, forKey: .type)
      let data = try NSKeyedArchiver.archivedData(
        withRootObject: nsDataValue,
        requiringSecureCoding: true
      )
      try container.encode(data, forKey: .value)
    } else if let nsDateValue = value as? NSDate {
      try container.encode(DataType.nsDate.rawValue, forKey: .type)
      let data = try NSKeyedArchiver.archivedData(
        withRootObject: nsDateValue,
        requiringSecureCoding: true
      )
      try container.encode(data, forKey: .value)
    } else if let locationValue = value as? CLLocation {
      try container.encode(DataType.clLocation.rawValue, forKey: .type)
      let data = try NSKeyedArchiver.archivedData(
        withRootObject: locationValue,
        requiringSecureCoding: true
      )
      try container.encode(data, forKey: .value)
    } else if let referenceValue = value as? CKRecord.Reference {
      try container.encode(DataType.ckRecordReference.rawValue, forKey: .type)
      let data = try NSKeyedArchiver.archivedData(
        withRootObject: referenceValue,
        requiringSecureCoding: true
      )
      try container.encode(data, forKey: .value)
    } else if let assetValue = value as? CKAsset {
      // Since CKAsset is not codable or archivable, we just store its URL,
      // and recreate the asset with the URL when decoding.
      // Note that CKAsset URL-s are meant to be short-lived, so this won’t
      // be suitable for long-term archiving.
      guard let url = assetValue.fileURL else {
        // There is no way for code to end up here that I can think of,
        // since you can’t construct CKAssets with a missing fileURL.
        throw EncodingError.invalidValue(
          value,
          EncodingError.Context(
            codingPath: [CodingKeys.value],
            debugDescription: "Missing URL value for CKAsset"
          )
        )
      }
      try container.encode(DataType.ckAsset.rawValue, forKey: .type)
      try container.encode(url, forKey: .value)
    } else {
      // Maybe not necessary since the above matching is exhaustive
      // for CKRecordProtocol? Also not sure how to force a unit test
      // to hit this.
      throw EncodingError.invalidValue(
        value,
        EncodingError.Context(
          codingPath: [CodingKeys.value],
          debugDescription: "Unsupported value data type"
        )
      )
    }
  }
  
  private static func decodeOneValue(
    container: inout KeyedDecodingContainer<CodingKeys>
  ) throws -> CKRecordValueProtocol {
    let dataTypeString = try container.decode(String.self, forKey: .type)
    guard let dataType = DataType(rawValue: dataTypeString) else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: [CodingKeys.type],
          debugDescription: "Invalid data type: \(dataTypeString)"
        )
      )
    }
    switch dataType {
    case .int: return try container.decode(Int.self, forKey: .value)
    case .int8: return try container.decode(Int8.self, forKey: .value)
    case .int16: return try container.decode(Int16.self, forKey: .value)
    case .int32: return try container.decode(Int32.self, forKey: .value)
    case .int64: return try container.decode(Int64.self, forKey: .value)
    case .uint: return try container.decode(UInt.self, forKey: .value)
    case .uint8: return try container.decode(UInt8.self, forKey: .value)
    case .uint16: return try container.decode(UInt16.self, forKey: .value)
    case .uint32: return try container.decode(UInt32.self, forKey: .value)
    case .uint64: return try container.decode(UInt64.self, forKey: .value)
    case .bool: return try container.decode(Bool.self, forKey: .value)
    case .string: return try container.decode(String.self, forKey: .value)
    case .double: return try container.decode(Double.self, forKey: .value)
    case .float: return try container.decode(Float.self, forKey: .value)
    case .date: return try container.decode(Date.self, forKey: .value)
    case .data: return try container.decode(Data.self, forKey: .value)
    case .nsNumber:
      let numberData = try container.decode(Data.self, forKey: .value)
      if let numberValue = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSNumber.self, from: numberData) {
        return numberValue
      } else {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: [CodingKeys.value],
            debugDescription: "Invalid NSNumber value in source data"
          )
        )
      }
    case .nsString:
      let stringData = try container.decode(Data.self, forKey: .value)
      if let nsStringValue = try? NSKeyedUnarchiver.unarchivedObject(
        ofClass: NSString.self,
        from: stringData
      ) {
        return nsStringValue
      } else {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: [CodingKeys.value],
            debugDescription: "Invalid NSString value in source data"
          )
        )
      }
    case .nsDate:
      let dateData = try container.decode(Data.self, forKey: .value)
      if let nsDateValue = try? NSKeyedUnarchiver.unarchivedObject(
        ofClass: NSDate.self,
        from: dateData
      ) {
        return nsDateValue
      } else {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: [CodingKeys.value],
            debugDescription: "Invalid NSDate value in source data"
          )
        )
      }
    case .nsData:
      let dataData = try container.decode(Data.self, forKey: .value)
      if let nsDataValue = try? NSKeyedUnarchiver.unarchivedObject(
        ofClass: NSData.self,
        from: dataData
      ) {
        return nsDataValue
      } else {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: [CodingKeys.value],
            debugDescription: "Invalid NSData value in source data"
          )
        )
      }
    case .clLocation:
      let locationData = try container.decode(Data.self, forKey: .value)
      if let locationValue = try? NSKeyedUnarchiver.unarchivedObject(
        ofClass: CLLocation.self,
        from: locationData
      ) {
        return locationValue
      } else {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: [CodingKeys.value],
            debugDescription: "Invalid CLLocation value in source data"
          )
        )
      }
    case .ckRecordReference:
      let referenceData = try container.decode(Data.self, forKey: .value)
      if let referenceValue = try? NSKeyedUnarchiver.unarchivedObject(
        ofClass: CKRecord.Reference.self,
        from: referenceData
      ) {
        return referenceValue
      } else {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: [CodingKeys.value],
            debugDescription: "Invalid CKRecord.Reference value in source data"
          )
        )
      }
    case .ckAsset:
      let url = try container.decode(URL.self, forKey: .value)
      return CKAsset(fileURL: url)
    case .array:
      var array: [CKRecordValueProtocol] = []
      var arrayContainer = try container.nestedUnkeyedContainer(forKey: CodingKeys.value)
      while !arrayContainer.isAtEnd {
        var itemContainer = try arrayContainer.nestedContainer(keyedBy: CodingKeys.self)
        array.append(try decodeOneValue(container: &itemContainer))
      }
      return array as CKRecordValueProtocol
    }
  }
  
  /// Whether the value for this key should be treated as NSType (NSNumber, NSString etc).
  ///
  /// Meant to be used primarily as a unit testing tool, safe to ignore in real life.
  ///
  /// Typically number and string values are cast to corresponding Swift types. This is fine
  /// for regular use, but in unit tests, we do want to also cover the NSType code paths.
  /// So this prefix of the key ignores the Swift types and lets the coding happen via
  /// the relevant NSType.
  ///
  /// You could argue that all the NSType coding isn’t really necessary, but since those types
  /// are part of `CKRecordValueProtocol`, I thought it’s nice to also encode them
  /// according to their original type.
  private func should_force_nsType(key: String?) -> Bool {
    guard let key else { return false }
    return key.hasPrefix("_force_nstype")
  }
  
  init(from decoder: Decoder) throws {
    var _values: [String: CKRecordValueProtocol] = [:]
    var container = try decoder.unkeyedContainer()
    while !container.isAtEnd {
      var nestedContainer = try container.nestedContainer(keyedBy: CodingKeys.self)
      let key = try nestedContainer.decode(String.self, forKey: .key)
      let value = try MockValueStore.decodeOneValue(container: &nestedContainer)
      _values[key] = value
    }
    values = _values
  }
}
