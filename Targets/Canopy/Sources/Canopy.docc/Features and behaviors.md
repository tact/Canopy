# Features and behaviors

Canopy implements several standard features and behaviors for working with CloudKit.

## Overview

You need to build out some behaviors when working with CloudKit. Canopy does a lot of this work for you, and is designed to work in a way that is appropriate for most apps, while adding configuration and hooks to modify the behavior where needed.

This article describes the behaviors that Canopy implements.

## CKQueryOperation paging and cursor handling

[CKQueryOperation](https://developer.apple.com/documentation/cloudkit/ckqueryoperation) returns records in response to a query. If the number is large, the operation also returns a cursor, and you must re-run the operation with this cursor to get the next page of the results, and keep repeating this process until no cursor is returned, which means that you have received all results.

The maximum number of records returned per page isn’t specified and may change over time. It has previously been around a few hundred records per response. You shouldn’t rely on this being any specific number.

Canopy’s corresponding API ``CKDatabaseAPIType/queryRecords(with:in:resultsLimit:qualityOfService:)`` handles all of the above for you, so you never need to implement cursors. You run the query, and in the end, you get back a single set of results, no matter how many CloudKit queries it actually took to get them. Canopy internally handles all the cursors and paging. There is currently no behavior in Canopy to just return one page.

With queries that return multiple pages, it would be nice to know how many pages in total will be returned, and inform the user of the progress for a better user experience. Unfortunately, this is currently not possible due to how CloudKit and its cloud service is internally built. In an Ask Apple session in December 2022, I asked whether it is possible to receive a count of the entire result set in this scenario, and got this comment from Apple staff:

> Unfortunately this is not possible as it would require a separate count index, which is not currently supported. Otherwise, the system would have to iterate over the entire relevant index in order to obtain the count, defeating the purpose of paginating.

## Record save policy and record versioning

In distributed systems, many people and devices can modify the same record at different times. It’s important to think about how conflicts in the data are handled.

CloudKit lets you choose between several behaviors by setting the [savePolicy](https://developer.apple.com/documentation/cloudkit/ckmodifyrecordsoperation/1447488-savepolicy) value on [CKModifyRecordsOperation](https://developer.apple.com/documentation/cloudkit/ckmodifyrecordsoperation). Canopy always sets this value to `changedKeys`.

The `changedKeys` value of `savePolicy` expresses a simple “latest wins” policy which is appropriate for Tact and many other CloudKit apps. Any modifications to the record simply overwrite the previous values.

Here’s a simple example. Imagine that in stored CloudKit data, you have a record with type `TestRecord`, name `testRecordName` and two values, `key1=value1` and `key2=value2`.

You now run this code:

```swift
let testRecord = CKRecord(recordType: "TestRecord", recordID: CKRecord.ID(recordName: "testRecordName"))
testRecord["key1"] = "newValue"
let result = await canopy.databaseAPI(usingDatabaseScope: .private).modifyRecords(saving: [testRecord])
```

After running this, `testRecord` in the cloud will have two values, `key1=newValue` and `key2=value2`. The value of `key2` did not change because you did not modify it with this operation.

If there is a need for other behaviors that consider the server change tag, these can be added in future Canopy versions.

Note that regardless of the save policy, CloudKit always returns a [recordChangeTag](https://developer.apple.com/documentation/cloudkit/ckrecord/1462195-recordchangetag) with all your CKRecords. This indicates the version of a given record. If you so choose, you can store this, and compare it to the `recordChangeTag` returned in future requests for the same record, to understand whether a record has changed on the cloud side.

## Batching modification requests to smaller batches

If you run a [CKModifyRecordsOperation](https://developer.apple.com/documentation/cloudkit/ckmodifyrecordsoperation) with a dataset that is too large, you may get the [limitExceeded](https://developer.apple.com/documentation/cloudkit/ckerror/code/limitexceeded) error. This indicates that you must split your operation in half and try again.

Canopy implements this automatically. You can submit an arbitrarily large modification request. Canopy splits it into reasonable initial batches, and splits those further into smaller ones if needed.

If you’d like, you can turn this behavior off by setting ``CanopySettingsType/autoBatchTooLargeModifyOperations`` to `false` in Canopy settings. You will then get the `limitExceeded` error and can implement the reaction to it in your own code.

## Auto-retrying modification for retriable errors

`CKModifyRecordsOperation` may return an error that indicates you can retry the operation after a while. Two common cases where it happens is flaky network conditions and multiple people modifying the same CloudKit zone at the same time (e.g. multiple users adding content to the same zone and parent record).

Canopy implements automatic retry and keeps trying up to 3 times. With retriable errors, CloudKit also indicates the appropriate timeout after which to retry, by setting the [retryAfterSeconds](https://developer.apple.com/documentation/cloudkit/ckerror/2299866-retryafterseconds) property of the CKError. Canopy uses this timeout value and retries after the indicated number of seconds. If the request still doesn’t go through after 3 tries, Canopy gives up and returns the error.

You can turn off the auto-retry by setting ``CanopySettingsType/autoRetryForRetriableErrors`` to `false` in Canopy settings. Canopy then returns the error immediately after the first failed attempt.

## Serializing database and zone change fetches

Fetching database and zone changes with change tokens is a powerful way to understand what data has changed in CloudKit. Read more about this technique in <doc:Three-methods-of-retrieving-records-from-CloudKit> under “Changes-based retrieving”. The Thoughts example app also demonstrates this approach.

When using this technique, you should have only one change request of a given type “in flight” at any given time. If you run two simultaneous requests to receive zone changes for the same zone, you may receive back two different change tokens and two different sets of records. It’s difficult to reason about which of them is the “right” one.

Canopy serializes the database and zone fetches and makes sure only one request of a given type is in flight at any given time. You may still ask it to run many requests, but execution of later requests will wait for earlier ones to finish.

## Account status stream for current user

Observing account status changes for the current user is a multi-step process with the system CloudKit API. You must listen to [CKAccountChanged](https://developer.apple.com/documentation/foundation/nsnotification/name/1399172-ckaccountchanged) notifications. Whenever you get one, you need to use the [accountStatus](https://developer.apple.com/documentation/cloudkit/ckcontainer/1399180-accountstatus) API of `CKContainer` to find out what the actual status is.

Canopy does all of this work internally, and provides you a simple stream of the account statuses. See ``CKContainerAPIType/accountStatusStream``.
