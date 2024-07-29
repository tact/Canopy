import CloudKit

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
//    case ckAsset
//    case ckRecordReference
//    case clLocation
//    case data
//    case date
    case double
//    case float
    case int
    case int16
    case int32
    case int64
    case int8
    
    // cannot support nsArray because keyed container only unarchiving arrays
    // when arrays contain one specific non-protocol type.
//    case nsArray
    
//    case nsData
//    case nsDate
    case nsNumber
//    case nsString
    case string
    case uint
    case uint16
    case uint32
    case uint64
    case uint8
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    for (key, value) in values {
      var nestedContainer = container.nestedContainer(keyedBy: CodingKeys.self)
      #warning("Remove the debug print")
      print("Key: \(key), value: \(value)")
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
    } else if let numberValue = value as? NSNumber {
      try container.encode(DataType.nsNumber.rawValue, forKey: .type)
      let data = try NSKeyedArchiver.archivedData(
        withRootObject: numberValue,
        requiringSecureCoding: true
      )
      try container.encode(data, forKey: .value)
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
    case .bool:
      return try container.decode(Bool.self, forKey: .value)
    case .string:
      return try container.decode(String.self, forKey: .value)
    case .double:
      return try container.decode(Double.self, forKey: .value)
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
    case .array:
      // todo
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
  /// Typically number and string values are cast to corresponding Swift types. This is fine
  /// for regular use, but in unit tests, we do want to also cover the NSType code paths.
  /// So this prefix of the key ignores the Swift types and lets the coding happen via
  /// the relevant NSType.
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
