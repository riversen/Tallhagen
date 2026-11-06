# Tallhagen: App Store submission checklist

This guide takes the owner of Tallhagen from a working Xcode project to a published iPad app, in the order the steps have to happen. Paths are relative to the project root, the folder that holds `Tallhagen.xcodeproj` (a clone of github.com/riversen/Tallhagen has the same layout, plus the hosted pages in `docs/`). Files marked "kit" were prepared as part of this submission kit; files marked "you" can only be produced or entered by you, because they need your Apple account, your web space or your contact details. Nothing in the kit contains your e-mail address, phone number or team identifier.

Facts this checklist relies on, all already set in the project:

| Fact | Value |
| --- | --- |
| Bundle identifier | `com.roysworld.tallhagen` (app target; lowercase since project version 11), set together with your team, automatic signing |
| Version and build | `MARKETING_VERSION` 1.0, `CURRENT_PROJECT_VERSION` 1 |
| Platform | iPad only (`TARGETED_DEVICE_FAMILY = 2`), iPadOS 17.0 or later, all four orientations, generated launch screen |
| Info.plist | Generated from build settings; includes `ITSAppUsesNonExemptEncryption = NO` (no encryption of its own) and `LSApplicationCategoryType = public.app-category.education` |
| Privacy manifest | `Tallhagen/PrivacyInfo.xcprivacy`: UserDefaults only (reason CA92.1), no tracking, no collected data |
| App icon | `Tallhagen/Assets.xcassets/AppIcon.appiconset/AppIcon.png`, 1024x1024 PNG without alpha |
| Scheme | `Tallhagen`, with unit tests (`TallhagenTests`) and UI tests (`TallhagenUITests`) |
| Networking, ads, purchases, accounts, analytics | None; the app is fully offline |
| Stored data | Four UserDefaults values: `learningLevel`, `speakNorwegian`, `solvedTotal`, `islandStars` (stars on the Talløyene map) |

The kit describes the app as it stands in this folder on 2026-11-06 (project version 11): the four activities and the Talløyene map (a fifth home card with numbered tasks on six islands, from number bars through the three games and place value up to 9999 to the equation balance, with padlocks and stars, its own reset in Settings and the fourth stored value). The number bars, place value and the equation balance exist only on the map, so the map cannot be removed on its own. Should it ever be removed before archiving, rewrite every text that names the map, the islands or those activities (both descriptions, promotional texts and release notes, and the map step and map rows of the glossary in `review_notes.md`), take the fourth value out of the privacy policy, `app_privacy.md` and `review_notes.md`, remove screenshots 04, 08, 09 and 10 from `AppStore/screenshots/13-inch/` and retake the home screenshots.

Button and field names below are those of App Store Connect in 2026; Apple renames things now and then, so look for the closest label if one differs.

## 1. Apple Developer Program (already in place)

You are already enrolled in the paid Apple Developer Program and publish EriksDay from the same account, so nothing has to be enrolled or accepted for Tallhagen. Two checks remain:

1. In Xcode > Settings > Accounts the team the project uses must be that paid team, listed without the words "(Personal Team)"; the Personal Team can install on your own iPad but cannot upload.
2. In App Store Connect > Agreements, Tax, and Banking the Program License Agreement must show as accepted; an updated agreement blocks uploads until the Account Holder accepts it. A free app needs no paid-applications agreement and no banking details.

## 2. Xcode: signing, bundle identifier, version and build (you, mostly done)

1. Open `Tallhagen.xcodeproj`, select the Tallhagen project in the navigator, then the Tallhagen target.
2. Signing & Capabilities: "Automatically manage signing" is on. Team must be the paid team from step 1 (not the Personal Team). Bundle Identifier is already `com.roysworld.tallhagen`; leave it. With a destination such as "Any iOS Device (arm64)" selected, the Signing section must show "Xcode Managed Profile" and no red error. If it says the identifier cannot be registered, see Troubleshooting.
3. General > Identity: Version 1.0, Build 1. These are the build settings `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`; the release script can override them per run (step 6). Display Name is Tallhagen, Minimum Deployments iPadOS 17.0, Supported Destinations iPad only, Device Orientation all four.
4. Build Settings > Info.plist Values: "App Uses Non-Exempt Encryption" (`INFOPLIST_KEY_ITSAppUsesNonExemptEncryption`) is NO. Check from the project root with:

   ```bash
   grep -c 'INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO' Tallhagen.xcodeproj/project.pbxproj
   ```

   The result should be 2 (Debug and Release). Without it App Store Connect asks the export compliance question for every build.
