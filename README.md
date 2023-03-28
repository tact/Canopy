# Canopy

Canopy helps you write better, more testable CloudKit apps.

TL;DR:

## Installing Canopy

Canopy is distributed as a Swift Package Manager package.

If you use Xcode UI to manage your dependencies, add `https://github.com/Tact/Canopy` as the dependency for your project.

If you use SPM `Package.swift`, add this:

```
dependencies: [
  .package(
    url: "https://github.com/Tact/Canopy",
    from: "0.2.0"
  )
]
```

## Using Canopy

### One-line example

To fetch a record from CloudKit private database which has the record ID `exampleID`, use this Canopy call:

```swift
let record = await Canopy().databaseAPI(usingDatabaseScope: .private).fetchRecords(
    with recordIDs: [CKRecord.ID(recordName: "exampleID")],
    desiredKeys: nil,
    perRecordIDProgressBlock: nil,
    qualityOfService: .userInitiated
  ).foundRecords.first
```

### Dependency injection for testability

Canopy is designed for enabling your code to be testable. You do your part by using [dependency injection](https://en.wikipedia.org/wiki/Dependency_injection) pattern in most of your code and features. Most of your code should not instatiate Canopy directly, but should receive it from outside. For example:

```swift
actor MyService {
  private let canopy: CanopyType
  init(canopy: CanopyType) {
    self.canopy = canopy
  }

  func someFeature() async {
    let databaseAPI = await canopy.getDatabaseAPI(usingDatabaseScope: .private)
    // call databaseAPI functions to
    // retrieve and modify records, zones, subscriptions …
  }
}
```

In live use of your app, you initiate and inject the live Canopy object that talks to CloudKit. When independently testing your features, you instead inject a mock Canopy object that doesn’t talk to any cloud services, but instead plays back mock responses.

// FIXME: link to testing

### Dependency injection with swift-dependency

TODO FIXME: write this

Above was the quick info .. move the rest to doc site

## Motivation

[CloudKit](https://developer.apple.com/icloud/cloudkit/) is a set of Apple API-s that let you store your app data in iCloud. It was introduced at [WWDC 14.](https://www.wwdcnotes.com/notes/wwdc14/208/) While it has gained new features along the way, the fundamentals have remained exactly as they were introduced. It is a stable first-party Apple API and service.

Out of the box, CloudKit provides you a set of API-s and two runtime environments, “development” and “production”, both running in iCloud. There’s no support for local testing.

Canopy is built on top of CloudKit API-s and aims to make it easier to develop solid CloudKit apps. Here are some of the Canopy design goals.

### Testable apps

### Consistent modern API

### Documentation and best practices

### Example app

### Limited scope

## Authors and credits

Canopy was built, and continues to be built, as part of [Tact app.](https://justtact.com/)

Major contributors: [Jaanus Kase](https://github.com/jaanus), [Andrew Tetlaw](https://github.com/atetlaw), [Henry Cooper](https://github.com/pillboxer)

Thanks to: [Priidu Zilmer](https://github.com/priiduzilmer), [Roger Sheen](https://github.com/infotexture), [Margus Holland](https://github.com/margusholland)
