import CloudKit

/// Shorthand versions of the functions. Protocol extension lets us specify default values.
public extension CKDatabaseAPIType {
  /// Fetch records based on their record ID-s.
  ///
  /// Note that the records can be of different record types, and live in different record zones. They only need to come
  /// from the same CloudKit database (you cannot fetch records across databases with the same API request).
  ///
  /// - Parameters:
  ///   - with: One or more record ID-s whose corresponding records you wish to fetch.
  ///   - desiredKeys: List of keys that should be populated for each fetched record. Limiting the keys
  ///   may decrease the download size and make it faster, especially if you exclude any `CKAsset` fields. Default value is `nil`,
  ///   instructing the system to fetch all keys. Specify an empty array to not populate any keys with values.
  ///   - perRecordIDProgressBlock: A closure that gets called with the download progress for each record ID.
  ///   May be useful to report download progress to the user, especially if you are fetching records with large assets.
  ///   Default is `nil`, meaning that download progress isn’t reported to you.
  ///   - qualityOfService: The desired quality of service of the request. Defaults to `.default` if not provided.
  ///
  /// - Returns:
  /// An array of records that were found and not found, or `CKRecordError` if there was an error with the request.
  func fetchRecords(
    with recordIDs: [CKRecord.ID],
    desiredKeys: [CKRecord.FieldKey]? = nil,
    perRecordIDProgressBlock: PerRecordIDProgressBlock? = nil,
    qualityOfService: QualityOfService = .default
  ) async -> Result<FetchRecordsResult, CKRecordError> {
    await fetchRecords(
      with: recordIDs,
      desiredKeys: desiredKeys,
      perRecordIDProgressBlock: perRecordIDProgressBlock,
      qos: qualityOfService
    )
  }
  
  /// Query for records.
  ///
  /// The query can be for one record type at a time, and all the records need to come from the same record zone.
  ///
  /// This function is backed by [CKQueryOperation](https://developer.apple.com/documentation/cloudkit/ckqueryoperation)
  /// which Canopy internally uses to actually execute the query. `CKQueryOperation` requires you to understand cursors and paging.
  /// Canopy implements this internally for you and returns a single full array of records in the end, even if CloudKit internally returned multiple pages.
  ///
  /// - Parameters:
  ///   - with: The `CKQuery` specifying your query. See [CloudKit documentation for CKQuery](https://developer.apple.com/documentation/cloudkit/ckquery)
  ///   about how to construct your query.
  ///   - in: The record zone ID to query the records from. or `nil` to use the default zone.
  ///   - qualityOfService: The desired quality of service of the request. Defaults to `.default` if not provided.
  ///
  /// - Returns:
  /// An array of records that matches the query, or `CKRecordError` if there was an error with the request. The returned array of records
  /// may be empty if the query was successful but there weren’t any records matching the query.
  func queryRecords(
    with query: CKQuery,
    in zoneID: CKRecordZone.ID?,
    qualityOfService: QualityOfService = .default
  ) async -> Result<[CKRecord], CKRecordError> {
    await queryRecords(
      with: query,
      in: zoneID,
      qos: qualityOfService
    )
  }
  
  /// Modify and delete records.
  ///
  /// This is the single method that you use for both record modification and deletion.
  ///
  /// - Parameters:
  ///   - saving: Array of `CKRecord` objects to save, or `nil` if you are not saving any records (you are only deleting).
  ///   - deleting: Array of record ID-s to delete, or `nil` if you are not deleting any records (you are only saving).
  ///   - perRecordProgressBlock: A closure that gets called with the upload progress for each record being saved.
  ///   May be useful to report upload progress to the user, especially if you are uploading records with large assets.
  ///   Default is `nil`, meaning that upload progress isn’t reported to you.
  ///   - qualityOfService: The desired quality of service of the request. Defaults to `.default` if not provided.
  ///
  /// - Returns:
  /// Records that were saved and record ID-s that were deleted, or `CKRecordError` if there was an error with the request. Note that
  /// the saved records likely have different metadata from what you gave to fhis function as input, as CloudKit updates
  /// the record timestamps and change tags when saving records.
  func modifyRecords(
    saving recordsToSave: [CKRecord]? = nil,
    deleting recordIDsToDelete: [CKRecord.ID]? = nil,
    perRecordProgressBlock: PerRecordProgressBlock? = nil,
    qualityOfService: QualityOfService = .default
  ) async -> Result<ModifyRecordsResult, CKRecordError> {
    await modifyRecords(
      saving: recordsToSave,
      deleting: recordIDsToDelete,
      perRecordProgressBlock: perRecordProgressBlock,
      qos: qualityOfService
    )
  }
  
