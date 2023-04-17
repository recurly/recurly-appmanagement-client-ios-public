# iOS RecurlyAppManagementSDK Documentation

## Context
The RecurlyAppManagementSDK enables merchants to record iOS IAP transactions in Recurly’s platform. A challenge in doing this is that Apple’s [Transaction](https://developer.apple.com/documentation/storekit/transaction) / [Receipt](https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html) objects lack key data (such as amount paid), which necessitates some help from the SDK.

The purpose of the SDK is to capture and upload a payload of [Product](https://developer.apple.com/documentation/storekit/product) + [Transaction](https://developer.apple.com/documentation/storekit/Transaction) data to Recurly when an IAP is successfully transacted. Consuming this data allows Recurly to interpret future subscription renewal transactions via App Store Server Notifications without any additional help from your app.

### App Requirements:

- The minimum deployment target for the SDK is iOS 15.0
- The SDK uses StoreKit 2
- StoreKit Transactions must be automatically verified by Apple

## Adding the SDK to your project

You have two options:

-  Add RecurlyAppManagementSDK directly to your project
- Add RecurlyAppManagementSDK via CocoaPods

### Option A: Add RecurlyAppManagementSDK directly to your project

1. Download the latest release from the public github repository, [recurly-client-ios-appmanagement](https://github.com/recurly/recurly-client-ios-appmanagement/releases), containing the `XCFrameworkRecurlyAppManagementSDK.xcframework`
2.. Add the `.xcframework` to Xcode under your app’s `.xcodeproj` > Select your app target > General > Frameworks, Libraries, and Embedded Content
3. Import `RecurlyAppManagementSDK` into files that use it

### Option B: Add RecurlyAppManagementSDK via CocoaPods

If you already use Cocoapods, skip to step 3.

1. [Install CocoaPods](https://guides.cocoapods.org/using/getting-started.html) if you don't already have it.
2. [Set up](https://guides.cocoapods.org/using/using-cocoapods.html) CocoaPods in your project.
3. Add this line to your Podfile.
`pod 'RecurlySDK'`
4. Download and install your required Pods with:
`pod install`
5. Don’t forget to open your code using the .xcworkspace file from now on.

For more information on CocoaPods and the Podfile, visit: <https://guides.cocoapods.org/using/the-podfile.html>

## Using the SDK in your app code

**Replace `Product.purchase()` with `RETransactionhandler.purchase()`**

All IAPs must be initiated by calling [Product.purchase()](https://developer.apple.com/documentation/storekit/product/3791971-purchase). To inject the purchase data upload functionality into your app, simply replace any calls of [Product.purchase() ](https://developer.apple.com/documentation/storekit/product/3791971-purchase)with RETransactionHandler.purchase() like this: \



```
let purchaseResult = try await product.purchase(options: purchaseOptions)
```


becomes


```
let purchaseResult = try await RETransactionHandler.shared.purchase(
    product: product,
    options: purchaseOptions
)
```


This wrapper function will submit your purchase to Apple as you’d expect and has the same return type, [Product](https://developer.apple.com/documentation/storekit/product).[PurchaseResult](https://developer.apple.com/documentation/storekit/product/purchaseresult).

**Recommended:** If you identify your customers with an [AppAccountToken](https://developer.apple.com/documentation/storekit/product/purchaseoption/3749440-appaccounttoken), be sure to include it in the Set of PurchaseOptions when you call `RETransactionHandler.purhcase()`. This information is potentially useful for interpreting future subscription renewal transactions in Recurly.


```
let purchaseOptions: Set = [Product.PurchaseOption.appAccountToken(uuid)]
```


Apple describes an [AppAccountToken](https://developer.apple.com/documentation/storekit/product/purchaseoption/3749440-appaccounttoken) as _a UUID to associate the purchase with an account in your system._

**Subscribe to Transaction.updates and call the RETransactionHandler.handle()**

If you haven’t already, you should create a listener that iterates over incoming transactions emitted by [Transaction.updates](https://developer.apple.com/documentation/storekit/transaction/3851206-updates). According to Apple _If your app has unfinished transactions, the listener receives them immediately after the app launches. Without the Task to listen for these transactions, your app may miss them._

When purchase() returns VerificationResult.Pending, it’s possible that the issue will be resolved and the resulting Transaction will be emitted via Transaction.updates later. Therefore you need to call RETransactionHandler.handle(update) in your Transaction.updates listener.

Here’s a minimal example of a TransactionObserver derived from Apple’s [documentation](https://developer.apple.com/documentation/storekit/transaction/3851206-updates). You probably have an observer analogous to this in your code already if your app already supports IAPs: \



```
final class TransactionObserver {
    var updates: Task<Void, Never>? = nil
    init() {
        updates = newTransactionListenerTask()
    }
    deinit {
        updates?.cancel()
    }
    private func newTransactionListenerTask() -> Task<Void, Never> {
        Task(priority: .background) {
            for await verificationResult in Transaction.updates {
                try await RETransactionHandler.shared.handle(update: update)
                // your code to handle updates
            }
        }
    }
}
```



## Configuring the App Store Server Notification URLs

**Request your App Store Server Notification URL from Recurly and set it on App Store Connect.**

It is necessary for Recurly to receive [App Store Server Notifications](https://developer.apple.com/documentation/appstoreservernotifications) in order to process initial subscription purchases and their associated automatic renewal transactions.

In [App Store Connect](https://appstoreconnect.apple.com/apps), select your app. On the left menu under General > App Information there should be an **App Store Server Notifications** section with the option to set URLs

Go ahead and set both the Production and Sandbox URLs. [According to Apple](https://help.apple.com/app-store-connect/#/dev0067a330b): _If you do not provide a Sandbox URL in App Store Connect, the App Store will automatically send notifications for both environments to the Production URL provided. If you only provide a Sandbox URL, no notifications will be sent in production._


## Logs

The SDK will log key events as a transaction is handled via [os.Logger](https://developer.apple.com/documentation/os/logger). The subsystem of the Logger is “com.recurly.RecurlyAppManagementSDK”. Normal messages are logged at the [Default](https://developer.apple.com/documentation/os/logging/generating_log_messages_from_your_code#3665947) level. Any unexpected errors are logged at the [Error](https://developer.apple.com/documentation/os/logging/generating_log_messages_from_your_code#3665947) level.

A successfully uploaded purchase prints out something similar to this:

```
2023-03-31 14:34:30.785718-0700 YourApp[3788:248889] [main] # 💰 Transaction id 2000000306007902 received via RETransactionhandler.purchase()
2023-03-31 14:34:30.788196-0700 YourApp[3788:248744] [main] # Transaction id 2000000306007902: Will attempt upload
2023-03-31 14:34:32.983560-0700 YourApp[3788:248744] [main] # Transaction id 2000000306007902 upload http status: 201
2023-03-31 14:34:32.983898-0700 YourApp[3788:248744] [main] # ✅ Transaction id 2000000306007902 added to handled transactions collection
2023-03-31 14:34:37.066866-0700 YourApp[3788:248744] [main] # 📲 Transaction id 2000000306007902 received via Transaction.updates
2023-03-31 14:34:37.554370-0700 YourApp[3788:248744] [main] # ⏭️ Transaction id 2000000306007902 has already been uploaded: Will not upload again.
```

## Testing

If you test your IAPs using [StoreKit Testing in Xcode](https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode), you should expect the SDK to attempt to upload the Transaction information as indicated by the above logs. However, StoreKit Testing in Xcode does do any networking with Apple servers and therefore will not trigger App Store Service Notifications. Without these notifications, Recurly’s backend will not process the uploaded payload further. Do not expect to see a result in the Recurly dashboard if you are using StoreKitTesting in Xcode

If you are using the [Sandbox environment](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases_with_sandbox) to test your purchases _and_ you have configured the App Store Server Notification URLs correctly in App Store Connect, you can expect uploaded transactions to be handled fully.















