# Motivation and scope

A summary of the motivation, technical design goals, and scope of the Canopy project.

## Overview

[CloudKit](https://developer.apple.com/icloud/cloudkit/) is a set of Apple APIs that let you store your app data in iCloud. It was introduced at [WWDC 14.](https://www.wwdcnotes.com/notes/wwdc14/208/) Since then, it’s gained a few new features, but the fundamentals have remained exactly as they were introduced. It is a stable first-party Apple API and service.

Out of the box, CloudKit provides you a set of APIs and two runtime environments, “development” and “production”, both running in iCloud. There’s no support for local testing.

Canopy is built on top of the CloudKit API and makes it easier to develop solid CloudKit apps. This article describes the elements that drive the design of the Canopy package.

## Testable CloudKit apps

Canopy lets you fully isolate the CloudKit dependency and test your CloudKit code without any interaction with the real cloud. You can be confident that your features behave the way you want when you receive the expected responses. Since the tests rely only on local data and have no network interaction, they are fast and predictable.

Canopy also offers some ideas around isolating dependencies for your UI tests, and simulating failures in the context of a real app.

<doc:Testable-CloudKit-apps-with-Canopy>

## Consistent modern API

CloudKit offers a family of APIs, varying from operation-based to “immediate” async APIs.

Canopy wraps many of the operation-based APIs behind a single consistent pattern: async APIs with `Result` return types, returning either the requested results or a failure.

Many people prefer working with throwing results. You can convert a Canopy result to a throwing result easily using the [`get()`](https://developer.apple.com/documentation/swift/result/get()) function of the Swift result type at the call site.

As an example, if you have this Canopy API call:

```swift
let recordsResult = await canopy.databaseAPI(usingDatabaseScope: .private).fetchRecords(…)
```

You can easily convert it to a throwing call like this:

```swift
do {
  let result = try await canopy.databaseAPI(usingDatabaseScope: .private).fetchRecords(…).get()
  // use result
} catch {
  // handle thrown error
}
```

## Standard behaviors and features

There are many CloudKit details you need to understand and implement to use it well. For example: server token handling, correctly sequencing zone and database change fetching, query request cursors, how to split large modification operation batches, modification policies, etc.

Canopy implements standard behavior for many of them, and is designed to work in a way that is appropriate for most apps, while adding configuration and hooks to modify the behavior where needed.

<doc:Features-and-behaviors>

## Documentation and best practices

This site documents best practices and CloudKit quirks that are useful to know when you work with it — with or without Canopy.

## Sample app

Canopy provides a sample app called “Thoughts” that showcases best practices for using and testing your CloudKit code, and offers a playground for modern multi-platform, multi-window app development.

<doc:Thoughts-example-app>

## Scope

CloudKit comes in two flavors. The first and earlier one is vanilla CloudKit, which is the main area of interest for Canopy. It’s conceptually very simple: you store a `CKRecord` in CloudKit’s bucket of records, and you get the same `CKRecord` back. It doesn’t prescribe anything about your client-side storage.

CloudKit started with this approach, and its core design has remained stable. It has received some modifications along the way. For example, initially you could only share record hierarchies with other participants, but later on, entire record zone sharing was added. Canopy does not currently implement record zone sharing, but it fits within the project goals and vision and can be added.

The other flavor of CloudKit uses a [combination of Core Data and CloudKit](https://developer.apple.com/documentation/coredata/mirroring_a_core_data_store_with_cloudkit/setting_up_core_data_with_cloudkit) with [NSPersistentCloudKitContainer](https://developer.apple.com/documentation/coredata/nspersistentcloudkitcontainer). This is much more powerful than vanilla CloudKit, and heavily determines your client-side stack.

Canopy does not wish to concern itself initially with client-side storage, and thus the `NSPersistentCloudKitContainer` scenario is initially out of scope for Canopy.