  /// Delete records that match a query.
  ///
  /// Sometimes you need to delete records that match a query. You could do two operations: first, query for the records to
  /// get a list of their record ID-s, and then, issue a deletion request with those ID-s. This function is just a shorthand way
  /// of performing these two operations in one function call.
  ///
  /// - Parameters:
  ///   - query: Query for the records that you want to delete.
  ///   - in: record zone ID where you want to perform the query and deletion.
  ///   - qualityOfService: The desired quality of service of the request. Defaults to `.default` if not provided.
  ///
  /// - Returns:
  ///  Record ID-s that were deleted, or `CKRecordError` if there was an error with the deletion.
  func deleteRecords(
    with query: CKQuery,
    in zoneID: CKRecordZone.ID?,
    qualityOfService: QualityOfService = .default
  ) async -> Result<ModifyRecordsResult, CKRecordError> {
    await deleteRecords(
      with: query,
      in: zoneID,
      qos: qualityOfService
    )
  }

  /// Save, modify, and delete record zones.
  ///
  /// You use this function to create, modify, and delete custom record zones. This is only available in private and shared CloudKit databases.
  /// If you attempt to do this in the public database, you will receive an error.
  ///
  /// You need to create a record zone before you can save any records in that zone.
  ///
  /// Creating and modifying a record zone is idempotent. You can repeatedly instruct the system to create a zone with the same ID.
  /// If the zone already exists, this operation does nothing. If there are already records in the zone, those records are not affected.
  ///
  /// - Parameters:
  ///   - saving: an array of record zones to create or modify.
  ///   - deleting: an array of record zone ID-s to delete.
  ///   - qualityOfService: The desired quality of service of the request. Defaults to `.default` if not provided.
  ///
  /// - Returns:
  /// Modification result with arrays of modified and deleted zones, or `CKRecordZoneError` if there was an error.
  func modifyZones(
    saving recordZonesToSave: [CKRecordZone]? = nil,
    deleting recordZoneIDsToDelete: [CKRecordZone.ID]? = nil,
    qualityOfService: QualityOfService = .default
  ) async -> Result<ModifyZonesResult, CKRecordZoneError> {
    await modifyZones(
      saving: recordZonesToSave,
      deleting: recordZoneIDsToDelete,
      qos: qualityOfService
    )
  }

  /// Fetch record zones based on their ID-s.
  ///
  /// You may need to do this if you are interested in the zone capabilities.
  ///
  /// - Parameters:
  ///   - with: List of record zone ID-s whose zones you are interested in.
  ///   - qualityOfService: The desired quality of service of the request. Defaults to `.default` if not provided.
  ///
  /// - Returns:
  /// Array of record zones matching the given ID-s, or `CKRecordZoneError` if there was an error with your request.
  func fetchZones(
    with recordZoneIDs: [CKRecordZone.ID],
    qualityOfService: QualityOfService = .default
  ) async -> Result<[CKRecordZone], CKRecordZoneError> {
    await fetchZones(
      with: recordZoneIDs,
      qos: qualityOfService
    )
  }
  
  /// Fetch all record zones in private or shared CloudKit database.
  ///
  /// One very interesting use case for this function is when using record sharing. When you share records with someone,
  /// the zone containing the shared records will show up in the other user’s shared CloudKit database. It has the same name
  /// as originally specified, and indicates the zone owner.
  ///
  /// So, when your app uses record sharing and you fetch all zones in a shared database, you will get zones whose name is the same,
  /// but owner is different. The exact list of zones depends on which other users have shared records with the current user.
  /// You can then perform further requests in those zones.
  ///
  /// It is not known whether there are any limits to number of zones that you can have in your shared database. Fetching zone list does not
  /// implement any paging in CloudKit.
  ///
  /// - Parameters:
  ///   - qualityOfService: The desired quality of service of the request. Defaults to `.default` if not provided.
  ///
  /// - Returns:
  /// Array of all record zones in a given CloudKit database, or `CKRecordZoneError` if there was an error with the request.
  func fetchAllZones(
    qualityOfService: QualityOfService = .default
  ) async -> Result<[CKRecordZone], CKRecordZoneError> {
    await fetchAllZones(qos: qualityOfService)
  }
  
