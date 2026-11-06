# Tallhagen – Norwegian iPad math game

An original, offline math game for children around 6–8 years old. The entire child-facing interface is in **Norwegian Bokmål**. It uses original graphics, visual number puzzles and independently written code. No third-party characters, educational-game branding, advertising, accounts or network services are included.

## What is included

| Activity | What children practice |
| --- | --- |
| **Bygg tallet** | Combine number pieces to reach a target number. Tap or drag pieces onto the answer area. Any combination with the right sum counts, pieces can be taken back, and an honest hint completes whatever the child has already placed. |
| **Finn tallvennen** | Find the missing addend in a visual equation. The missing amount is shown as empty slots the child can count; wrong answers show the real sum and whether it was too much or too little, and tried answers are marked "Prøvd". |
| **Del opp** | Divide a quantity into two groups with a slider and plus/minus buttons. Both groups always stay non-empty and always add back to the total. |
| **Tallverkstedet** | Free play: change two quantities and immediately see the total as a two-colour dot frame. A button reads the equation aloud in Norwegian. |
| **Talløyene** (version 8) | A textless map of garden islands: numbered stepping stones open one after another, each a short run of four puzzles of one activity at one range, rated 0–3 stars (finishing always earns one; the best result is kept). |
| **Likevekt** (version 10, on the map) | An equation balance on the sixth island: find the number hidden in a flower bud by laying the same card on both sides, letting opposite cards cancel, and splitting both sides into equal parts, from pictures to symbols. |
| **Plassverdi** (version 9, on the map) | Base-ten blocks for 11–9999 on the fifth island: build a number from unit squares, tens rods, hundred tiles and thousand cubes (ten of a kind become one of the next by themselves), read a number from its blocks, or take units away and break a ten when the ones run out. |
| **Tallstolpene** (version 8, on the map) | Number bars 1–10 as friendly characters on a unit grid. Drag or tap bars into the building zone to build a total (tens rods above ten), combine them by dropping one on another, cut them with a sideways swipe or a tap on a cut marker, or cut one bar into two wanted parts. |

Quantities are always shown as dots in rows of five, with a small gap after every ten, so 10, 20, 30 and 40 are easy to recognize; at the Til 100 level the rows hold ten dots, so 100 is ten rows of ten. Each activity has its own original, text-free icon drawn in code (a tower of pieces, a dot and its missing friend, a group cut in two, dots over plus and minus keys).

The whole app lives in an original garden drawn in code: a morning sky with a big sun and slow clouds, rolling hills with swaying daisies and tulips, a wooden signboard, and a grass footer with the sound button on every screen. Four friendly guide creatures, one per activity, idle on the home cards and beside each game title: a snail whose shell spiral turns as the child builds a number (Bygg tallet), a butterfly whose orange and teal wings are two parts of one whole (Finn tallvennen), a bumblebee (Del opp) and a hedgehog that sniffs at every plus and minus (Tallverkstedet). When a puzzle is solved the guide hops, flaps or loops once and a small flower sprouts at its feet; the home progress card is a flower bed with one flower per solved task. Nothing in the garden reacts to a wrong answer, nothing decorative sits near the counted dots, and the whole garden stands still under Reduce Motion.

