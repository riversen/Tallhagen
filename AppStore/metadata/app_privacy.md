# App Privacy answers for Tallhagen (App Store Connect)

These are the answers to type into the **App Privacy** section of App Store Connect for Tallhagen 1.0. They are written so that the owner filling in the form and an App Review reader can both see why every answer is "no": the app has no network code at all, so it never sends anything off the iPad.

## Summary

| Question | Answer |
| --- | --- |
| Do you or your third-party partners collect data from this app? | **No, we do not collect data from this app** |
| Does the app use data for tracking? | **No** (the question is not shown when nothing is collected) |
| Every data type, every category and sub-type | **Not collected** |
| Privacy Policy URL | `https://riversen.github.io/Tallhagen/privacy.html` (the hosted copy of `AppStore/privacy-policy/index.html`) |
| User Privacy Choices URL | leave empty |

Result on the App Store product page: the **Data Not Collected** label, which tells parents that the developer does not collect any data from this app.

## Where to enter it

1. App Store Connect, then Apps, then Tallhagen.
2. In the sidebar under General, click **App Privacy**.
3. **Privacy Policy**: click Edit, paste the privacy policy URL, leave "User Privacy Choices URL" empty, click Save. (A change to this URL is released with the next app version.)
4. **Data Collection**: click **Get Started**, choose **No, we do not collect data from this app**, click Save. App Store Connect then asks no further questions.
5. Scroll to **Product Page Preview** and confirm that it shows the app does not collect data.
6. Click **Publish** (top right) and confirm in the "Publish Your App Privacy Responses?" dialog. Do this before submitting the first version for review; the responses appear on the product page when it goes live.

## Why "No" is the accurate answer

Apple defines "collect", for this form, as transmitting data off the device in a way that lets the developer or a third party access it for longer than is needed to serve a request in real time. Apple's guidance adds that data processed only on the device is not "collected" and does not need to be disclosed.

Tallhagen:

- makes no network connections of any kind: no URL loading, no sockets, no web views, no links that open a browser;
- contains no third-party code: no SDKs, no analytics, no advertising, no crash-reporting libraries. The only frameworks it uses are Apple's SwiftUI, Foundation, UIKit and AVFoundation (for on-device speech synthesis);
- has no accounts, sign-in, purchases or subscriptions;
- never asks for the microphone, camera, location, contacts, photos or any other permission;
- stores exactly four values with Apple's UserDefaults on the iPad: the chosen level (`learningLevel`), whether speech is on (`speakNorwegian`), the number of solved tasks (`solvedTotal`) and the stars earned on the island map (`islandStars`, one short text holding the stars per map task). The app never sends them off the device; they are not identifiers and are deleted with the app. Under Apple's definition they are not collected.

Because nothing is transmitted, there are no "third-party partners" either.

## Every data type, and why it is "Not collected"

The full list of data types is shown only after answering "Yes". If it ever appears, every box stays unticked. The reasons, category by category, are also the answer to any reviewer question about a particular type:

| Category | Sub-types | Why it is not collected |
| --- | --- | --- |
| Contact Info | Name, Email Address, Phone Number, Physical Address, Other User Contact Info | No account, no form and no text field anywhere in the app; nothing is typed in. |
| Health & Fitness | Health, Fitness | No health content and no HealthKit. |
| Financial Info | Payment Info, Credit Info, Other Financial Info | No purchases, no payments, no StoreKit. |
| Location | Precise Location, Coarse Location | No location services. |
| Sensitive Info | Sensitive Info | Nothing of this kind exists in the app. |
| Contacts | Contacts | No access to the contacts database. |
| User Content | Emails or Text Messages, Photos or Videos, Audio Data, Gameplay Content, Customer Support, Other User Content | No messages, photos, recordings or support channel. The app never sends gameplay state (the four stored values) off the device. |
| Browsing History | Browsing History | No web content. |
| Search History | Search History | No search. |
| Identifiers | User ID, Device ID | No accounts, no advertising identifier, no device identifiers read or sent. |
| Purchases | Purchase History | No purchases. |
| Usage Data | Product Interaction, Advertising Data, Other Usage Data | No analytics or event logging; the solved-task count and the map stars are only shown on the device. |
| Diagnostics | Crash Data, Performance Data, Other Diagnostic Data | No crash or performance reporting code. If an iPad owner has chosen in iPadOS Settings to share diagnostics with Apple and developers, that sharing is done by Apple's platform; Apple's guidance states that developers are not responsible for disclosing data collected by Apple. |
| Surroundings | Environment Scanning | No camera and no augmented reality. |
| Body | Hands, Head | No camera and no motion capture. |
| Other Data | Other Data Types | Nothing else is collected. |

## Tracking

Answer **No** wherever tracking is asked about. Tracking means linking data about a user or device with third-party data for advertising purposes, or sharing it with a data broker. Tallhagen has no advertising, shows no App Tracking Transparency prompt, never reads the advertising identifier and sends no data anywhere.

## The privacy manifest in the app

`Tallhagen/PrivacyInfo.xcprivacy` is consistent with these answers:

- `NSPrivacyTracking` is false.
- `NSPrivacyCollectedDataTypes` is an empty array: nothing collected.
- `NSPrivacyAccessedAPITypes` has one entry, `NSPrivacyAccessedAPICategoryUserDefaults`, with reason `CA92.1` (reading and writing user defaults that are accessible only to the app itself). This covers the four `@AppStorage` keys above. No other required-reason API family is used (no file timestamp, system boot time, disk space or active keyboard APIs).
- There is no `NSPrivacyTrackingDomains` key, because no tracking domains exist; the app never contacts any domain at all.
- There are no third-party SDKs, so no SDK privacy manifests or signatures are involved.

If Apple's upload validation ever reports a missing reason for a required-reason API, that would mean new code was added; review the manifest at that point.

## A short statement for the App Review notes

If a sentence about privacy is wanted in the "Notes" field of App Review Information: "Tallhagen is fully offline. It contains no network code, no third-party SDKs, no analytics, no advertising, no accounts and no purchases. The only stored data is four local values (level, sound on or off, solved-task count, stars on the island map) in UserDefaults; the app never sends them off the device. Speech uses Apple's on-device speech synthesis; no audio is recorded."

## Keeping the answers true

The answers stay valid as long as the app keeps the properties documented in `agent.md` section 9: no network, no third-party code, no accounts, no analytics. Any future change to those would require updating the privacy policy, the privacy manifest and these App Privacy answers before the release that introduces it.
