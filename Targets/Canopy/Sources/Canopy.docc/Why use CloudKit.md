# Why you should (not) use CloudKit as your backend

The pros and cons of using CloudKit.

## Overview

Should you use CloudKit as the backend for your app?

There is no universal answer to this question. It depends on the context of your app, your users, and you as the developer. It has business, technical, and operational aspects. This article explores some of the tradeoffs which may help you make this decision.

Apple has an article with similar title on their site: [Determining If CloudKit Is Right for Your App.](https://developer.apple.com/documentation/cloudkit/determining_if_cloudkit_is_right_for_your_app) The focus of that article is more narrow and technical: it helps you decide between various cloud storage services and API-s that Apple itself offers. It contains good technical information and you should consider it, but does not discuss the complete picture.

This article asks a broader question: were you a developer who needs a cloud backend for your app, and CloudKit roughly fits the data model of your app, how should you think about the offerings of both Apple and other service providers?

## Arguments in favor of CloudKit

**First party technology.** CloudKit an integral part of Apple software and services stack. Apple has been operating it since 2014, and has committed to maintaining in the long term. Apple’s business model and privacy policy apply to it. We can expect CloudKit to remain stable and be around for a while.

**Based on iCloud account.** Apple steers everyone using their devices to have an iCloud account, and you can expect your users to have one, if they use any Apple devices. There is no sign-up in the classical sense where your users would have to create an account, create a password, you’d need to deal with lost passwords etc. The user’s iCloud account takes care of all these matters, so you can focus on the value add of your app.

Nothing to operate in the cloud

Large storage works

No cost to developer. Costs are distributed across users.

Web services

Privacy model

Advanced Data Protection

## Arguments against CloudKit

No other platforms.

iCloud Drive required.

Immutable resource ownership

No logic on the cloud (except in public database?)

No business visibility, compliance etc.

Limits are not documented.

No visibility into Advanced Data Protection
