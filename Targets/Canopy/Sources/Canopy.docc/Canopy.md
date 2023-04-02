# ``Canopy``

Write better, testable CloudKit apps.

Canopy helps you write better, more testable CloudKit apps. It isolates the CloudKit dependency so you can write fast and reliable tests for your CloudKit-related features, and implements standard CloudKit-related behaviors.

Canopy was built, and continues to be built, as part of [Tact app.](https://justtact.com)

Canopy source and installation instructions, including the source for this site, are [available on GitHub.](https://github.com/Tact/Canopy)

## Topics

### About Canopy

- <doc:Motivation-and-scope>
- <doc:Features-and-behaviors>
- <doc:Testable-CloudKit-apps-with-Canopy>
- <doc:Thoughts-example-app>

### CloudKit articles

- <doc:Three-methods-of-retrieving-records-from-CloudKit>
- <doc:Why-use-CloudKit>
- <doc:iCloud-Advanced-Data-Protection>

### Main Canopy API

- ``CanopyType``
- ``Canopy/Canopy``
- ``MockCanopy``

### Settings

- ``CanopySettingsType``
- ``CanopySettings``
- ``RequestBehavior``

### Token store

Token store manages client-side storage of database and zone change tokens. You only need to use TokenStore if you use the ``CKDatabaseAPIType/fetchDatabaseChanges(qualityOfService:)-1eag`` or ``CKDatabaseAPIType/fetchZoneChanges(recordZoneIDs:fetchMethod:qualityOfService:)-4any`` API-s.

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

- ``ModifyRecordsResult``
- ``FetchDatabaseChangesResult``
- ``FetchRecordsResult``
- ``ModifyZonesResult``
- ``ModifySubscriptionsResult``
- ``FetchZoneChangesResult``
- ``FetchRecordChangesResult``
- ``DeletedCKRecord``
