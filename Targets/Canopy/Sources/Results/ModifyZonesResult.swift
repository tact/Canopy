import CloudKit
import Foundation

public struct ModifyZonesResult: Equatable, Sendable {
  public let savedZones: [CKRecordZone]
  public let deletedZoneIDs: [CKRecordZone.ID]
  
  public init(savedZones: [CKRecordZone], deletedZoneIDs: [CKRecordZone.ID]) {
    self.savedZones = savedZones
    self.deletedZoneIDs = deletedZoneIDs
  }
}
