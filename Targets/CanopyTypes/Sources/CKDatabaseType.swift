import CloudKit

public protocol CKDatabaseType: Sendable {
  func add(_ operation: CKDatabaseOperation)
}
