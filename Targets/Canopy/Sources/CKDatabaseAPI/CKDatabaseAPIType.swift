import CanopyTypes
import CloudKit
import Foundation

/// Canopy overlay to the CKDatabase API.
///
/// FIXME: note how qos is written here, but qualityOfService in the shorthand. This is to disambiguate the APIs.
public protocol CKDatabaseAPIType {
  typealias PerRecordProgressBlock = (CKRecord, Double) -> Void
  typealias PerRecordIDProgressBlock = (CKRecord.ID, Double) -> Void
  
  func queryRecords(
    with query: CKQuery,
    in zoneID: CKRecordZone.ID?,
    qos: QualityOfService
  ) async -> Result<[CKRecord], CKRecordError>
  
  func modifyRecords(
    saving recordsToSave: [CKRecord]?,
    deleting recordIDsToDelete: [CKRecord.ID]?,
    perRecordProgressBlock: PerRecordProgressBlock?,
    qos: QualityOfService
  ) async -> Result<ModifyRecordsResult, CKRecordError>
  
  func deleteRecords(
    with query: CKQuery,
    in zoneID: CKRecordZone.ID?,
    qos: QualityOfService
  ) async -> Result<ModifyRecordsResult, CKRecordError>
  
  func fetchRecords(
    with recordIDs: [CKRecord.ID],
    desiredKeys: [CKRecord.FieldKey]?,
    perRecordIDProgressBlock: PerRecordIDProgressBlock?,
    qos: QualityOfService
  ) async -> Result<FetchRecordsResult, CKRecordError>

  func modifyZones(
    saving recordZonesToSave: [CKRecordZone]?,
    deleting recordZoneIDsToDelete: [CKRecordZone.ID]?,
    qos: QualityOfService
  ) async -> Result<ModifyZonesResult, CKRecordZoneError>

  func fetchZones(
    with recordZoneIDs: [CKRecordZone.ID],
    qos: QualityOfService
  ) async -> Result<[CKRecordZone], CKRecordZoneError>
  
  func fetchAllZones(
    qos: QualityOfService
  ) async -> Result<[CKRecordZone], CKRecordZoneError>
  
  func modifySubscriptions(
    saving subscriptionsToSave: [CKSubscription]?,
    deleting subscriptionIDsToDelete: [CKSubscription.ID]?,
    qos: QualityOfService
  ) async -> Result<ModifySubscriptionsResult, CKSubscriptionError>
  
  func fetchDatabaseChanges(
    qos: QualityOfService
  ) async -> Result<FetchDatabaseChangesResult, CanopyError>

  func fetchZoneChanges(
    recordZoneIDs: [CKRecordZone.ID],
    fetchMethod: FetchZoneChangesMethod,
    qos: QualityOfService
  ) async -> Result<FetchZoneChangesResult, CanopyError>
}
