import CanopyTypes
import CloudKit
import Foundation

/// Canopy overlay to the CKDatabase API.
public protocol CKDatabaseAPIType {
  typealias PerRecordProgressBlock = (CKRecord, Double) -> Void
  typealias PerRecordIDProgressBlock = (CKRecord.ID, Double) -> Void
  
  func queryRecords(
    with query: CKQuery,
    in zoneID: CKRecordZone.ID?,
    qualityOfService: QualityOfService
  ) async -> Result<[CKRecord], CKRecordError>
  
  func modifyRecords(
    saving recordsToSave: [CKRecord]?,
    deleting recordIDsToDelete: [CKRecord.ID]?,
    perRecordProgressBlock: PerRecordProgressBlock?,
    qualityOfService: QualityOfService
  ) async -> Result<ModifyRecordsResult, CKRecordError>
  
  func deleteRecords(
    with query: CKQuery,
    in zoneID: CKRecordZone.ID?,
    qualityOfService: QualityOfService
  ) async -> Result<ModifyRecordsResult, CKRecordError>
  
  func fetchRecords(
    with recordIDs: [CKRecord.ID],
    desiredKeys: [CKRecord.FieldKey]?,
    perRecordIDProgressBlock: PerRecordIDProgressBlock?,
    qualityOfService: QualityOfService
  ) async -> Result<FetchRecordsResult, CKRecordError>

  func modifyZones(
    saving recordZonesToSave: [CKRecordZone]?,
    deleting recordZoneIDsToDelete: [CKRecordZone.ID]?,
    qualityOfService: QualityOfService
  ) async -> Result<ModifyZonesResult, CKRecordZoneError>

  func fetchZones(
    with recordZoneIDs: [CKRecordZone.ID],
    qualityOfService: QualityOfService
  ) async -> Result<[CKRecordZone], CKRecordZoneError>
  
  func fetchAllZones(
    qualityOfService: QualityOfService
  ) async -> Result<[CKRecordZone], CKRecordZoneError>
  
  func modifySubscriptions(
    saving subscriptionsToSave: [CKSubscription]?,
    deleting subscriptionIDsToDelete: [CKSubscription.ID]?,
    qualityOfService: QualityOfService
  ) async -> Result<ModifySubscriptionsResult, CKSubscriptionError>
  
  func fetchDatabaseChanges(
    qualityOfService: QualityOfService
  ) async -> Result<FetchDatabaseChangesResult, CanopyError>

  func fetchZoneChanges(
    recordZoneIDs: [CKRecordZone.ID],
    fetchMethod: FetchZoneChangesMethod,
    qualityOfService: QualityOfService
  ) async -> Result<FetchZoneChangesResult, CanopyError>
}
