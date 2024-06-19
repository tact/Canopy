import CanopyTypes
import CloudKit
import Foundation

/// Canopy API provider for CKDatabase.
///
/// [CKDatabase](https://developer.apple.com/documentation/cloudkit/ckdatabase)
/// is the representation for containers of your app’s records and record zones in the cloud. You interact with CKDatabase
/// to store and obtain `CKRecord` objects that represent your app’s data.
///
/// Methods of this protocol have a preferred shorthand way of calling them via a protocol extension,
/// which lets you skip specifying some parameters and provides reasonable default values for them.
public protocol CKDatabaseAPIType: Sendable {
  
  typealias PerRecordProgressBlock = @Sendable (CKRecord, Double) -> Void
  typealias PerRecordIDProgressBlock = @Sendable (CKRecord.ID, Double) -> Void

  /// See ``CKDatabaseAPIType/queryRecords(with:in:resultsLimit:qualityOfService:)`` for preferred way of calling this API.
  func queryRecords(
    with query: CKQuery,
    in zoneID: CKRecordZone.ID?,
    resultsLimit: Int?,
    qos: QualityOfService
  ) async -> Result<[CKRecord], CKRecordError>

  /// See ``CKDatabaseAPIType/modifyRecords(saving:deleting:perRecordProgressBlock:qualityOfService:)`` for preferred way of calling this API.
  func modifyRecords(
    saving recordsToSave: [CKRecord]?,
    deleting recordIDsToDelete: [CKRecord.ID]?,
    perRecordProgressBlock: PerRecordProgressBlock?,
    qos: QualityOfService
  ) async -> Result<ModifyRecordsResult, CKRecordError>

  /// See ``CKDatabaseAPIType/deleteRecords(with:in:qualityOfService:)`` for preferred way of calling this API.
  func deleteRecords(
    with query: CKQuery,
    in zoneID: CKRecordZone.ID?,
    qos: QualityOfService
  ) async -> Result<ModifyRecordsResult, CKRecordError>
  
  /// See ``CKDatabaseAPIType/fetchRecords(with:desiredKeys:perRecordIDProgressBlock:qualityOfService:)`` for preferred way of calling this API.
  func fetchRecords(
    with recordIDs: [CKRecord.ID],
    desiredKeys: [CKRecord.FieldKey]?,
    perRecordIDProgressBlock: PerRecordIDProgressBlock?,
    qos: QualityOfService
  ) async -> Result<FetchRecordsResult, CKRecordError>

  /// See ``CKDatabaseAPIType/modifyZones(saving:deleting:qualityOfService:)`` for preferred way of calling this API.
  func modifyZones(
    saving recordZonesToSave: [CKRecordZone]?,
    deleting recordZoneIDsToDelete: [CKRecordZone.ID]?,
    qos: QualityOfService
  ) async -> Result<ModifyZonesResult, CKRecordZoneError>

  /// See ``CKDatabaseAPIType/fetchZones(with:qualityOfService:)`` for preferred way of calling this API.
  func fetchZones(
    with recordZoneIDs: [CKRecordZone.ID],
    qos: QualityOfService
  ) async -> Result<[CKRecordZone], CKRecordZoneError>
  
  /// See ``CKDatabaseAPIType/fetchAllZones(qualityOfService:)`` for preferred way of calling this API.
  func fetchAllZones(
    qos: QualityOfService
  ) async -> Result<[CKRecordZone], CKRecordZoneError>
  
  /// See ``CKDatabaseAPIType/modifySubscriptions(saving:deleting:qualityOfService:)`` for preferred way of calling this API.
  func modifySubscriptions(
    saving subscriptionsToSave: [CKSubscription]?,
    deleting subscriptionIDsToDelete: [CKSubscription.ID]?,
    qos: QualityOfService
  ) async -> Result<ModifySubscriptionsResult, CKSubscriptionError>
  
  /// See ``CKDatabaseAPIType/fetchDatabaseChanges(qualityOfService:)`` for preferred way of calling this API.
  func fetchDatabaseChanges(
    qos: QualityOfService
  ) async -> Result<FetchDatabaseChangesResult, CanopyError>

  /// See ``CKDatabaseAPIType/fetchZoneChanges(recordZoneIDs:fetchMethod:qualityOfService:)`` for preferred way of calling this API.
  func fetchZoneChanges(
    recordZoneIDs: [CKRecordZone.ID],
    fetchMethod: FetchZoneChangesMethod,
    qos: QualityOfService
  ) async -> Result<FetchZoneChangesResult, CanopyError>
}
