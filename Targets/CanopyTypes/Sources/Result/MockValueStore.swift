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
//    case array
//    case bool
//    case ckAsset
//    case ckRecordReference
//    case clLocation
//    case data
//    case date
    case double
//    case float
    case int
//    case int16
//    case int32
//    case int64
//    case int8
//    case nsArray
//    case nsData
//    case nsDate
    case nsNumber
//    case nsString
    case string
//    case uint
//    case uint16
//    case uint32
//    case uint64
//    case uint8
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    for (key, value) in values {
      var nestedContainer = container.nestedContainer(keyedBy: CodingKeys.self)
      #warning("Remove the debug print")
      print("Key: \(key), value: \(value)")
      try nestedContainer.encode(key, forKey: .key)
      if let stringValue = value as? String {
        try nestedContainer.encode(DataType.string.rawValue, forKey: .type)
        try nestedContainer.encode(stringValue, forKey: .value)
      } else if let intValue = value as? Int {
        try nestedContainer.encode(DataType.int.rawValue, forKey: .type)
        try nestedContainer.encode(intValue, forKey: .value)
      } else if let doubleValue = value as? Double {
        try nestedContainer.encode(DataType.double.rawValue, forKey: .type)
        try nestedContainer.encode(doubleValue, forKey: .value)
      } else if let numberValue = value as? NSNumber {
        // Does not seem to ever get here. Numbers are cast to
        // basic values successfully above. But will keep this code path
        // here anyway just in case.
        try nestedContainer.encode(DataType.nsNumber.rawValue, forKey: .type)
        let data = try NSKeyedArchiver.archivedData(withRootObject: numberValue, requiringSecureCoding: true)
        try nestedContainer.encode(data, forKey: .value)
      } else {
        throw EncodingError.invalidValue(
          value,
          EncodingError.Context(
            codingPath: [CodingKeys.value],
            debugDescription: "Unsupported value data type"
          )
        )
      }
    }
  }
  
  init(from decoder: Decoder) throws {
    var _values: [String: CKRecordValueProtocol] = [:]
    var container = try decoder.unkeyedContainer()
    while !container.isAtEnd {
      let nestedContainer = try container.nestedContainer(keyedBy: CodingKeys.self)
      let key = try nestedContainer.decode(String.self, forKey: .key)
      let dataTypeString = try nestedContainer.decode(String.self, forKey: .type)
      guard let dataType = DataType(rawValue: dataTypeString) else {
        throw DecodingError.dataCorrupted(
          DecodingError.Context(
            codingPath: [],
            debugDescription: "Invalid data type: \(dataTypeString)"
          )
        )
      }
      switch dataType {
      case .int:
        let intValue = try nestedContainer.decode(Int.self, forKey: .value)
        _values[key] = intValue
      case .string:
        let stringValue = try nestedContainer.decode(String.self, forKey: .value)
        _values[key] = stringValue
      case .double:
        let doubleValue = try nestedContainer.decode(Double.self, forKey: .value)
        _values[key] = doubleValue
      case .nsNumber:
        let numberData = try nestedContainer.decode(Data.self, forKey: .value)
        let numberValue = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSNumber.self, from: numberData)
        _values[key] = numberValue
      }
    }
    values = _values
  }
}
