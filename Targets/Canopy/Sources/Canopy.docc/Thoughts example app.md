# Thoughts example app

Thoughts is an example app that showcases how to build and test your code with Canopy, as well as other best practices for modern app development.

## Overview

[Thoughts](https://github.com/Tact/Thoughts) is a companion app for Canopy. It demonstrates how to use Canopy in the context of a real app, and showcases other ideas for modern multi-platform multi-window app development.

User story for Thoughts:

_I would like to keep a list of my thoughts that syncs neatly across all my devices via iCloud. My thoughts have a body and possibly a title. They may contain private info, so I’d like them encrypted. I want to emphasize parts of the thought with Markdown._

![Thoughts iOS - one thought](thoughts-ios-onethought)

## Key ideas

**Testability.** Thoughts showcases how to use all three approaches to testing outlined in <doc:Testable-CloudKit-apps-with-Canopy>. It has unit tests with 100% coverage for its central store and view models, UI tests with isolated dependencies, and lets you simulate some errors via its settings interface.

**Multi-platform, multi-window.** Thoughts works on both macOS and iOS, with single or multiple windows. All UI code is shared native SwiftUI, with minimal platform-specific modifications as needed.

![Thoughts macOS](thoughts-macos)

![Thoughts iOS - list of thoughts](thoughts-ios-list)

**Rich tests and previews.** You can explore much of the Thoughts functionality by simply browsing the tests and the SwiftUI previews of all its views, showcasing all possible view states.

![Thoughts SwiftUI previews](thoughts-previews)

**Ready for Advanced Data Protection.** Thoughts uses [encryptedValues](https://developer.apple.com/documentation/cloudkit/ckrecord/3746821-encryptedvalues) to store all the private user data, so if the user has Advanced Data Protection on their account, end-to-end encryption will apply. Read more: <doc:iCloud-Advanced-Data-Protection>

## Architecture

![Thoughts architecture](thoughts-architecture)

The Thoughts architecture could perhaps be labeled “store and viewmodels”. There is a central store that acts as in-memory source of truth while the app is running, and interacts both with views and external world. Viewmodels use Store as their data source, and keep view-local state such as the transient state of UI in a view.

The division of “UI-land” and “Backend-land” is arbitrary. Perhaps the clearest distinction is that the UI-land code is running in the main queue, as all UI code on Apple platforms must, though there are some exceptions (viewmodels have long-running background tasks to subscribe and react to store changes).

Thoughts is architected to be testable and mockable. You can see this with SwiftUI previews. Even though you may not be able to build and run the app (at least until you replace the team and container IDs with your own ones), you can get a taste of the whole app UI via tests and previews.

## Future ideas

**Full offline mode.** Although Thoughts functions with CloudKit connectivity problems, it does not function fully as an offline app. When there is a problem saving data to CloudKit, Thoughts retries a few times through Canopy’s auto-retry, but eventually gives up if there really is no connection (or there is a permanent simulated error), and does not attempt another save when the connection is restored. Another save attempt is made only after you again edit a thought. Fully functional offline mode would be an interesting extension.

**Preserving window state.** Although Thoughts remembers window positions and sizes on macOS automatically through SwiftUI magic, it currently does not preserve the navigation state.

**Sharing and collaboration.** Currently, Thoughts is designed to work only in a single user scenario, but the data model design has possible sharing in mind. Most importantly, its records on CloudKit are stored in a custom zone in the user’s private CloudKit database. Should sharing with other users ever get implemented in Thoughts, it will be straightforward from CloudKit perspective.
