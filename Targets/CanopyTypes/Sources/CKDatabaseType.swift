import CloudKit

public protocol CKDatabaseType {
  func add(_ operation: CKDatabaseOperation)
}
