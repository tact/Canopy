import CloudKit

public struct DeletedCKRecord: Codable, Equatable {
  private let typeString: String
  private let recordName: String
  private let zoneName: String
  private let zoneOwnerName: String

  public var recordID: CKRecord.ID {
    CKRecord.ID(recordName: recordName, zoneID: CKRecordZone.ID(zoneName: zoneName, ownerName: zoneOwnerName))
  }

  public var recordType: CKRecord.RecordType {
    typeString as CKRecord.RecordType
  }

  public init(recordID: CKRecord.ID, recordType: CKRecord.RecordType) {
    typeString = recordType
    recordName = recordID.recordName
    zoneName = recordID.zoneID.zoneName
    zoneOwnerName = recordID.zoneID.ownerName
  }
}
