# Why you should (not) use CloudKit as your backend

The pros and cons of using CloudKit.

## Overview

Should you use CloudKit as the backend for your app?

There is no universal answer to this question. It depends on the context of your app, your users, and you as the developer. It has business, technical, and operational aspects. This article explores some of the tradeoffs which may help you make this decision.

Apple has an article with similar title on their site: [Determining If CloudKit Is Right for Your App.](https://developer.apple.com/documentation/cloudkit/determining_if_cloudkit_is_right_for_your_app) The focus of that article is more narrow and technical: it helps you decide between various cloud storage services and API-s that Apple itself offers. It contains good technical information and you should consider it, but does not discuss the complete picture.

This article asks a broader question: if you are a developer who needs a cloud backend for your app, and CloudKit roughly fits your data model, how should you think about the offerings of both Apple and other service providers?

## Arguments in favor of CloudKit

**First party technology.** CloudKit an integral part of Apple software and services stack. Apple has been operating it since 2014, and has committed to maintaining in the long term. Apple’s business model and privacy policy apply to it. We can expect CloudKit to remain stable and be around for a long time.

**Based on iCloud account.** Apple steers everyone using their devices to have an iCloud account, and you can expect your users to have one, if they use any Apple devices. There is no sign-up for your app in the classical sense where your users would have to create an account, create a password, you’d need to deal with lost passwords etc. The user’s iCloud account takes care of all these matters and steers users towards securing their account with 2FA and Advanced Data Protection, so you can focus on the value add of your app.

**Nothing to set up or operate in the cloud.** You need to do literally nothing to set up and operate your CloudKit backend from an operational perspective. It all happens as part of your Apple developer account, and Apple operates the services on your behalf. With a third party service provider, you would need to research their service offering, consider their pricing and privacy policy, set up a separate contract and billing relationship, keep an eye on their service stability etc. Most modern service providers are straightforward to use and these steps are not insurmountable, but it is an extra chore to do, and possibly extra price to pay, in addition to your Apple developer account.

**Supports storage of large assets.** CloudKit API and service do not have asset size limits beyond those imposed by the user’s iCloud plan, device storage, and public database quota if you use CloudKit public database. Tact app currently itself implements a storage cap for assets, but that is purely for client-side user experience reasons: we have not yet implemented optimal UX for handling large assets. We have, however, done technical experiments for storing multi-gigabyte assets, and everything works as expected. CloudKit is technically suitable for working with large media.

**No cost to developer. Costs are distributed across users.** Most of the time, there is no cost to you as the developer for using CloudKit. If you use CloudKit private and shared databases, users themselves pay for the cloud space as part of their iCloud plan. If you use public database, CloudKit has a generous storage cap that scales with the number of your app users. You do need to pay if you store a large amount of assets per user (bytes, not number of items) in the public database.

**Privacy model.** CloudKit has a user-centric privacy model. The user’s private data that they store with your app is in their private database, with no way for you as the developer to access it. This may be considered either advantage or disadvantage depending on your world view and business model. Canopy is developed as part of [Tact](https://justtact.com), whose [privacy policy](https://go.justtact.com/link/privacy) and world view state that users’ data belongs only to them, and thus it is listed here as an argument in favor of CloudKit.

**Advanced Data Protection and end-to-end encryption.** In December 2022, Apple started rolling out Advanced Data Protection which also covers third-party apps. Your app data in CloudKit is end-to-end encrypted when certain conditions are met. Read more in our dedicated article: <doc:iCloud-Advanced-Data-Protection>

## Arguments against CloudKit

**Only Apple client platforms.** CloudKit only supports Apple client platforms—iOS, macOS, watchOS and tvOS. There is no support for Android, Windows, or other client platforms. There is a [CloudKit JS](https://developer.apple.com/documentation/cloudkitjs) available which lets you build web-based UI for a CloudKit app, and we have built a working technical experiment with it for Tact, but there is no API or tooling to build native CloudKit apps on non-Apple client platforms.

**Requires iCloud account and Apple ID.** CloudKit requires using an Apple ID and iCloud account. This is not an issue for Apple customers who are highly likely to have these, but it may be a showstopper for users on other platforms.

**Requires iCloud Drive.** The relation between iCloud Drive and CloudKit is problematic and unclear to both developers and users. Using CloudKit requires iCloud Drive to be enabled on the user’s device. The user experience of enabling and disabling iCloud Drive and CloudKit apps keeps changing with each OS release. [See this blog post](https://blog.justtact.com/disabling-icloud-drive-should-not-disable-cloudkit-access/) for discussion and example with an earlier iOS version.

**Immutable record ownership.** Each shared data record in CloudKit has exactly one owner, and there is no way to transfer ownership of records between users. This may be limiting to some categories of apps.

**No administrator visibility and compliance in private/shared databases.** CloudKit provides two extremes in privacy approach: in public database, the data is shared between all users (although not all users can necessarily always access all data). In private and shared databases, the data is strictly owned by the record owner and those with whom the record owner shares it. There is no way to provide access to user’s private CloudKit data to a role like “business administrator.” Thus, you cannot use CloudKit to build privacy-preserving apps which would meet common enterprise scenario requirements like being able to recover data held by users for legal purposes, transferring records to other employees when someone leaves a company, etc. We note that this would be an interesting area of development and unlock whole new classes of business apps on Apple platforms, but currently, this is not supported.

**No server-side logic on private and shared databases.** CloudKit public database has [CloudKit web services](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/index.html#//apple_ref/doc/uid/TP40015240) that lets you read and change data in CloudKit public database from your own server, providing you a way to enhance the data that users themselves have added. This is not available in private and shared databases: those behave strictly as “buckets of records”. You put records in, you get records back, but there is no way to run any additional logic on the server side.

**Limited visibility into Advanced Data Protection.** As the <doc:iCloud-Advanced-Data-Protection> article discusses, there is no way for you as a developer to assert to yourself or your users whether end-to-end encryption actually applies for a given record stored in CloudKit.

## Conclusion

There is no single conclusion to this article. Each developer needs to decide for themselves whether using CloudKit is appropriate for their app, users, and business. The arguments listed above have different weights for each developer. We will update this article as CloudKit evolves.