5. The test targets (`TallhagenTests`, `TallhagenUITests`) still use `com.example` identifiers. That is fine for the App Store: tests are not part of the archive. Change them only if you want to run the tests on a physical iPad.
6. Run the tests one last time from the project root:

   ```bash
   ./Tests/run.sh
   xcodebuild -project Tallhagen.xcodeproj -scheme Tallhagen \
     -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4),OS=18.2' test
   ```

   Also run the app once on a real iPad with the paid team selected (Product > Run with the iPad chosen as destination). That registers the bundle identifier for the team and checks touch, drag and speech on hardware.
7. Privacy policy and support pages, and the address inside the app: **done on 2026-11-06.** The pages are online on GitHub Pages, set up like EriksDay's: the public repository `github.com/riversen/Tallhagen` holds them in its `docs` folder, and they are served at
   - `https://riversen.github.io/Tallhagen/privacy.html`: the text of `AppStore/privacy-policy/index.html` with the effective date 6 November 2026 and the contact address filled in (the kit's copy keeps its placeholders, so no e-mail address is stored outside `docs/`);
   - `https://riversen.github.io/Tallhagen/support.html`: getting started, the questions parents ask, and the contact address;
   - `https://riversen.github.io/Tallhagen/`: a short start page that links to both.

   `privacy_url.txt` and `support_url.txt` in both language folders hold the two addresses, and `marketing_url.txt` holds `https://www.iversentechnology.com/`, as for EriksDay. Keep the pages at these addresses for as long as the app is in the store. To change the policy, edit `docs/privacy.html` in the repository (on github.com or in a clone), update the effective date in both languages, and make the same change in `AppStore/privacy-policy/index.html` and its Markdown copy `AppStore/privacy-policy/privacy-policy.md`; both keep their placeholders for the date and the contact address.

   App Review Guideline 5.1.1(i) requires the privacy policy to be accessible within the app, not only in App Store Connect, and a Kids-category app may not link out without a parental gate, so the app shows the address as plain text. `Tallhagen/Theme.swift` holds it:

   ```swift
   enum PrivacyPolicy {
       static let address = "https://riversen.github.io/Tallhagen/privacy.html"
   }
   ```

   Settings shows a "Personvern" section with the sentence "Appen samler ikke inn opplysninger. Personvernerklæring:" and the address on the line below, as plain text that is neither a link nor selectable: selectable text offers Share on a long press, and Settings has no parental gate. The section stays hidden while the address is empty, so no placeholder can ever reach a build. `Tools/release.sh` refuses to archive unless the address is an https address. `AppStore/metadata/review_notes.md` tells App Review that the address stands under Innstillinger.

## 3. App Store Connect: bundle identifier and the app record (you)

1. Bundle identifier. With automatic signing, Xcode registers `com.roysworld.tallhagen` as an App ID the first time it signs the app for the paid team (step 2.6 or the first archive). If it has not happened, register it by hand: developer.apple.com/account > Certificates, Identifiers & Profiles > Identifiers > + > App IDs > App > Description "Tallhagen", Bundle ID "Explicit" `com.roysworld.tallhagen`, no capabilities > Continue > Register. Until 2026-11-06 the project used `com.roysworld.Tallhagen`; if an App ID with that capitalisation is already in the list from an earlier run on a device, see Troubleshooting.
2. App record. In App Store Connect choose Apps > + > New App and fill in:
   - Platforms: iOS (an iPad-only app still belongs to the iOS platform).
   - Name: Tallhagen (from `AppStore/metadata/nb-NO/name.txt`; names are unique across the whole App Store, so if it is taken choose a variant of at most 30 characters, for example "Tallhagen: tall med prikker"; the kit's texts assume the Made for Kids choice of step 4.4).
   - Primary Language: Norwegian. App Store Connect lists the language simply as "Norwegian"; all texts in the kit are Bokmål.
   - Bundle ID: pick `com.roysworld.tallhagen` from the list. It appears only after the identifier is registered (step 3.1); wait a few minutes and reload if it is missing.
   - SKU: a private identifier that never shows in the store, for example `tallhagen-ipad-2026`.
   - User Access: Full Access.
3. Press Create. The app record opens on the "1.0 Prepare for Submission" page with "App Information", "Pricing and Availability" and "App Privacy" in the sidebar.

## 4. Fill the listing (kit texts, entered by you)

Each text lives in its own file under `AppStore/metadata/nb-NO/` (Norwegian, the primary language) and `AppStore/metadata/en-US/` (English, for the optional English (U.S.) localization). Paste the content of a file into the field named here; App Store Connect counts characters and refuses longer texts, and every kit text is within its limit (`AppStore/metadata/LIMITS.md` lists the measured counts and a small script to re-measure after an edit). The URL files hold the hosted addresses of step 2.7 and, in `marketing_url.txt`, `https://www.iversentechnology.com/`, as for EriksDay.

| App Store Connect field | Where | File | Limit |
| --- | --- | --- | --- |
| Name | App Information > Localizable Information | `name.txt` | 30 characters |
| Subtitle | App Information > Localizable Information | `subtitle.txt` | 30 characters |
| Privacy Policy URL | App Privacy > Privacy Policy > Edit | `privacy_url.txt` (hosted in step 2.7) | a public https address |
| Promotional Text | Version page (1.0) | `promotional_text.txt` | 170 characters; can be changed without a new build |
| Description | Version page (1.0) | `description.txt` | 4,000 characters |
| Keywords | Version page (1.0) | `keywords.txt` | 100 characters, comma separated, no spaces after commas |
| Support URL | Version page (1.0) | `support_url.txt` | a public https address |
| Marketing URL (optional) | Version page (1.0) | `marketing_url.txt` (`https://www.iversentechnology.com/`, as for EriksDay) | optional |
| What's New in This Version | Version page, from the second version on | `release_notes.txt` | 4,000 characters; the field does not exist for 1.0 |
| Copyright | Version page (1.0) | type `2026 Roy Iversen`, as for EriksDay | one line |

1. Localizations. The primary language is Norwegian; fill its fields first. To add English, use the language pop-up at the top right of the version page (and of App Information) and choose English (U.S.), then paste the `en-US` files into the same fields. A localization without screenshots of its own shows the primary language's set, so upload the images again under English only if you want different ones there.
2. Categories (App Information > General Information). Primary Category: Education. Secondary Category: optional. Tallhagen is listed as Made for Kids (age range 6–8); that selection is made inside the age rating dialog of step 4.4, not here. The Kids Category rules (no advertising, analytics, purchases or links out of the app, and a privacy policy) are met as built, and the selection cannot be undone after approval. `AppStore/metadata/age_rating.md` explains why the kit's texts require it (guidelines 2.3.8 and 5.1.4) and lists the replacement texts for the case that you refuse it.
3. Content Rights (App Information): answer "No" to the question whether the app contains, shows or accesses third-party content. Everything in Tallhagen is original.
4. Age Rating (App Information > Age Ratings > Set Up Age Ratings, later Edit): answer the questionnaire exactly as written in `AppStore/metadata/age_rating.md`: tick no in-app controls or capabilities, choose None or No for every content description, and under Age Categories and Override choose Made for Kids with the age range 6–8. The kit's texts require it; "Not Applicable" would mean rewriting every listing text without children as the audience (the replacements are at the end of `age_rating.md`). With every answer None or No the calculated rating is 4+, as for EriksDay.
5. App Privacy (sidebar > App Privacy): follow `AppStore/metadata/app_privacy.md`. First Privacy Policy > Edit: paste the privacy policy URL and leave User Privacy Choices URL empty. Then Data Collection > Get Started: the app collects no data, so the answer to "Do you or your third-party partners collect data from this app?" is No. Press Publish; the product page then shows "Data Not Collected".
6. Privacy policy and support pages: hosted in step 2.7. If an address ever changes, change its URL file, the App Store Connect field and `PrivacyPolicy.address` together, and upload a new build.
7. Pricing and Availability (sidebar): Price: Free (price 0 / the free tier). Availability: all countries and regions, or at least Norway. Pre-orders: off. The page also contains sections about offering the iPad app on Macs with Apple silicon and on Apple Vision Pro; the app has only been tested on iPads, so untick those if you want to keep the promise of an iPad app, or leave them on after trying it there.
8. Save every page (the Save button is at the top right) before leaving it.

## 5. Screenshots (you, from the simulator)

1. The screenshots live in `AppStore/screenshots/13-inch/`, filled by the maintainer from the iPad Pro 13-inch (M4) simulator: `portrait/` holds seven PNG files of 2064x2752 pixels (home, chooser, Bygg tallet in progress, the number bars of a Talløyene task with a tens rod in the building zone, Finn tallvennen, Del opp, Tallverkstedet) and `landscape/` three of 2752x2064 pixels (the Talløyene map, a place-value task with hundred tiles and tens rods, the equation balance), all without alpha channel and numbered in the intended order. A slot takes between 1 and 10 images; the seven portrait images are a complete set, and the three landscape ones follow at the end (the map is shown in landscape, where three islands and part of the fourth fit side by side). The first three images appear in search results, so the home screen and a game lead.
2. In App Store Connect open the version page > Previews and Screenshots and select the iPad tab. Drop the files into the "iPad 13" Display" slot (named after the 13-inch iPad Pro) and drag them into order.
3. The 12.9-inch (2nd generation) slot is optional and no longer required; App Store Connect scales the 13-inch set for every other iPad size. Fill it only if you want different images there.
4. Screenshots must show the app as it runs; device frames and marketing text are optional, and nothing from other apps, publishers or brands may appear. Retake them whenever a screen changes: on the iPad Pro 13-inch (M4) simulator, File > Save Screen (Command-S) produces the right pixel size. Check a new file with `sips -g hasAlpha <file>`; if it reports yes, convert it with `sips -s format jpeg <file> --out <file>.jpg` (App Store Connect accepts JPEG as well as PNG, but never transparency). If a landscape capture comes out as a portrait image, rotate it with `sips -r -90 <file>` before uploading. The kit's images show a fixed status bar (09:41, full battery, Wi-Fi), set before capturing with `xcrun simctl status_bar booted override --time 2026-11-05T08:41:00.000Z --dataNetwork wifi --wifiMode active --wifiBars 3 --batteryState charged --batteryLevel 100` (the time is UTC; the date beside it follows the day of the capture), and the stars on the map come from a launch argument, for example `xcrun simctl launch booted com.roysworld.tallhagen -islandStars "bars-build-5=3,bars-split-6=2,bars-build-10=3"`, which leaves the stored stars untouched.

## 6. Build and upload (kit script, run by you)

Both paths need the paid team in the project, Xcode 26.5 (or newer) and the Mac online, because signing for the App Store downloads the distribution certificate and profile from Apple. Xcode reaches Apple with the Apple ID signed in under Xcode > Settings > Accounts; path A can use the three `ASC_*` variables of an App Store Connect API key instead (see Authentication below). `PrivacyPolicy.address` already holds the hosted policy address (step 2.7), so both paths build it into the app.

Path A, the release script (from the project root):

```bash
./Tools/release.sh --dry-run            # checks only; prints the commands it would run
./Tools/release.sh                      # tests, archive, export a signed .ipa to ~/Desktop/Tallhagen-export-<timestamp>
./Tools/release.sh --upload             # tests, archive, upload straight to App Store Connect
BUILD_NUMBER=2 ./Tools/release.sh --upload           # the same with CURRENT_PROJECT_VERSION 2
VERSION=1.0.1 BUILD_NUMBER=3 ./Tools/release.sh --upload   # a later version
```

What it does, in order: refuses to run while the app's bundle identifier still starts with `com.example`; reads the team from the project file, where Xcode stored the one you chose (or takes `TEAM_ID` for this run only), and refuses when none is set; checks the icon, the privacy manifest and `AppStore/ExportOptions.plist`; refuses while `PrivacyPolicy.address` in `Tallhagen/Theme.swift` is not an https address (a dry run only warns); runs `./Tests/run.sh`; archives the Release configuration into `~/Library/Developer/Xcode/Archives/Tallhagen-<timestamp>.xcarchive`, where Xcode's Organizer (Window > Organizer > Archives) lists it; then exports with a temporary copy of `AppStore/ExportOptions.plist` in which `TEAM_ID_PLACEHOLDER` is replaced by your team id (the project copy is never changed). With `--upload` the export destination becomes `upload` and xcodebuild sends the build to App Store Connect. The script writes nothing inside the project folder, and `./Tools/release.sh --help` lists every variable. `TEAM_ID` is never written into the project; the team you chose in Xcode is stored there on purpose.

- `BUILD_NUMBER=<n>` is passed as `CURRENT_PROJECT_VERSION=<n>`; `VERSION=<x>` as `MARKETING_VERSION=<x>`. Without them the project values (1.0 and 1) are used. App Store Connect accepts each build number only once per version, and the export options leave the numbers unmanaged, so the number you pass is exactly what is uploaded.
- Authentication: by default xcodebuild uses the Apple ID signed in to Xcode. To use an App Store Connect API key instead (for example on a Mac where nobody is signed in), create one under App Store Connect > Users and Access > Integrations > App Store Connect API (role App Manager or Developer), download the `.p8` file once and keep it outside the project, then run with `ASC_KEY_PATH=/path/to/AuthKey_XXXX.p8 ASC_KEY_ID=<key id> ASC_ISSUER_ID=<issuer id>`.

Path B, Xcode: choose Product > Destination > Any iOS Device (arm64), then Product > Archive. The Organizer opens; select the archive and press Distribute App > App Store Connect > Upload. Keep "Upload your app's symbols" on and turn "Manage Version and Build Number" off so the numbers stay as in the project, then "Automatically manage signing" > Upload. Path B runs none of the script's checks and no tests: run the tests of step 2.6 and check with `./Tools/release.sh --dry-run`, which runs the script's checks without archiving (it only warns if `PrivacyPolicy.address` is empty or not an https address). (A signed `.ipa` from path A can also be uploaded with Apple's Transporter app, or from the Organizer via Distribute App with the same archive.)

After the upload:

1. App Store Connect processes the build for about 10 to 60 minutes and sends an e-mail when it has completed processing. Until then the build is not selectable anywhere.
2. Export compliance is already answered by the Info.plist key (`ITSAppUsesNonExemptEncryption = NO`; the reasoning is in `AppStore/metadata/export_compliance.md`). If a build nevertheless shows "Missing Compliance" under TestFlight > Builds, click it and answer that the app uses no encryption.
3. TestFlight is optional but worth one round: under TestFlight add yourself and family as internal testers (App Store Connect users, no review needed), install the TestFlight app on the iPad and accept the invitation. External testers need a short Beta App Review first. Tell testers that the compact Norwegian voice sounds mechanical and that a better one can be downloaded once under Settings > Accessibility > Read & Speak (Spoken Content on iPadOS 17 and 18) > Voices > Norwegian; the app notices it by itself.

## 7. Submit for review (you)

The list the release script prints after an upload is a short reminder. Do the steps below in their order: the contact details (7.2) and the release choice (7.3) come before Add for Review (7.4).

1. On the version page scroll to Build and press the plus sign (or "Add Build"), choose the processed build (1.0, build 1 or the latest) and press Done.
2. App Review Information: leave "Sign-in required" unchecked (there are no accounts). Enter your first name, last name, phone number and e-mail address in the Contact Information fields; they go only into App Store Connect. In Notes paste `AppStore/metadata/review_notes.md`; the field takes 4,000 characters and the file is just under (`AppStore/metadata/LIMITS.md` has the measured count), so if the field refuses it, shorten the glossary table. The notes already carry the Kids-category statement and say that the privacy policy address stands under Innstillinger (step 2.7). No attachment is needed.
3. Version Release: choose "Manually release this version" for a first release (you decide the day) or "Automatically release this version".
4. Press Save, then "Add for Review" at the top right, review the summary and press "Submit to App Review". The status changes to "Waiting for Review".
5. Timelines: most submissions move to "In Review" within one to two days and are decided within a day after that; a first submission and apps in the Kids category can take a little longer. A rejection arrives as a message in App Store Connect (App Review) that quotes a guideline number; answer in the same thread or fix, upload a new build (higher build number) and resubmit. "Pending Developer Release" means approved and waiting for you; "Ready for Distribution" means it is in the store.

## 8. After approval and every later update (you)

1. Release: with manual release, press "Release This Version" when you are ready; the app appears in the App Store within a few hours, and in search a little later. With automatic release it goes live as soon as it is approved.
2. For every later update, before archiving:
   - raise `CURRENT_PROJECT_VERSION` (the build number: 2, 3, ...) for every upload, even for the same version, in Xcode or with `BUILD_NUMBER`;
   - raise `MARKETING_VERSION` (the version: 1.0.1, 1.1, 2.0) for every version that reaches the public, in Xcode or with `VERSION`;
   - in App Store Connect press "+ Version or Platform" on the app page, enter the same version number, and write the "What's New in This Version" text in Norwegian and English (`release_notes.txt` in `AppStore/metadata/nb-NO/` and `en-US/` holds the first version's text as a model; write new text for each update);
   - replace screenshots if the screens changed, re-answer the age rating if content changed, keep the App Privacy answers as long as the app still collects nothing;
   - run `./Tests/run.sh` and the Xcode tests, then `./Tools/release.sh --upload` with the new numbers.
3. Keep every archive (the Organizer keeps them in `~/Library/Developer/Xcode/Archives`); they are needed to read crash reports for that build.
4. Updates may use a phased release (the version reaches automatic-update users over seven days); it is offered on the version page from the second version on.

## What was prepared for you and what only you can do

Prepared in the kit:

- `AppStore/metadata/nb-NO/` and `AppStore/metadata/en-US/`: name, subtitle, promotional text, description, keywords and release notes within App Store Connect's limits, plus URL files holding the hosted support and privacy addresses and the marketing page.
- `AppStore/metadata/review_notes.md`: notes for App Review with a glossary of the main Norwegian buttons.
- `AppStore/metadata/age_rating.md`, `AppStore/metadata/app_privacy.md` and `AppStore/metadata/export_compliance.md`: the answers for the age rating and App Privacy questionnaires and the export compliance reasoning; `AppStore/metadata/LIMITS.md` records the measured character counts.
- `AppStore/privacy-policy/index.html` (with a Markdown copy, `AppStore/privacy-policy/privacy-policy.md`): the privacy policy text, with placeholders for the date and your contact address.
- `github.com/riversen/Tallhagen` (GitHub Pages, from its `docs` folder): the hosted privacy policy with the date and contact filled in, a support page and a short start page (step 2.7).
- `AppStore/screenshots/13-inch/`: ten screenshots from the simulator at the required sizes, seven portrait and three landscape.
- `AppStore/ExportOptions.plist` and `Tools/release.sh`: a checked, repeatable archive, export and upload.
- In the project: the bundle identifier, version 1.0 and build 1, the encryption key, the privacy manifest, the alpha-free icon, the generated launch screen, the iPad-only settings and the tests.

Only you can:

- keep the paid team selected in Xcode and the Program License Agreement accepted;
- select the paid team in Xcode and run the app on a real iPad once;
- create the app record, choose categories, enter the age rating, App Privacy, pricing and availability;
- keep the pages in `github.com/riversen/Tallhagen` online at their addresses for as long as the app is in the store (step 2.7);
- review and upload the screenshots in `AppStore/screenshots/13-inch/`, and retake them if a screen changes;
- type your contact details for App Review;
- upload the build, submit, answer App Review and release;
- confirm the Made for Kids selection (step 4.4) and decide whether the app is offered on Macs and Apple Vision Pro.

## Troubleshooting

- "Missing Compliance" next to a build: the Info.plist key was missing or an older build was uploaded. Click the status, answer that the app uses no encryption, and check that `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` is in the project for the next upload.
- "Invalid App Store Icon. The App Store Icon in the asset catalog in 'Tallhagen.app' can't be transparent nor contain an alpha channel": regenerate the icon with `swiftc -O Tools/MakeIcon.swift -o /tmp/makeicon && /tmp/makeicon Tallhagen/Assets.xcassets/AppIcon.appiconset/AppIcon.png` and confirm with `sips -g hasAlpha Tallhagen/Assets.xcassets/AppIcon.appiconset/AppIcon.png` (must print "no"). The release script refuses to archive an icon with alpha.
- "The bundle version must be higher than the previously uploaded version" (or "CFBundleVersion must contain a higher version"): the same build number was already uploaded for this version. Run again with a higher `BUILD_NUMBER`, or raise the build number in Xcode > General.
- "The provided entity includes an attribute with a value that has already been used" or "The app name you entered is already being used": choose another name of at most 30 characters.
- Provisioning profile and certificate errors ("No profiles for 'com.roysworld.tallhagen' were found", "No signing certificate 'iOS Distribution' found", "Provisioning profile doesn't include signing certificate", "Communication with Apple failed"): make sure the team selected in Signing & Capabilities is the paid team, that the Apple ID is signed in under Xcode > Settings > Accounts (open the team there and press "Download Manual Profiles" or let automatic signing retry), that the Mac is online, and that the bundle identifier is registered to that team (step 3.1). A Personal Team always fails here. If a distribution certificate was created on another Mac, export it from that Mac's Keychain Access with its private key, or revoke it in Certificates, Identifiers & Profiles and let Xcode create a new one. The script needs `-allowProvisioningUpdates` to succeed, which requires a signed-in account or the three `ASC_*` variables.
- "An App ID with Identifier 'com.roysworld.tallhagen' is not available" (developer portal), "The app identifier 'com.roysworld.tallhagen' cannot be registered to your development team because it is not available" (Xcode, Signing & Capabilities), or a signing error that names `com.roysworld.Tallhagen`: until 2026-11-06 the project used that capitalisation, and the developer portal can treat identifiers that differ only in case as the same. If Certificates, Identifiers & Profiles > Identifiers lists `com.roysworld.Tallhagen` and no App Store Connect app uses it, open it and remove it, then let Xcode register `com.roysworld.tallhagen` (Product > Run on the iPad, or the next archive). To keep the old App ID instead, set the Bundle Identifier back to `com.roysworld.Tallhagen` in Xcode and pick that identifier as the app record's Bundle ID (step 3.2): the record and the build must carry the same bundle ID, and an upload that differs, even only in case, can stop with "No suitable application records were found". A record that already has the other identifier can be switched in App Information > General Information > Bundle ID (then Save) until the first build is uploaded; after that upload the record's bundle ID can no longer be changed and its App ID can no longer be removed.
- "Unable to process request - PLA Update available" or any "agreement" message during upload: the Account Holder has to accept the updated agreement in App Store Connect > Agreements, Tax, and Banking.
- The build never appears on the version page: it is still processing (wait for the e-mail), it was uploaded under a different bundle identifier, or it was rejected during processing (the e-mail says why, for example a missing icon size or a duplicate build number).
- The Norwegian voice sounds mechanical for testers or reviewers, or the iPad reads Norwegian with a foreign voice: the device has only the compact voice or none. Download Nora (Enhanced) or Nora (Premium) under Settings > Accessibility > Read & Speak (Spoken Content on iPadOS 17 and 18) > Voices > Norwegian; the app switches to it by itself. This is also explained in `AppStore/metadata/review_notes.md`.
- `./Tools/release.sh` refuses to start: read its message. It stops when the bundle identifier still starts with `com.example`, when no `DEVELOPMENT_TEAM` is in the project and `TEAM_ID` is not set, when `BUILD_NUMBER` or `VERSION` is malformed, when only some of the `ASC_*` variables are set, when `EXPORT_DIR` points inside the project, when `AppStore/ExportOptions.plist` no longer contains `TEAM_ID_PLACEHOLDER`, or when `PrivacyPolicy.address` in `Tallhagen/Theme.swift` is empty or not an https address (step 2.7).
