# Testable CloudKit apps with Canopy

How to use Canopy to build testable apps.

## Overview

When you use Apple CloudKit APIs, your CloudKit code works against real CloudKit backends. Apple operates two CloudKit environments for you: “development” and “production”. You do your development work with debug build against development environment. The live version of your app uses the production environment.

![Testing CloudKit code without Canopy](testing-without-canopy)

It is good that the two environments are separated like this. However, your dependency on CloudKit is not _isolated_. You depend on several things, like having a network connection, data in CloudKit being in a particular state, and the iCloud account on your device or simulator being (not) logged in.

Testing all the combinations of connectivity, data and account state is tedious.

For a longer discussion on isolating dependencies, read [“What are dependencies?”](https://pointfreeco.github.io/swift-dependencies/main/documentation/dependencies/whataredependencies) by [Point-Free.](https://www.pointfree.co) Although it discusses a simplistic clock example, all your network and cloud dependencies, including CloudKit, are examples of dependencies you want to isolate for reliable and fast tests and previews.

## Isolating CloudKit dependency with replaying mock containers

The key idea that Canopy offers for isolating the CloudKit dependency is to replace the real cloud containers with _replaying mock containers_.

[CKContainer](https://developer.apple.com/documentation/cloudkit/ckcontainer) and [CKDatabase](https://developer.apple.com/documentation/cloudkit/ckdatabase) are the key CloudKit objects that your code interacts with, performing API calls, sending and receiving data. You could say that these objects are the representations of your app data in iCloud. They represent the real data that lives in some Apple-operated data center. By interacting with these objects, you interact with the data over the cloud.

The Canopy approach to testing and dependency isolation keeps interacting with these objects during live application use. However, for tests and previews, you substitute them with Canopy’s two replaying mock containers: [ReplayingMockCKContainer](https://github.com/tact/Canopy/blob/main/Targets/CanopyTestTools/Sources/ReplayingMockCKContainer/ReplayingMockCKContainer.swift) and [ReplayingMockCKDatabase](https://github.com/tact/Canopy/blob/main/Targets/CanopyTestTools/Sources/ReplayingMockCKDatabase/ReplayingMockCKDatabase.swift).

The term _replaying_ in their name indicates their core behavior: they _replay_, or play back, the responses to CloudKit requests that you initialize them with. They are stateless in the sense that they don’t know anything about your application or its data. All they know is how to behave as substitutions of the real cloud-based objects, while keeping the interaction local to your code and device.

![Testing CloudKit code with Canopy](testing-with-canopy)

Here is an example from [Canopy test suite.](https://github.com/tact/Canopy/blob/main/Targets/Canopy/Tests/ModifyRecordsTests.swift#L34)

```swift
func test_success() async {
  let recordID = CKRecord.ID(recordName: "TestRecordName")
  let record = CKRecord(recordType: "TestRecord", recordID: recordID)
  let db = ReplayingMockCKDatabase(
    operationResults: [
      .modify(
        .init(
          savedRecordResults: [
            .init(
              recordID: recordID,
              result: .success(record)
            )
          ],
          deletedRecordIDResults: [],
          modifyResult: .init(result: .success(()))
        )
      )
    ]
  )
  
  let api = databaseAPI(db)
  let result = try! await api.modifyRecords(saving: [record]).get()
  
  XCTAssertTrue(result.savedRecords.first!.isEqualToRecord(record))
  XCTAssertEqual(result.deletedRecordIDs, [])
}
```

You see that a `ReplayingMockCKDatabase` is initialized with one result to a modification operation. An API request is then run, and compared with the expected result, which in this case is a success. In the test suite, you will see similar tests also for failure scenarios.

See the <doc:Thoughts-example-app> for how to build the features and tests in the context of a real app. The important thing to realize here is that most of your application and feature code does not know, and should not know, whether it is running against a real or mock backend. The point of dependency isolation and controlling is to test the real behavior against an isolated mock, so you can have confidence that it behaves correctly in the live context.

The above simple example shows just one response being played back, but there’s no limit to how many responses a replaying mock has: it can have many, and you can test a complex multi-step CloudKit interaction with this approach. In [Tact app](https://justtact.com), we have tests for application startup from both “blank” and “previously installed” states, which simulate tens of CloudKit requests in this fashion.

The replaying mocks are not aware of your app’s data model and semantics. You get the best results with them if you first develop your app a bit against CloudKit development environment, so you have some idea about what is the real shape of CloudKit responses. You can then build tests with replaying mocks, simulating those responses. Replaying mocks have no way to check that the responses make sense: you can construct completely nonsensical scenarios with them, and make your app respond adequately, if you so choose.

## Using Canopy replaying mock containers with UI testing

The above approach works well for unit testing where you can independently construct your features and inject dependencies to them.

UI testing works differently. Your app is built and run as a black box, with the accessibility APIs controlling and introspecting the app UI. Traditional dependency injection does not work because the UI test does not have control how the application code gets built.

Canopy suggests an approach to UI testing where the desired state of the app is built on the UI test side, and injected into the application through the process environment. When the application starts, it sees whether it is running in debug configuration, and if so, whether the state has been injected. If so, it constructs its data store using the mock data and interacts with those, instead of the real cloud interfaces. See <doc:Thoughts-example-app> and its UI tests for a real example.

![UI testing with Canopy](testing-ui)

This approach currently requires to always link your app against `CanopyTestTools`, slightly increasing the app size and complexity. We hope to find a way to conditionally link the app against the test tools only if the app is built in test/debug configuration and needs to construct the mock store with replaying containers.

Being able to inject the state via launch environment is one of the reasons why `ReplayingMockCKContainer`, `ReplayingMockCKDatabase` and all their nested types conform to `Codable`. The state can easily be encoded and decoded with standard encoding APIs, and you can have these types be part of other more complex nested `Codable` types, as you see in Thoughts app example. 

## Simulating request failures during live application use

Testing is something that you do during development or continuous integration. Most of your non-engineering staff is not directly involved in the approaches to testing described above.

Canopy offers another method of testing that you can use with your wider team during the development period or even live use of your app, in the context of real data and devices: _simulating failures_. The idea is that during real use, your app behaves mostly as expected, but you can control it to explicitly fail some requests, which lets you test the UI of error handling.

<doc:Thoughts-example-app> shows one way to do this. In its settings, you can instruct the app to simulate failed requests for specific cases. When you then do those things in the app, it responds with an error that, from the perspective of the UI, is real because the underlying Canopy library returned it as a real error. You can then test and refine the user experience of your app behavior in error situations.

![Simulating errors with Thoughts app](thoughts-ios-settings)

Thoughts exposes these settings to everyone. In a real app, you should not do this because your real users have no use for this functionality. You may want to create a special “Developer Settings” view for your app that can only be accessed with some hidden method, such as repeatedly tapping on some part of the screen in a way that a user would not regularly do, performing some non-obvious gesture etc.

## Conclusion

Canopy adds three tools to your toolkit of testing your CloudKit app.

**Replaying mock containers** let you isolate your CloudKit dependency and construct unit and integration tests against replayed CloudKit requests.

**Injecting mock containers via process launch environment** extends the replaying containers to UI testing.

**Simulating failures during real application use** lets you test your error-handling code in the context of real application with real users and devices.
