import CloudKit

public extension CKRecordZone.ID {
  var ckDatabaseScope: CKDatabase.Scope {
    (ownerName == CKCurrentUserDefaultName) ? .private : .shared
  }

  func ckDatabase(forContainerIdentifier cloudKitContainerIdentifier: String) -> CKDatabase {
    CKContainer(identifier: cloudKitContainerIdentifier).database(with: ckDatabaseScope)
  }
}
