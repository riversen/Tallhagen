# AppStore: the submission kit for Tallhagen

Everything in this folder exists to get Tallhagen 1.0 (bundle identifier `com.roysworld.tallhagen`, iPad only) through App Store Connect. Start with `SUBMISSION-CHECKLIST.md`; the other files are the material it refers to. Paths below are relative to the project root. Nothing in this folder contains the owner's e-mail address, phone number or team identifier; App Store Connect asks for those separately.

## Files and folders

| Path | What it is |
| --- | --- |
| `AppStore/SUBMISSION-CHECKLIST.md` | Step-by-step guide in English: Xcode signing, the app record, the listing, screenshots, build and upload, review, release and later updates, plus troubleshooting. |
| `AppStore/README.md` | This index. |
| `AppStore/ExportOptions.plist` | Template for `xcodebuild -exportArchive` (method app-store-connect, automatic signing, symbols uploaded, version and build number left unmanaged). The team id is the literal `TEAM_ID_PLACEHOLDER`; `Tools/release.sh` substitutes the real one in a temporary copy outside the project. Never write a real team id into this file. |
| `AppStore/metadata/nb-NO/` | Norwegian (Bokmål) listing texts, the primary language: `name.txt`, `subtitle.txt`, `promotional_text.txt`, `description.txt`, `keywords.txt`, `release_notes.txt`, `support_url.txt`, `marketing_url.txt`, `privacy_url.txt`. One file per App Store Connect field; the checklist says which field and which character limit. The three URL files hold the hosted support and privacy addresses (GitHub Pages, checklist step 2.7) and the marketing page. `nb-NO` names the language of the texts (Bokmål); App Store Connect calls this localization simply Norwegian, locale code `no`, so rename the folder to `no` should a tool that uploads metadata from such folders ever read it. |
| `AppStore/metadata/en-US/` | The same fields in English, for an optional English (U.S.) localization of the listing. |
| `AppStore/metadata/LIMITS.md` | The measured character count of every metadata file against its App Store Connect limit, with the script that measures them. |
| `AppStore/metadata/review_notes.md` | Notes for App Review: how to try the app in a minute, a Norwegian-to-English glossary, speech, privacy, the Kids-category statement and other facts. Pasted into the Notes field of App Review Information (4,000 characters; the file is just under). |
| `AppStore/metadata/age_rating.md` | Answers for the age rating questionnaire, line by line, why the listing texts require the Made for Kids (6–8) selection, what it binds the app to, and the replacement texts should the owner refuse it. |
| `AppStore/metadata/app_privacy.md` | Answers for the App Privacy section: the app collects nothing, so the product page shows Data Not Collected. |
| `AppStore/metadata/export_compliance.md` | Why the export compliance answer is No and how the `ITSAppUsesNonExemptEncryption` key is set through the build settings. |
| `AppStore/privacy-policy/index.html` | The privacy policy page (Norwegian and English on one page). Its hosted copy, with the date and contact filled in, is `docs/privacy.html` in the public repository `github.com/riversen/Tallhagen`, served at https://riversen.github.io/Tallhagen/privacy.html; this copy keeps the placeholders. `privacy-policy.md` in the same folder is a Markdown copy with the hosting notes. |
| `AppStore/screenshots/13-inch/` | Filled by the maintainer from the simulator (iPad Pro 13-inch (M4)) for the iPad 13-inch display slot in App Store Connect: `portrait/` holds seven PNG files of 2064x2752 pixels and `landscape/` three of 2752x2064 pixels (the Talløyene map, a place-value task, the equation balance), none with an alpha channel, numbered in the intended order; the ten fill the slot. |
| `Tools/release.sh` | Release script: refuses placeholder bundle identifiers and a missing team, runs `./Tests/run.sh`, archives the Release configuration, exports a signed `.ipa` (or uploads with `--upload`). `./Tools/release.sh --help` lists the environment variables (`TEAM_ID`, `BUILD_NUMBER`, `VERSION`, `EXPORT_DIR`, `ASC_KEY_PATH`, `ASC_KEY_ID`, `ASC_ISSUER_ID`); `--dry-run` shows the commands without building. |
| `Tools/MakeIcon.swift` | Regenerates the 1024x1024 app icon without an alpha channel, should the icon ever change. |

## Facts the kit relies on

- Project: `Tallhagen.xcodeproj`, scheme `Tallhagen`, Release configuration, `MARKETING_VERSION` 1.0, `CURRENT_PROJECT_VERSION` 1, automatic signing with the team set in Xcode, iPadOS 17.0 or later, iPad only, all four orientations.
- The Info.plist is generated from build settings (`GENERATE_INFOPLIST_FILE = YES`), including `ITSAppUsesNonExemptEncryption = NO`, so App Store Connect does not ask the export compliance question for each build, and `LSApplicationCategoryType = public.app-category.education`.
- The privacy manifest `Tallhagen/PrivacyInfo.xcprivacy` declares only UserDefaults (reason CA92.1), no tracking and no collected data. The app stores four UserDefaults values (`learningLevel`, `speakNorwegian`, `solvedTotal`, `islandStars`); the privacy policy, `app_privacy.md` and `review_notes.md` name all four.
- The listing texts name children as the audience, which App Review Guidelines 2.3.8 and 5.1.4 allow only with the Made for Kids selection (checklist step 4.4); `age_rating.md` holds the replacement texts for the other case.
- Guideline 5.1.1(i) also wants the privacy policy reachable inside the app: `PrivacyPolicy.address` in `Tallhagen/Theme.swift` (checklist step 2.7) puts the hosted address (https://riversen.github.io/Tallhagen/privacy.html) on the Settings screen as plain text, and `Tools/release.sh` refuses to archive unless it is an https address.
- The app icon `Tallhagen/Assets.xcassets/AppIcon.appiconset/AppIcon.png` is 1024x1024 without alpha.

Before submitting, run `./Tests/run.sh` and the Xcode tests described in the project `README.md`; the release script runs the logic tests on its own, the Xcode tests are a separate step.