Version 8 adds **Talløyene**, the number islands: from the home screen the child opens a pond with four islands (versions 9 and 10 add a fifth and a sixth), each hosted by one of the guides and carrying numbered stepping stones. Only the first stone is open at first; finishing its four puzzles opens the next, and every finished stone keeps its best 0–3 stars (few mistakes earn three, finishing always earns one). The first island teaches with **Tallstolpene**, number bars 1–10 drawn as original characters: every bar is as tall as its value on a unit grid, has its own deep colour and face, and shows a white numeral that grows stronger with the range (hidden while building to 5). Bars are tapped or dragged into a building zone that shows the target as a dashed outline, combine when dropped on each other (with a little squash and a ring of sparks), cut with a sideways swipe or a tap on a cut marker, and above ten the built total stands as tens rods beside a unit bar. The other islands replay Bygg tallet, Finn tallvennen and Del opp at 20, 40 and 100, and one more bar stone to 20 closes the second island. Inside a stone the screen keeps a minimal strip (back to the map, the stone's number, one leaf per solved puzzle, the guide) above the puzzle, in portrait and landscape. The stars live in one new local setting; Settings can reset them (and the locks) without touching the solved count.

Made for children who cannot read much yet: the first launch opens a chooser with three big cards (1–20, 1–40, 1–100) that are read aloud one by one while the card being named glows; the home menu is narrated the same way, every game reads its task aloud and has a **Les opp oppgaven** button, and a large sound button at the bottom of every screen turns the automatic speech off and on (the read-aloud buttons always speak).

Children pick among **Til 20**, **Til 40** and **Til 100** before they start (and again from the home screen's **Velg tall** button); Settings also offers **Til 10** and **Til 30**. Each level produces target totals of exactly its maximum in all three puzzle modes, and the workshop allows two positive numbers up to that maximum (39 + 1 and 20 + 20 are allowed at Til 40, 41 is never reachable; 99 + 1 at Til 100). The app counts one locally stored completed task per correct puzzle; the count survives level changes and relaunches and can be reset from Settings. Norwegian speech is on by default and can be turned off with the sound button or in Settings. There are no timers, lives, advertisements, accounts, analytics, subscriptions, online APIs or third-party packages.

## Run on a Mac with Xcode

Requirements: a Mac with Xcode 16 or newer (the iPadOS 17 SDK or newer). To install on your own iPad you also need an Apple ID and an iPad running iPadOS 17 or later. A paid Apple Developer Program membership is **not required** for personal development signing, though free provisioning has limitations (apps expire after 7 days and must be reinstalled).

1. Unzip **Tallhagen-iPad-v11.zip**, clone https://github.com/riversen/Tallhagen, or use this directory directly. Version 11 prepares the App Store release: the bundle identifier is now `com.roysworld.tallhagen`, and the privacy policy and support pages are online, with the policy address shown in Settings, in the public GitHub repository that also holds this source; version 10 adds Likevekt (the equation balance) on a sixth island; version 9 adds Plassverdi (place value with base-ten blocks) on a fifth island; version 8 adds Talløyene (the island map) and Tallstolpene (the number bars); version 7 makes the app use the best installed Norwegian voice and adds the App Store kit; version 6 added the garden scenery and the four guide creatures; version 5 added the Til 100 level, the first-launch chooser, narrated menus and the sound button; version 4 added the per-game icons; earlier archives are kept only for reference.
2. Open **Tallhagen.xcodeproj** in Xcode. The shared **Tallhagen** scheme is included.
3. Select the **Tallhagen** target. Under **Signing & Capabilities**, the project carries the owner's bundle identifier `com.roysworld.tallhagen` and team. To install with your own Apple ID, choose your **Personal Team** and change the **Bundle Identifier** to one unique to you (for example `com.yourname.Tallhagen`). Do the same for the `TallhagenTests` and `TallhagenUITests` targets only if you want to run the tests on a physical iPad.
4. Choose an **iPad Simulator**, or connect your iPad with a cable and select it in the device list.
5. Press **Run** (Command–R).
6. On a physical iPad, iPadOS will ask you to trust the developer: **Settings › General › VPN & Device Management › your Apple ID › Trust**. On iPadOS 16 and later you may also need to enable **Developer Mode** under **Settings › Privacy & Security** and restart once.

The app installs as **Tallhagen** with its own icon. The iPad cannot install the ZIP or the source files directly; Xcode builds and signs the app first.

From the command line, a simulator build looks like this:

```bash
xcodebuild -project Tallhagen.xcodeproj -scheme Tallhagen -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4),OS=18.2' build
```

## Publishing on the App Store

The project is ready to be submitted as **Tallhagen 1.0** (build 1). The numbers of the ZIP archives (version 8, 9, 10 …) count development rounds of this folder; App Store Connect only sees the marketing version and build number set in the project. The owner's bundle identifier `com.roysworld.tallhagen` and team are set, the generated Info.plist declares the Education category and the no-encryption answer, the privacy manifest declares only the local UserDefaults use, and the app icon has no alpha channel. The App Store kit in `AppStore/` came with version 7 and is kept in step with every later version: listing texts in Norwegian Bokmål and English (`AppStore/metadata`, one field per file, measured against the limits in `LIMITS.md`), review notes, the App Privacy, age-rating and export-compliance answers, the privacy policy text (`AppStore/privacy-policy`; its hosted copy is on GitHub Pages, step 3 below) and 13-inch iPad screenshots (`AppStore/screenshots/13-inch`).

**`AppStore/SUBMISSION-CHECKLIST.md` is the complete step-by-step guide**, with troubleshooting. In short, in this order:

1. **Account.** In Xcode › Settings › Accounts use the paid Apple Developer Program team, not the Personal Team. In App Store Connect › Agreements, Tax, and Banking the Program License Agreement must be accepted (checklist step 1).
2. **Test on a real iPad.** Run `./Tests/run.sh` and the Xcode tests described below. Then run the app once on an iPad with the paid team selected; this also registers the bundle identifier (step 2).
3. **Privacy policy and support page.** Done in version 11: both pages are online at https://riversen.github.io/Tallhagen/privacy.html and https://riversen.github.io/Tallhagen/support.html, served by GitHub Pages from the `docs` folder of the public repository github.com/riversen/Tallhagen, set up like EriksDay's. That repository also holds this project's source; its `docs` folder exists only there, because the hosted pages carry the contact address, which the project folder and the ZIP never contain (in a clone, only `docs/` holds it). `PrivacyPolicy.address` in `Tallhagen/Theme.swift` holds the policy address, which Settings shows as plain text, as Apple requires, and the URL files in `AppStore/metadata` hold both addresses and the marketing page https://www.iversentechnology.com/. To change the policy later, edit `docs/privacy.html` in that repository and update its date, then make the same change in both kit copies, `AppStore/privacy-policy/index.html` and `AppStore/privacy-policy/privacy-policy.md`, which keep their placeholders for the date and the contact address (checklist step 2.7).
4. **App record.** In App Store Connect choose Apps › + › New App: platform iOS, name Tallhagen, primary language Norwegian, bundle ID `com.roysworld.tallhagen`, any private SKU (step 3).
5. **Listing.** Paste the files of `AppStore/metadata/nb-NO` into their fields, and `en-US` for an optional English localization. Choose the Education category, answer the age rating with Made for Kids 6–8 (the rating comes out as 4+, as for EriksDay) and App Privacy with Data Not Collected exactly as the files in `AppStore/metadata` say, type `2026 Roy Iversen` as the copyright, and set the price to free (step 4).
6. **Screenshots.** Upload the PNG files of `AppStore/screenshots/13-inch`, portrait first, to the iPad 13-inch slot (step 5).
7. **Build and upload.** From the project root, check first, then build and upload:

   ```bash
   ./Tools/release.sh --dry-run
   ```

   ```bash
   ./Tools/release.sh --upload
   ```

   The script runs its checks and the logic tests, archives the Release build and sends it to App Store Connect. Xcode's Product › Archive followed by Distribute App › App Store Connect uploads by hand, but runs neither the tests nor the script's checks, so run the tests and `./Tools/release.sh --dry-run` first (step 6).
8. **Submit.** When the build has processed (App Store Connect sends an e-mail, usually within an hour), add it to the 1.0 version page, paste `AppStore/metadata/review_notes.md` into the review notes, enter your contact details, choose manual or automatic release, then press Add for Review and Submit to App Review (step 7).
9. **Updates.** Every later upload needs a higher build number and every public update a higher version, for example `VERSION=1.0.1 BUILD_NUMBER=2 ./Tools/release.sh --upload`. Write new release notes and retake the screenshots of changed screens (step 8).

## For a child

1. Start with **Til 10**, even if the child is comfortable with larger numbers. Change levels at any time in *Innstillinger*.
2. Try **Tallverkstedet** first to discover the dot quantities.
3. Move on to **Bygg tallet** and **Finn tallvennen**.
4. Use **Del opp** to connect addition and subtraction.

## Local data and privacy

Four values are saved locally with `@AppStorage` (Apple UserDefaults): the chosen level, whether speech is on (default on), the completed-task count, and the stars earned on Talløyene (`islandStars`, one short text; which stones are open follows from it). The level chooser opens by itself only while no level has been saved yet. The app makes no network requests, asks for no permissions, and its privacy manifest declares only this local UserDefaults use. Removing the app removes the saved progress.

Speech uses Apple's on-device speech synthesis with the best Norwegian voice installed on the iPad: Bokmål before any other Norwegian voice, and Premium over Enhanced over the compact default voice. A fresh iPad only has the compact "Nora" voice, which sounds rather mechanical; for a much more natural voice, download **Nora (Enhanced)** or **Nora (Premium)** once under Settings › Accessibility › Read & Speak (Spoken Content on iPadOS 17 and 18) › Voices › Norwegian (a few hundred megabytes, Wi-Fi recommended). The app notices the download by itself, with no setting to change. Siri's own voices are not available to apps. If no Norwegian voice is installed at all, the iPad's default voice reads the Norwegian text and may mispronounce it. With "Les opp på norsk" on, each puzzle's task, every feedback and every hint is read aloud; every game also has a **Les opp oppgaven** button that reads the task on demand, and the workshop reads its equation on demand. While VoiceOver is running, VoiceOver announces the same text and the app's own automatic speech stays quiet. The app is fully usable without speech and always uses its light paper palette (it does not follow Dark Mode).

The garden and its creatures are decoration only: hidden from VoiceOver, never in the way of a tap, and readable text always sits on white, paper, a cloud veil or the signboard. With Reduce Motion on, the garden is a still picture and the creatures only fade between expressions; Increase Contrast replaces the sky with plain paper; Reduce Transparency makes the cloud veils opaque.

## Project structure

- `Tallhagen.xcodeproj/` – native iPad Xcode project with three targets (app, unit tests, UI tests) and a shared scheme
- `Tallhagen/TallhagenApp.swift` – app entry point
- `Tallhagen/HomeView.swift` – home screen, level chooser, settings, the progress flower bed and the drawn `GameIcon` views
- `Tallhagen/Games.swift` – the four playable game screens
- `Tallhagen/Challenges.swift` – a map node as a challenge: the status strip, the run counter and the completion card
- `Tallhagen/IslandMap.swift` – Talløyene: the island map, its nodes and the home map card
- `Tallhagen/NumberBars.swift` – Tallstolpene: the number bars, their faces and the bar activity
- `Tallhagen/PlaceValue.swift` – Plassverdi: base-ten blocks, the tray and the regrouping workspace
- `Tallhagen/Balance.swift` – Likevekt: the bud, the cards, the board and the division rail
- `Tallhagen/CommonViews.swift` – reusable visual building blocks (dot frames, cards, buttons, scaffold, grass footer)
- `Tallhagen/GardenScenery.swift` – the garden palette, backdrop (sky, sun, clouds, hills, flowers), flower and meadow views
- `Tallhagen/GardenCreatures.swift` – the four guide creatures and their idle, attentive and happy poses
- `Tallhagen/Theme.swift` – colours, typography, storage keys, speech, haptics
- `Tallhagen/MathLogic.swift` – Foundation-only puzzle generators, number rules, bar rules, the map and its progress rules
- `Tallhagen/GameSessions.swift` – Foundation-only state machines for the activities, the bars and a challenge run, and the Norwegian feedback copy
- `Tallhagen/Assets.xcassets/` – original app icon (generated by `Tools/MakeIcon.swift`)
- `Tools/MakeIcon.swift` – renders the app icon with CoreGraphics on a Mac; not part of any Xcode target
- `Tools/release.sh` – archives the Release build for iPad and exports or uploads it for App Store Connect
- `AppStore/` – App Store submission kit: listing texts, privacy policy, questionnaire answers, screenshots, checklist and export options
- `Tallhagen/PrivacyInfo.xcprivacy` – privacy manifest
- `Tests/` – shared invariant checks, a seeded random generator and a swiftc-only runner (`run.sh`)
- `TallhagenTests/` – XCTest unit tests that reuse the shared checks on the simulator
- `TallhagenUITests/` – XCUITest flows that drive the real app on an iPad simulator
- `agent.md` – detailed implementation, pedagogy, architecture, privacy, testing and delivery instructions for coding agents
- `AGENTS.md` – conventional agent entry point referring to `agent.md`

## Tests

Logic tests without Xcode (macOS or Linux with Swift installed):

```bash
./Tests/run.sh
```

This compiles the two Foundation-only files with the shared checks and runs about 6 million individual checks: all five levels, 10,000 seeded randomized puzzles per level and generator (and per range for the bar tasks and per level and task for place value), every target from the smallest through exactly 40 and 100 (and through 9999 for place value), the session state machines (correct and incorrect answers, locking after completion, undo, hints, bar combining and cutting), the island map with its stars and unlock rules, the place-value blocks (carrying, borrowing, reading, taking away), the equation balance (mirrored cards, cancellation, division, stars), and the workshop limits. The seed is fixed, so a failure is reproducible.

Unit and UI tests on an iPad simulator:

```bash
xcodebuild -project Tallhagen.xcodeproj -scheme Tallhagen \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4),OS=18.2' test
```

Add `-only-testing:TallhagenTests` or `-only-testing:TallhagenUITests` to run one bundle.

## Verification status

- Logic tests (`./Tests/run.sh`): pass on macOS with Swift 6.3 (about 6 million checks since version 10; 5,950,451 in the recorded run).
- Xcode 26.5: the app builds for the iPad simulator on both iOS 18.2 (iPad Pro 13-inch, M4) and iOS 17.0 (iPad 10th generation, the deployment target), and launches on both; every source also type-checks against the iOS 17.0 SDK without warnings.
- The 16 XCTest unit tests and the 9 XCUITest UI tests pass on the iPad Pro 13-inch (M4) simulator running iOS 18.2 (version 6, one complete run). Section 10 of `agent.md` records the exact results.
- The garden screens were checked by screenshot on the simulator in portrait and landscape (home, chooser, a game before and after solving). Reduce Motion, Increase Contrast, Split View and a physical iPad have **not** been exercised. Do a device check (touch, drag and drop, speech, smoothness of the garden on an older iPad) before relying on this as a finished product.
- Version 7: 20 unit tests and 9 UI tests pass in one run on the iOS 18.2 simulator; a Release archive for a real iPad builds (unsigned); the store keys are present in the archived bundle. A signed upload has **not** been performed from this environment.
- Version 11: 36 unit tests and 14 UI tests pass in one run on the iOS 18.2 simulator after the last code change (5,950,451 logic checks); the iOS 17.0 build succeeds and the built app carries `com.roysworld.tallhagen`; the privacy address in Settings was checked on the simulator (plain text, no Copy or Share menu on a long press); the three hosted pages return HTTP 200 and match the published files; see section 10 of `agent.md`.
- Version 10: 36 unit tests and 14 UI tests pass in one run on the iOS 18.2 simulator (5,950,451 logic checks); the balance screens were checked by screenshot in portrait and landscape; see section 10 of `agent.md`.
- Version 9: 32 unit tests and 13 UI tests pass in one run on the iOS 18.2 simulator (5,566,096 logic checks); the place-value screens were checked by screenshot in portrait and landscape; see section 10 of `agent.md`.
- Version 8: 28 unit tests and 12 UI tests pass in one full run on the iOS 18.2 simulator after a review that found and fixed a hint crash; see section 10 of `agent.md` for that run, the iOS 17.0 build and the simulator screenshots of the map and the bars in portrait and landscape. Dragging bars with a finger, speech and the animations on a real iPad have **not** been tried.

The ZIP holds the source project, not a signed app: Xcode builds and signs it for your own iPad, and `Tools/release.sh` builds the App Store version as described under Publishing on the App Store. No signed upload has been performed from this environment.

## For maintainers and coding agents

Read **`agent.md`** before changing the project. It documents the intended behaviour, mathematical invariants, number-range rules, privacy requirements, source ownership rules, automated verification commands and manual iPad acceptance checks.
