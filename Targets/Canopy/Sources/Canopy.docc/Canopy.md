# ``Canopy``

Write better, testable CloudKit apps.

_⚠️ This documentation site is currently half-broken, and does not include documentation for several Canopy types. Conceptual documentation works fine. Canopy types and code are spread across several Swift Package Manager modules, and DocC does not easily support this scenario out of the box, for generating a documentation site. [Work is in progress](https://forums.swift.org/t/are-there-updates-on-using-swift-docc-with-multiple-targets/73072) to address this._

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

- ``/CanopyTypes/CanopyType``
- ``Canopy/Canopy``
- ``/CanopyTestTools/MockCanopy``

### Settings

- ``/CanopyTypes/CanopySettingsType``
- ``/CanopyTypes/CanopySettings``
- ``RequestBehavior``

### Token store

Token store manages client-side storage of database and zone change tokens. You only need to use TokenStore if you use the ``CKDatabaseAPIType/fetchDatabaseChanges(qualityOfService:)`` or ``CKDatabaseAPIType/fetchZoneChanges(recordZoneIDs:fetchMethod:qualityOfService:)`` Canopy APIs.

- ``TokenStoreType``
- ``TestTokenStore``
- ``UserDefaultsTokenStore``

### CKContainer API

- ``/CanopyTypes/CKContainerAPIType``
- ``/CanopyTypes/CKContainerAPIError``

### CKDatabase API

- ``/CanopyTypes/CKDatabaseAPIType``
- ``/CanopyTypes/FetchZoneChangesMethod``

### Request results

- ``/CanopyTypes/ModifyRecordsResult``
- ``/CanopyTypes/FetchDatabaseChangesResult``
- ``/CanopyTypes/FetchRecordsResult``
- ``/CanopyTypes/ModifyZonesResult``
- ``/CanopyTypes/ModifySubscriptionsResult``
- ``/CanopyTypes/FetchZoneChangesResult``
- ``/CanopyTypes/DeletedCKRecord``
