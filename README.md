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

### Using throwing return type

Canopy provides all its API as `async Result`. Many people prefer to instead use throwing API. It’s easy to convert Canopy API calls to throwing style at the call site with the [`get()`](https://developer.apple.com/documentation/swift/result/get()) API. For the above example, follow this approach:

```swift
do {
  let result = await Canopy().databaseAPI(usingDatabaseScope: .private).fetchRecords(…).get()
  // use result
} catch {
  // handle thrown error
}
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

## Understanding Canopy

The Canopy package has three parts.

### Libraries

Libraries provide the main Canopy functionality and value. `Canopy` is the main library, `CanopyTestTools` helps you build tests, and `CanopyTypes` provides some shared types used by both.

### Documentation

The Canopy documentation site at <https://canopy-docs.justtact.com> has documentation for the libraries, as well as information about the library motivation and some ideas and best practices about using CloudKit. The documentation is generated from DOCC in this same repository, and can also be used inline in Xcode.

Some highlights from documentation:

FIXME

### Example app

The `Things` example app showcases using Canopy in a real app, and demonstrates some best practices for modern multi-platform, multi-window app development.

TODO: LINK



## Authors and credits

Canopy was built, and continues to be built, as part of [Tact app.](https://justtact.com/)

Major contributors: [Jaanus Kase](https://github.com/jaanus), [Andrew Tetlaw](https://github.com/atetlaw), [Henry Cooper](https://github.com/pillboxer)

Thanks to: [Priidu Zilmer](https://github.com/priiduzilmer), [Roger Sheen](https://github.com/infotexture), [Margus Holland](https://github.com/margusholland)
