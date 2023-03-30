# Motivation and scope

A summary of Canopy motivation, technical design goals, and scope.

## Overview

[CloudKit](https://developer.apple.com/icloud/cloudkit/) is a set of Apple API-s that let you store your app data in iCloud. It was introduced at [WWDC 14.](https://www.wwdcnotes.com/notes/wwdc14/208/) While it has gained new features along the way, the fundamentals have remained exactly as they were introduced. It is a stable first-party Apple API and service.

Out of the box, CloudKit provides you a set of API-s and two runtime environments, “development” and “production”, both running in iCloud. There’s no support for local testing.

Canopy is built on top of CloudKit API-s and aims to make it easier to develop solid CloudKit apps. Here are some the elements that drive the design of the Canopy package.

## Testable CloudKit apps

Canopy lets you fully isolate the CloudKit dependency and test your CloudKit code without any interaction with the real cloud. You can have confidence in your features behaving in particular way after receiving particular responses. Since the tests rely only on local data and have no network interaction, they are fast and predictable.

Canopy also offers some ideas around isolating dependencies for your UI tests, and simulating failures in the context of a real app.

<doc:Testable-CloudKit-apps-with-Canopy>

## Consistent modern API

CloudKit offers a family of APIs, varying from Operation-based to “immediate” async API-s.

Canopy wraps many Operation-based API-s behind a single consistent pattern: async API-s with `Result` return types, returning either requested results or a failure.

Many people prefer working with throwing results. You can convert a Canopy result to throwing result easily using the [`get()`](https://developer.apple.com/documentation/swift/result/get()) function of the Swift Result type.

## Standard behaviors and features

There’s many details you need to understand and implement about CloudKit to use it well. Server token handling, correctly sequencing zone and database change fetching, query request cursors, splitting too large modification operation batches, modification policy are just a few examples.

Canopy implements standard behavior for many of them, and aims to work in a way that is appropriate for most apps, while adding configuration and hooks to modify the behavior where needed.

<doc:Features-and-behaviors>

## Documentation and best practices

This site aims to document aspects of Canopy and CloudKit that are useful for working with CloudKit, with or without Canopy.

## Example app

The Thoughts example app that’s part of the Canopy package showcases best practices of using and testing your CloudKit code, as well as offering a broader playground for modern multi-platform, multi-window app development.

<doc:Thoughts-example-app>

## Scope

CloudKit comes in two flavors. The first and earlier one is vanilla CloudKit, which is the main interest area for Canopy. It’s conceptually very simple: you put CKRecords in, you get CKRecords back. It doesn’t prescribe anything about your client-side storage.

CloudKit started with this approach, and its core design has remained stable. It has received some modifications along the way. For example, initially you could only share record hierarchies with other participants, but later on, entire record zone sharing was added.

Canopy does not currently implement record zone sharing, but it fits within the project goals and vision and can be added.

The other flavor of CloudKit is using [Core Data and CloudKit together.](https://developer.apple.com/documentation/coredata/mirroring_a_core_data_store_with_cloudkit/setting_up_core_data_with_cloudkit) This is much more powerful than vanilla CloudKit, and heavily determines your client-side stack.

Canopy does not wish to concern itself initially with client-side storage, and thus the Core Data+CloudKit is initially out of scope for Canopy.
