import CloudKit

public protocol CKDatabaseType {
  var debugDescription: String { get }
  var databaseScope: CKDatabase.Scope { get }
  func add(_ operation: CKDatabaseOperation)
}
