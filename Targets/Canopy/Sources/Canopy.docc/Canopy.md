# ``Canopy``

Write better, testable CloudKit apps.

Canopy helps you write better, more testable CloudKit apps. It isolates the CloudKit dependency so you can write fast and reliable tests for your CloudKit-related features, and implements standard CloudKit-related behaviors.

Canopy is built as part of [Tact](https://justtact.com). The Canopy source code and installation instructions (including the source for this site) are available on [GitHub](https://github.com/Tact/Canopy).

## Topics

### About Canopy

- <doc:Motivation-and-scope>
- <doc:Testable-CloudKit-apps-with-Canopy>
- <doc:Features-and-behaviors>
- <doc:Thoughts-example-app>

### CloudKit articles

- <doc:Three-methods-of-retrieving-records-from-CloudKit>
- <doc:Why-use-CloudKit>
- <doc:iCloud-Advanced-Data-Protection>

### Main Canopy API

- ``CanopyType``
- ``Canopy/Canopy``

### Settings

- ``CanopySettingsType``
- ``CanopySettings``
- ``RequestBehavior``

### Token store

Token store manages client-side storage of database and zone change tokens. You only need to use TokenStore if you use the ``CKDatabaseAPIType/fetchDatabaseChanges(qualityOfService:)`` or ``CKDatabaseAPIType/fetchZoneChanges(recordZoneIDs:fetchMethod:qualityOfService:)`` Canopy APIs.

- ``TokenStoreType``
- ``TestTokenStore``
- ``UserDefaultsTokenStore``

### CKContainer API

- ``CKContainerAPIType``
- ``CKContainerAPIError``

### CKDatabase API

- ``CKDatabaseAPIType``
- ``FetchZoneChangesMethod``

### Request results

- ``CanopyResultRecordType``
- ``ModifyRecordsResult``
- ``FetchDatabaseChangesResult``
- ``FetchRecordsResult``
- ``ModifyZonesResult``
- ``ModifySubscriptionsResult``
- ``FetchZoneChangesResult``
- ``DeletedCKRecord``