  /// Save or delete notification subscriptions.
  ///
  /// Notification subscriptions drive visible and invisible push notifications straight from CloudKit to your user’s device and your app.
  /// You should set up subscriptions if you want your users to be notified, or your app to react, whenever data changes on the cloud side.
  ///
  /// There are limits to what kind of subscriptions you can have. You use one of the concrete CKSubscription subclasses to create
  /// subscriptions: see [CKDatabaseSubscription](https://developer.apple.com/documentation/cloudkit/ckdatabasesubscription),
  /// [CKRecordZoneSubscription](https://developer.apple.com/documentation/cloudkit/ckrecordzonesubscription),
  /// [CKQuerySubscription.](https://developer.apple.com/documentation/cloudkit/ckquerysubscription)
  ///
  /// - Parameters:
  ///   - saving: Array of subscriptions to save.
  ///   - deleting: Array of subscription ID-s to delete.
  ///   - qualityOfService: The desired quality of service of the request. Defaults to `.default` if not provided.
  ///
  /// - Returns:
  /// Array of saved and deleted subscriptions, or `CKSubscriptionError` if there was an error with the request.
  func modifySubscriptions(
    saving subscriptionsToSave: [CKSubscription]? = nil,
    deleting subscriptionIDsToDelete: [CKSubscription.ID]? = nil,
    qualityOfService: QualityOfService = .default
  ) async -> Result<ModifySubscriptionsResult, CKSubscriptionError> {
    await modifySubscriptions(
      saving: subscriptionsToSave,
      deleting: subscriptionIDsToDelete,
      qos: qualityOfService
    )
  }
  
  /// Fetch changes that have happened in a given CKDatabase.
  ///
  /// Change-based fetching is a powerful way to work with CloudKit. See the chapter “Changes-based retrieving” in <doc:Three-methods-of-retrieving-records-from-CloudKit> for how it works.
  ///
  /// Fetching changes with Canopy is serialized. You can call this function multiple times and simultaneously. Only
  /// one change fetch request is processed at a time: later requests wait for earlier ones to finish.
  ///
  /// Fetching database changes interacts with the token store that you initialized Canopy with. See ``TokenStoreType`` for
  /// more info about token store.
  ///
  /// - Parameters:
  ///   - qualityOfService: The desired quality of service of the request. Defaults to `.default` if not provided.
  ///
  /// - Returns:
  /// A collection of zone ID-s that have changed, or `CanopyError` if there was an error with the request.
  func fetchDatabaseChanges(
    qualityOfService: QualityOfService = .default
  ) async -> Result<FetchDatabaseChangesResult, CanopyError> {
    await fetchDatabaseChanges(qos: qualityOfService)
  }

  /// Fetch changes that have happened in a given `CKRecordZone`.
  ///
  /// Change-based fetching is a powerful way to work with CloudKit. See the chapter “Changes-based retrieving” in <doc:Three-methods-of-retrieving-records-from-CloudKit> for how it works.
  ///
  /// Fetching changes with Canopy is serialized. You can call this function multiple times and simultaneously. Only
  /// one change fetch request is processed at a time: later requests wait for earlier ones to finish.
  ///
  /// Fetching record zone changes interacts with the token store that you initialized Canopy with. See ``TokenStoreType`` for
  /// more info about token store.
  ///
  /// - Parameters:
  ///   - recordZoneIDs: Array of record zone ID-s whose changes you wish to fetch.
  ///   - fetchMethod: You can populate some, none, or all of the record values when fetching changes.
  ///   If your records have large assets, it may make sense to exclude them with this parameter, so that your fetch happens
  ///   faster and your download size is smaller.
  ///   - qualityOfService: The desired quality of service of the request. Defaults to `.default` if not provided.
  ///
  /// - Returns:
  /// A collection of records and record ID-s that have changed, or `CanopyError` if there was an error with the request.
  func fetchZoneChanges(
    recordZoneIDs: [CKRecordZone.ID],
    fetchMethod: FetchZoneChangesMethod = .changeTokenAndAllData,
    qualityOfService: QualityOfService = .default
  ) async -> Result<FetchZoneChangesResult, CanopyError> {
    await fetchZoneChanges(
      recordZoneIDs: recordZoneIDs,
      fetchMethod: fetchMethod,
      qos: qualityOfService
    )
  }
}
