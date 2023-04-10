# iCloud Advanced Data Protection

What Advanced Data Protection for iCloud means for your CloudKit app.

_This article was [originally published](https://blog.justtact.com/advanced-data-protection/) on Tact engineering blog. Slightly edited for Canopy documentation._

In December 2022, Apple announced [powerful new data protections.](https://www.apple.com/newsroom/2022/12/apple-advances-user-security-with-powerful-new-data-protections/) Of the three announced protections, iMessage Contact Key Verification is specific to Messages, and thus beyond the scope of this post.

Let’s talk about the other two.

Security Keys for Apple ID do not have a direct impact on your app and its data, but are indirectly a great way to improve the security of user accounts. Since CloudKit apps use the users’ iCloud account which in turn uses their Apple ID, do consider using a hardware security key to further secure yourself, and discuss this also with your users.

Advanced Data Protection (ADP) for iCloud is the most intriguing of the three, and the rest of this article will discuss how it can improve the security of user data in CloudKit apps.

TL;DR: your app’s records in iCloud will be end-to-end encrypted if certain conditions are met. You have no way to verify some of the conditions on your end.

## iCloud security basics

The security of third-party app data in CloudKit was previously a bit of a mystery. There were a number of platform security documents by Apple, but there wasn’t an easily digestible policy or guide.

With this data protection announcement, Apple has freshly published a number of documents that discuss iCloud security, including that of third-party CloudKit apps, in greater detail:

* [iCloud security overview](https://support.apple.com/guide/security/secacde2d0da)
* [iCloud data security overview](https://support.apple.com/kb/HT202303)
* [Advanced Data Protection for iCloud](https://support.apple.com/guide/security/sec973254c5f)

The first one pretty clearly outlines that all data in iCloud, including both Apple and third-party apps, now falls under one of two policies.

> * **Standard data protection (the default setting):** The user’s iCloud data is encrypted, the encryption keys are secured in Apple data centers, and Apple can assist with data and account recovery.  
> * **Advanced Data Protection for iCloud:** An optional setting that offers Apple’s highest level of cloud data security. If a user chooses to turn on Advanced Data Protection, their trusted devices retain sole access to the encryption keys for the majority of their iCloud data, thereby protecting it using end-to-end encryption.

In a nutshell, data in both cases is encrypted both in transit and at rest in the iCloud data centers. In the first case, Apple has access to the keys. In the second case, they don’t, and data is end-to-end encrypted if certain conditions are met.

## Storing encrypted data in CloudKit

If you use CloudKit to store your app data in iCloud, you need to look at the [encryptedValues](https://developer.apple.com/documentation/cloudkit/ckrecord/3746821-encryptedvalues) API in `CKRecord`. This is your single entry point to storing and retrieving the encrypted values that could be end-to-end encrypted with Advanced Data Protection.

There’s three categories of data to think about.

* `CKAsset` records are already always encrypted.
* `CKReference` fields are never encrypted, since the server needs access to them to identify relations between records.
* For all other data types, they are encrypted as long as you use the `encryptedValues` API to work with them, instead of setting them directly on your `CKRecord`.

You lose certain features with encryption. As the documentation says:

> CloudKit doesn’t support indexes on encrypted fields. Don’t include encrypted fields in your predicate or sort descriptors when fetching records with `CKQuery` and `CKQueryOperation`.

This is pretty obvious, but worth mentioning. Since the server no longer has access to the field contents, you obviously cannot query, search or sort by them.

## Sharing

Sharing has impact on ADP and end-to-end encryption. The data security overview says:

> iWork collaboration, the Shared Albums feature in Photos, and sharing content with “anyone with the link,” do not support Advanced Data Protection. When you use these features, the encryption keys for the shared content are securely uploaded to Apple data centers so that iCloud can facilitate real-time collaboration or web sharing.

It’s not clear what “anyone with the link” means for CloudKit apps and `CKShare`. We can assume it means the [publicPermission](https://developer.apple.com/documentation/cloudkit/ckshare/1640494-publicpermission) of a `CKShare` being something other than `none`: that is, if anyone can access the shared record by just opening its shared URL, even if it is only for reading purposes.

## When does ADP and end-to-end encryption apply to values of a CloudKit record?

Let’s now put all the pieces together and ask: when is the data in a given `CKRecord` end-to-end encrypted? As far as we can tell, these three conditions must be met.

1. You use the `encryptedValues` API and `CKAsset` to store the data that you want to protect.
2. If the record belongs in a shared record hierarchy, `publicPermission` on the `CKShare` that governs the share is `none`.
3. Current user, and in case of shared record also all other users, have ADP enabled on their iCloud account.

As a developer, you have control over conditions 1 and 2. Here’s the thing though: **you have no way to tell at runtime in your app if condition 3 is met.** There is no way for you to know if the current user or other `CKShare` members have ADP enabled on their account or not.

If you had a way to verify condition 3, you could display a nice badge or something in your app next to the relevant `CKRecord`, to indicate that all the conditions for end-to-end encryption have been met, and the user can assume this data to be end-to-end encrypted. But there is no way to do this, and doesn’t sound like there will be any time soon.

I was obviously interested in doing this for Tact, so I asked in a December 2022 Ask Apple session about this. A helpful Apple person told me in pretty clear terms:

> Apple does not provide API for [checking whether a given user has ADP enabled] because we don't want to expose users' account choices to other users.

This makes perfect sense. Not exposing users’ account choices is a good approach and I support that. At the same time, I think that it’s a valid need to provide assurance to users about whether something is end-to-end encrypted, because it may inform their choice about the kind of info that they want to store with your app. These two goals (protect users’ account choices, and inform all participants about whether ADP applies to a given `CKRecord`) are currently in conflict, and it’s clear which one Apple has chosen. I (and I suppose also Apple) can’t imagine a system design that would satisfy both goals. So, that’s just how it is for now.

## Conclusion

People interested in Tact sometimes ask me about end-to-end encryption. Until now, I had to say Tact just doesn’t have any. Now, I can say that it’s there if the above conditions are met.

Implementing any security protocol correctly, including end-to-end encryption, is hard. I have infinitely more faith in Apple’s than my own ability to do it well. I hope that they will follow up with independent security analyses and audits that’s common industry practice for these kinds of systems, to provide users and developers extra assurance in their implementation.

As a developer, since you don’t have access to users’ account choices, you have no way to definitively inform your users about whether ADP applies to the data they store in your system. The best you can do today is complete your part of the equation by using `encryptedValues` and `CKAsset`s, and educating your users about enabling ADP on their account if they choose to do so.
