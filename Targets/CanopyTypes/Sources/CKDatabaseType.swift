import CloudKit

public protocol CKDatabaseType {
  var debugDescription: String { get }
  func add(_ operation: CKDatabaseOperation)
}
