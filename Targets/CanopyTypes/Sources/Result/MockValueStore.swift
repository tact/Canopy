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
    case String
    case Int
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    for (key, value) in values {
      var nestedContainer = container.nestedContainer(keyedBy: CodingKeys.self)
      #warning("Remove the debug print")
      print("Key: \(key), value: \(value)")
      try nestedContainer.encode(key, forKey: .key)
      if let stringValue = value as? String {
        try nestedContainer.encode(DataType.String.rawValue, forKey: .type)
        try nestedContainer.encode(stringValue, forKey: .value)
      } else if let intValue = value as? Int {
        try nestedContainer.encode(DataType.Int.rawValue, forKey: .type)
        try nestedContainer.encode(intValue, forKey: .value)
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
      case .Int:
        let intValue = try nestedContainer.decode(Int.self, forKey: .value)
        _values[key] = intValue
      case .String:
        let stringValue = try nestedContainer.decode(String.self, forKey: .value)
        _values[key] = stringValue
      }
    }
    values = _values
  }
}
