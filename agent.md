# Tallhagen: detailed instructions for coding agents

**Project:** Tallhagen, an original, offline Norwegian-language mathematics game for iPad.

**Audience:** Children aged approximately 6–8, with adult supervision optional. The application should be usable by a child who can recognize numbers but is still learning how quantities, addition, and subtraction work.

**Project status:** Playable implementation with four activities and five selectable number limits (10, 20, 30, 40 and 100; the child's chooser offers 20, 40 and 100). Version 6 stands every screen in an original, gently animated garden (sky, sun, hills, flowers, a grass footer) with four guide creatures drawn in code, one per activity. Version 7 uses the best installed Norwegian voice and is the first store-ready package: the owner's bundle identifier and team are in the project, the store keys are generated into Info.plist, a Release archive for a real iPad builds, and `AppStore/` holds the submission kit (section 9). Version 8 adds **Talløyene**, a textless map of islands with numbered, star-rated stops that unlock one after another, and **Tallstolpene**, number bars 1–10 drawn as original characters, played inside a minimal status strip. Version 9 adds **Plassverdi** on a fifth island: base-ten blocks for 11–9999 with automatic carrying and borrowing. Version 10 adds **Likevekt** on a sixth island, Likevektsøya: an equation balance with a hidden bud, mirrored cards, cancellation and division in three scaffold phases, with no negative amounts. Version 11 prepares the store release without changing the games: the bundle identifier is `com.roysworld.tallhagen` (lowercase, at the owner's request), the privacy policy and a support page are hosted on GitHub Pages (public repository `riversen/Tallhagen`, folder `docs`), the same repository holds the project source, like EriksDay's, and `PrivacyPolicy.address` shows the policy address in Settings. Version 12 (store version 1.1, build 2) adds quiet, original sound cues synthesised in code: a paper slide for a choice, a tick for a change, a soft knock for a refused move, a chime for a solved task and a faint applause for a finished task on Talløyene; they follow the sound button. The Foundation-only math logic and the per-activity state machines are tested with plain `swiftc` on macOS or Linux and, through the same shared checks, with XCTest on an iPad simulator. XCUITest flows drive the real app on the simulator. An iPad simulator build with Xcode 26.5 has been performed and is recorded in section 10. Testing on a physical iPad with a child has **not** been done in this repository's development environment.

**Highest-priority instruction:** Preserve a calm, tactile, child-friendly learning experience. Never trade mathematical correctness, child privacy, originality, or accessibility for animation or game mechanics.

---

## 1. Scope and intended product

Build and maintain a native iPad application in **Swift 5 / SwiftUI** that teaches the meaning of numbers through visible quantities and hands-on arithmetic. The default interface language is **Norwegian Bokmål**, including task text, feedback, settings, and voice locale. English appears in source documentation, not in the child's interface.

Currently implemented:

1. **Bygg tallet** — select or drag number pieces and combine their values to reach a target. Any composition with the right sum counts; pieces can be taken back; a hint completes what is already placed or suggests removing a piece when nothing fits.
2. **Finn tallvennen** — find the missing positive addend in an addition equation with four candidate answers. The missing amount is shown as empty slots in a dot frame; wrong answers show the real sum and whether it was too much or too little.
3. **Del opp** — distribute a visible collection into two nonempty groups with a slider or plus/minus controls, then check the answer.
4. **Tallverkstedet** — freely increase or decrease two positive quantities while observing their combined value as a two-colour dot frame, with an explicit read-aloud button.
5. **Talløyene** (version 8) — a textless map of garden islands in a pond, reached from the home screen. Each island is hosted by one of the four guides and carries numbered stepping stones: a padlock while locked, the number once open, 0–3 stars underneath once complete. A stone is a *challenge*: four puzzles of one activity at one fixed range, played inside a minimal status strip (back to the map, node number, one leaf per solved task, the guide) instead of the usual title row. Completing a stone opens the next one; stars reward few mistakes and the best result is kept.
6. **Tallstolpene** (version 8, map only) — number bars 1–10 as original characters: fixed width, height proportional to the value on a unit grid, a distinct deep colour and a simple face per value, a white numeral whose opacity grows with the range. *Bygg med stolper*: drag or tap bars into the building zone until its total equals the target (totals above ten stand as tens rods beside a unit bar); bars combine when dropped on each other and split with a sideways swipe or a tap on a cut marker. *Del stolpen*: cut one bar into two wanted parts.
7. **Plassverdi** (version 9, map only) — base-ten blocks for 11–9999 on the fifth island, Tusenøya, with its own level set (`PlaceValueLevel`: 11–19, 20–99, 100–999, 1000–9999) independent of `LearningLevel`. *Vis tallet*: drag or tap blocks (units, tens rods, hundred tiles, thousand cubes) from the tray onto the workspace until it shows the target; ten blocks of a place regroup into one of the next by themselves (a carry). *Les tallet*: read the blocks and pick the number among four. *Ta bort og veksle*: start with the blocks for a number and take units away; when the ones run out, break a ten into ten units (a borrow). Every block is countable: units are small squares, rods carry ten unit lines, tiles a ten-by-ten grid, cubes a gridded front face.
8. **Likevekt** (version 10, map only) — the equation balance on the sixth island, Likevektsøya: a two-sided board on a post with the hidden number as a closed flower bud, positive cards (warm, filled) and inverse cards (cool, dashed). Every card the child lays on the left gets a mirror on the right, an inverse card takes its amount away from the cards beside the bud and on the right (the pair vanishes as zero), a division rail under the board splits both sides into equal parts, and three scaffold phases lead from pictures only through pictures with numerals and signs to symbols such as `2 · ? + 3 = 11`. When the bud stands alone it opens and shows its number; the move count and 1–3 stars rate the solution against the shortest one. No amount on the board is ever negative.

Difficulty levels:

| Stored level ID | Norwegian label | Maximum represented total | Primary use |
| --- | --- | --- | --- |
| 1 | Til 10 | 10 | Beginning quantity recognition |
| 2 | Til 20 | 20 | Number bonds and early arithmetic |
| 3 | Til 30 | 30 | Larger quantities |
| 4 | Til 40 | 40 | Extended arithmetic and visual quantity sense |
| 5 | Til 100 | 100 | Large quantities in rows of ten |

**All four activities must respect the selected maximum.** A 40-level activity must actually be capable of presenting or producing the total **40**, not merely numbers below 40, and the 100-level the total **100**. A total of 41 (or 101) is never allowed in those levels. Within these activities, operands must remain positive, so a single component can be at most 39 when it is paired with another positive component to make 40 (99 for 100).

Before the first game the child picks one of three ranges, **Til 20**, **Til 40** or **Til 100** (`LearningLevel.starterChoices`), on a chooser built for non-readers: big numbers with their dots, read aloud with a glow. Til 10 and Til 30 remain in Settings for adults.

The four free-play activities follow the chosen level. The map's stones carry their own fixed ranges (`IslandMap.standard`, section 5): bars to 5, 6, 10 and 10 on the first island, then Bygg tallet, Finn tallvennen and Del opp at 20, 40 and 100 on the next three (with one more bar node, *Bygg med stolper til 20*, closing the second island), so the map is a journey through the same mathematics in order, independent of the free-play level.

### Explicit non-goals in the present version

Do not assert that the app already provides features it does not implement. At present it has no multiplication lessons, multi-child profiles, cloud synchronization, detailed learning analytics, adaptive skill-placement system, teaching curriculum certificate, custom character voice acting, Apple App Store deployment, or signed distributable IPA. These would be future tasks requiring separate design, code, and tests.

## 2. Originality and intellectual-property requirements

This must remain independently developed software with its **own visual identity**, wording, code, exercises, name, icon, and user-interface behavior. The existence of other number-learning programs is not permission to borrow their artwork, mascots, animation assets, screenshots, lesson copy, sounds, or distinctive expressive UI arrangements.

Nonnegotiable rules for any agent modifying the project:

- Do not import, trace, derive, or repackage artwork from a third-party educational product.
- Do not introduce another educational publisher's product, company, or character names into source files, app metadata, documentation, comments, assets, filenames, or identifiers.
- Avoid resembling a recognizable third-party character merely by changing colors or facial features. The current game expresses quantities with simple dots and cards rather than character imitations.
- Use only original content, Apple's standard SF Symbols, and assets with explicit compatible license documentation. The four activity icons are `GameIcon` views in `HomeView.swift`, drawn from plain shapes (no artwork files); keep them abstract dot-based motifs, not characters.
- The garden scenery (`GardenScenery.swift`) and the four guide creatures (`GardenCreatures.swift`: a snail for Bygg tallet, a butterfly for Finn tallvennen, a bumblebee for Del opp and a hedgehog for Tallverkstedet) are original drawings built from SwiftUI shapes, with no artwork files. They are generic garden animals with simple faces and were deliberately designed away from the signature characters of commercial learning products: no ladybug, no spotted characters, no numerals with faces, no sun with a face or rays, no chunky 3D card style. The working names used in code comments (Rulle, Flagra, Summa, Noste) are never displayed or spoken and must stay out of child-facing copy, app metadata and assets.
- The number bars (`NumberBars.swift`) are plain rounded columns in ten deep colours with dot eyes, a line mouth and unit lines, no limbs, no numerals with faces and no third-party likeness; the islands of the map (`IslandMap.swift`) are sand-rimmed grass ellipses in a pond with the four guides as hosts, stepping stones and padlocks drawn from SF Symbols and plain shapes. Keep both families generic and garden-like.
- The app icon is rendered by original code in `Tools/MakeIcon.swift` (a full-bleed teal square, three soft circles and a white card with seven dots) and contains no third-party material. Regenerate it with that script rather than pasting artwork of unknown origin.
- If you introduce a third-party library or asset, document its origin, license, reason for use, and privacy implications. Prefer no dependencies.
- Keep icons and interface elements meaningfully distinct from any commercial educational app.
- Before every release, perform a source-and-assets review for third-party references or unlicensed inclusions.

This section is policy for future contributors, not a claim that an external legal review has occurred.

## 3. Architecture and current source map

```text
Tallhagen-iPad/
├── README.md                        Setup, functionality, status, limitations
├── agent.md                         This full development and QA specification
├── AGENTS.md                        Discovery entry point for agentic coding tools
├── .gitignore                       Keeps ZIPs, Xcode user data, build output and signing material out of git
├── docs/                            Repository only: hosted start, support and privacy pages (GitHub Pages, main:/docs); never in the ZIP
├── Tallhagen.xcodeproj/
│   ├── project.pbxproj              App target, unit-test target, UI-test target, build settings
│   └── xcshareddata/xcschemes/
│       └── Tallhagen.xcscheme       Shared scheme: builds the app, tests both test bundles
├── Tallhagen/
│   ├── TallhagenApp.swift           @main app, HomeView entry point, Dynamic Type cap
│   ├── MathLogic.swift              Foundation-only levels, generators, rules (seedable)
│   ├── GameSessions.swift           Foundation-only per-activity state machines + Norwegian copy
│   ├── SoundRecipes.swift           Foundation-only synthesis of the quiet sound cues + their play gate
│   ├── Theme.swift                  Colors, fonts, storage keys, game catalog, speech, sound cues, haptics
│   ├── CommonViews.swift            Dot frames, panels, buttons, piece cards, status, scaffold, grass footer
│   ├── GardenScenery.swift          Garden palette, backdrop (sky, sun, clouds, hills, flowers), flower, meadow
│   ├── GardenCreatures.swift        The four guide creatures (snail, butterfly, bee, hedgehog) and their moods
│   ├── HomeView.swift               Home menu, level chooser, settings sheet, progress bed, GameIcon drawings
│   ├── Games.swift                  Four concrete activity views on top of the sessions
│   ├── Challenges.swift             ChallengeHost, challenge play screen, status strip, completion card (map nodes)
│   ├── IslandMap.swift              Talløyene: the island map screen, islands, nodes, glyphs, the home map card
│   ├── NumberBars.swift             Tallstolpene: bar palette, faces, bar views, the bar activity with its gestures
│   ├── PlaceValue.swift             Plassverdi: base-ten blocks, the tray, the regrouping workspace, read and take-away tasks
│   ├── Balance.swift                Likevekt: the bud, the cards, the board with its mirrored cards and the division rail
│   ├── Assets.xcassets/             App icon (generated by Tools/MakeIcon.swift, original)
│   └── PrivacyInfo.xcprivacy        Declared UserDefaults accessed-API use
├── AppStore/                        App Store submission kit (nothing in it is compiled into the app)
│   ├── README.md                    Index of the kit
│   ├── SUBMISSION-CHECKLIST.md      Step-by-step submission guide for the owner
│   ├── ExportOptions.plist          Export options for release.sh (team id substituted at run time)
│   ├── metadata/nb-NO/, en-US/      Listing texts, one field per file (fastlane layout, no fastlane needed)
│   ├── metadata/*.md                Review notes, App Privacy, age rating and export-compliance answers, limits
│   ├── privacy-policy/              Privacy policy text (HTML and Markdown); hosted copy on GitHub Pages
│   └── screenshots/13-inch/         Simulator captures: portrait 2064x2752, landscape 2752x2064, no alpha
├── Tools/
│   ├── MakeIcon.swift               Renders the original app icon (macOS, not an Xcode target)
│   ├── RenderSounds.swift           Writes the sound cues to WAV files for listening (macOS, not an Xcode target)
│   └── release.sh                   Runs the logic tests, archives Release for iPad, exports an .ipa or uploads
├── Tests/
│   ├── LogicChecks.swift            Shared invariant checks (used by run.sh and XCTest)
│   ├── SeededGenerator.swift        Deterministic SplitMix64 random source for tests
│   ├── main.swift                   Standalone swiftc runner (not part of any Xcode target)
│   └── run.sh                       Compiles the logic + checks with swiftc and runs them
├── TallhagenTests/
│   └── TallhagenTests.swift         XCTest wrappers around the shared checks + persistence tests
└── TallhagenUITests/
    └── TallhagenUITests.swift       XCUITest flows: home, settings persistence, all four games, the map and its nodes
```

### Responsibility boundaries

**MathLogic.swift** contains the canonical numeric rules: `LearningLevel`, `NumberPiece`, the three puzzle generators, `WorkshopRules`, and since version 8 the bar rules (`BarRules`, `BarPuzzle`) and the map (`IslandMap`, `Island`, `MapNode`, `MapActivity`, `MapGuide`, `MapProgress`, `ChallengeRules`), and since version 9 the place-value rules (`PlaceValueUnit`, `PlaceValueBlocks`, `PlaceValueLevel`, `PlaceValueTask`, `PlaceValueRules`, `PlaceValuePuzzle`), and since version 10 the balance rules (`BalancePhase`, `BalanceCard`, `BalanceRules`, `BalancePuzzle`). It imports `Foundation`, **not SwiftUI**, to remain testable with `swiftc` outside Apple platforms. Every generator has an overload that takes an explicit `inout` `RandomNumberGenerator` (`make(level:…using:)` for the three number puzzles, `makeBuild(maximum:…using:)` and `makeSplit(maximum:…using:)` for the bars), so tests reproduce a run from a seed; production uses the system generator. Extend math generation or numeric validation here first and write tests before adding a UI.

**GameSessions.swift** contains the per-activity state machines (`BuildSession`, `PairSession`, `SplitSession`, `WorkshopSession`, and since version 8 `BarSession`, `ChallengeRun` and, since version 9, `PlaceValueSession`, since version 10 `BalanceSession`), the `AnswerOutcome` enum and the Norwegian feedback copy in `GameCopy`. It is also Foundation-only. A session owns the puzzle, the child's current selection or value, the solved flag and the feedback text, and exposes only mutations that keep the contracts in section 5 true. Views never compute correctness themselves.

**SoundRecipes.swift** (version 12) synthesises the five sound cues (`SoundCue`: `paper`, `tick`, `knock`, `chime`, `applause`) from damped sines and filtered noise, with a small seeded noise source (`CueNoise`), so every cue is original, the app ships no sound files and every run sounds the same. Each cue has a peak level (all at or below -22 dBFS, far below the speech), a number of slightly different variants and a minimum interval; `SoundCueGate` refuses every cue while sound is off and thins out fast series. Foundation only, checked by `Tests/run.sh`. Change a cue here and listen to it with `Tools/RenderSounds.swift` before shipping.

**Games.swift** implements interaction, layout, animation, haptics and speech on top of the sessions. It must not quietly replace mathematical rules with duplicated hard-coded 10/20/30/40 limits. All caps come from `LearningLevel.maximum` through the sessions and `WorkshopRules`. The views own the `solvedTotal` increment, which they perform exactly when a session reports `.solved`. `BuildGameView`, `PairGameView` and `SplitGameView` take an optional `level:`; a map node pins its range through it while free play keeps following the stored level, and every outcome is also reported to the `challengeHost` environment value when one is present.

**CommonViews.swift** owns reusable elements: `BeadGroup` (dot frames with ten-grouping, colour segments and empty placeholder slots), `WhitePanel`, `BigActionButton`, `SecondaryActionButton` (with an `isSpeaking` pulse for read-aloud buttons), `StepButton`, `NumberPieceCard`, `SoundToggleButton`, `NarrationGlow`, `StatusMessage`, `GameScaffold` (garden backdrop, back button, title row with the activity's guide creature, optional `creature:`, `mood:` and `progress:` parameters; inside a map node it shows `ChallengeStatusStrip` instead), `FooterClearance` (keeps a pushed screen's content clear of the grass, see section 7) and `GardenFooter` (the grass strip that carries the sound button). If a component will be reused in multiple games, move it here rather than duplicating it.

**GardenScenery.swift** owns the garden palette (an `extension GardenStyle` with the sky, hill, leaf, soil, sand, petal and outline tokens; this file is the sole owner of these names), the `GardenTuning` performance levers, `GardenBackground` (`.home`, `.chooser` and `.game(tint)` styles), `GardenFlower` and `GardenMeadow` (the footer grass and the home progress bed). Everything in it is decoration: hidden from VoiceOver, never hit-testable, still under Reduce Motion, flat paper under Increase Contrast.

**GardenCreatures.swift** owns `GardenCreature` (which guide belongs to which `GameKind`), `CreatureMood` (`idle`, `thinking`, `happy`), the optional `creatureProgress` environment value (the snail's shell dial and the hedgehog's sniff) and `CreatureView`. It uses the palette names and defines no colours of its own. Creatures never carry text, identifiers or hit testing, and no mood ever reacts to a wrong answer.

**Theme.swift** owns design tokens (`GardenStyle`), the `Font.garden`/`Font.display` helpers, `StorageKey`, `LearningLevel.stored(in:)`, the activity catalog (`GameKind`: titles, subtitles, tints, identifiers), Norwegian text-to-speech (`NorwegianVoice`), the sound-cue player (`SoundCuePlayer`, version 12: an `AVAudioEngine` with four player nodes, the ambient audio session, buffers rendered from `SoundRecipes` off the main thread at launch, prepared at once and paused after six quiet seconds and in the background, rebuilt after a media-services reset), haptics (`TouchFeedback`), VoiceOver announcements and the shared `GameFeedback.react` helper. Keep voice handling in one place; use Apple APIs already available on iPadOS.

**HomeView.swift** owns navigation and settings. Preserve the existing `@AppStorage` keys unless implementing a carefully tested migration. Users should not lose preferences or their completed-task counter after an update. Since version 8 it also declares the navigation destinations for `MapRoute` (the map) and `MapNode` (a challenge), the home's `MapCard`, and the Talløyene section of Settings.

**Challenges.swift** owns the glue between a map node and an activity: `ChallengeHost` (an `ObservableObject` carrying the node and its `ChallengeRun`; activity views call `report(_:)` with every `AnswerOutcome`), the `challengeHost` environment value, `ChallengePlayView` (creates the activity view at the node's fixed range, stores the stars under `islandStars` the moment the run completes and shows `ChallengeCompletionCard` after a short delay that is cancelled if the child leaves) and `ChallengeStatusStrip`, which `GameScaffold` draws instead of its title row whenever the environment carries a host. Rules and state stay in MathLogic.swift and GameSessions.swift.

**IslandMap.swift** owns `IslandMapView` (the horizontally scrolling pond with one `IslandView` per `Island`), `MapNodeButton` (padlock, number, activity glyph, stars, the breathing halo on the next node), `ActivityGlyph`/`BarGlyph`, `StarRow`, and the home screen's `MapCard`/`MapIcon`. It reads `IslandMap.standard` and `MapProgress` and never decides unlocks itself.

**NumberBars.swift** owns the bar drawing (`BarMetrics`, `BarPalette`, `BarFace`, `NumberBarView`, `BarComposition`, `BarGhostComposition`) and `BarGameView`, the activity behind the `barBuild` and `barSplit` nodes: shelf layout, the tap, drag and swipe gestures and hit areas, the combine, split and rejection animations (none under Reduce Motion) and speech. Values, combine and split rules come from `BarRules`/`BarPuzzle`, state from `BarSession`.

**PlaceValue.swift** owns `PlaceBlockStyle`/`PlaceBlockView` (unit, rod, tile and cube drawings at one scale), the tray bins, the workspace columns with the carry and borrow transitions, the reading choices and `PlaceValueView`, the activity behind the `placeValue` nodes. Blocks, regrouping, borrowing and the puzzles come from `PlaceValueBlocks`, `PlaceValueRules` and `PlaceValuePuzzle` in MathLogic.swift; the state from `PlaceValueSession` in GameSessions.swift.

**Balance.swift** owns `BudView` (closed and open), `BalanceCardView` (positive, inverse and ghost styling per phase), the board with its two wrapping trays and the post, the division rail, the hand of cards, the vanishing pair (`CancelBurstView`) and `BalanceView`, the activity behind the `balance` nodes. Moves, the shortest solution, the board's maximum and the star rule come from `BalanceRules` and `BalancePuzzle` in MathLogic.swift; the cards and their identities from `BalanceSession` in GameSessions.swift.

**Tallhagen.xcodeproj** is a standard, hand-maintainable project with 24-character hexadecimal object identifiers. When adding Swift files or app resources, add file references and build-phase entries to the right target. Do not presume that files dropped into the directory will be automatically compiled. The unit-test target compiles `Tests/LogicChecks.swift` and `Tests/SeededGenerator.swift` with the compilation condition `TALLHAGEN_XCTEST`, which switches on the `@testable import Tallhagen` those files need in Xcode but not under plain `swiftc`.

## 4. Educational approach

The core teaching loop should be: **see a quantity → manipulate it → observe what changes → receive accurate, concise feedback → optionally try again**.

### Pedagogy rules

- Treat a numeral as a countable quantity. Show both the number and its visual representation wherever feasible.
- Use concrete mathematical language in Norwegian: *tall*, *prikker*, *pluss*, *til sammen*, *mangler*, *venstre*, *høyre*.
- Present exercises without time pressure, losing lives, random penalties, streak anxiety, ads, or paywalls.
- Errors should prompt another attempt; avoid shame, defeat, or alarming cues.
- Avoid dependence on reading fluency; instructions should be short and audible when appropriate.
- Start with positive whole-number quantities. Do not introduce zero as a selectable component, negative numbers, fractions, or decimal arithmetic without a separate curriculum decision.
- Keep the child's action and the response close together. Avoid screens that require several abstract steps before something visibly changes.
- Preserve mathematical flexibility: when a child can correctly compose a total in more than one way, accept **any** valid composition rather than only the initially generated pair.
- Provide optional hints; hints must not falsely imply that an alternative correct approach is wrong. `BuildSession.hint` therefore completes the child's current selection when any remaining pieces fit, and only suggests removing a piece when nothing fits.
- Do not promise alignment with a specific Norwegian school-year curriculum without a documented review.
- **Place value (curriculum note, version 9):** the blocks follow the base-ten material common in Norwegian early mathematics (enere, tiere, hundrere, tusenere): a number is read from its places from the largest down, ten of a place are exchanged for one of the next (`veksle`), and subtraction with a broken ten is shown with real blocks before any written algorithm. The ranges 11–19, 20–99, 100–999 and 1000–9999 are offered in that order on one island; nothing promises alignment with a particular school year.

### Visual quantities through 40

`BeadGroup` renders dots in rows of five and inserts a slightly larger gap after every second row, so every block of two rows is a group of ten: 40 appears as four clearly separated ten-frames. The whole quantity is always drawn; amounts above 20 are never replaced with an ellipsis or hidden. Counted objects (filled dots) are visually distinct from the decorative circles on the home screen and the icon.

`BeadGroup` also supports colour segments (for example 18 teal dots followed by 22 orange dots in the workshop and in a solved pair puzzle) and dashed, empty placeholder slots that show how many are missing in *Finn tallvennen*. The accessibility label states the filled count and, for placeholders, the total the frame reaches, without reading out the missing count directly. Never let the visual quantity and the accessibility label disagree.

**Decoration never looks like a counted quantity.** The garden draws nothing inside a `WhitePanel`, a piece card, a choice card or a group panel, and nothing decorative comes within about 24 pt of a dot frame. Petals, leaves, clouds and burst pieces are ellipses, capsules and arcs; flower centres are flat yellow discs of at most 5.5 pt; the only filled circles outside `BeadGroup` are the sun (112 pt or larger) and creature eyes, so no decorative circle in a game colour exists in the 7–24 pt dot range. The progress bed plants one flower per solved task in groups of five with a larger gap after every ten, lives only in the home progress card and is capped at 40 and at what fits; `home.solvedTotal` stays the only statement of progress.

## 5. Mathematical contracts and invariants

These are business rules, not implementation suggestions. New features must maintain them or explicitly update the specification and tests. `Tests/LogicChecks.swift` encodes each of them.

### LearningLevel

- `LearningLevel` uses persistent raw integer identifiers **1, 2, 3, 4, 5**.
- Titles and maxima map respectively to **10, 20, 30, 40, 100**; `starterChoices` is `[.practice, .advanced, .hundred]`.
- `dotColumns` is 5 for maxima up to 40 and 10 for 100, so every frame at a level uses the same row length and 100 is ten rows of ten.
- The saved key is `learningLevel`. Existing values 1–3 must retain their original meanings.
- `LearningLevel.resolve(_:)` turns any stored integer into a level; unrecognized values fall back to `practice` (maximum 20). `LearningLevel.stored(in:)` applies this to UserDefaults.
- A new number range should be a new level, not a silent change to an existing stored level's maximum.

### NumberPiece

- Represents one positive integer with a distinct `UUID` identity.
- Identity is important when two different pieces have the same numeric value: selecting one must not remove the other by accident.
- Pieces displayed for any generated puzzle have values strictly below that puzzle's target.

### BuildPuzzle and BuildSession

- `BuildPuzzle.targetRange(for:)` is 5…10 at level 1 and 8…maximum for levels 2–5.
- A guaranteed pair of positive pieces sums exactly to the target.
- Three additional positive pieces are generated as distractors, making **five** pieces in total, with distinct IDs even when values repeat.
- `BuildPuzzle.completion(for:from:)` finds the fewest pieces among given candidates whose values add up to an amount, or nil. Every generated puzzle is solvable from its own pieces.
- `BuildSession.choose` accepts **any** combination summing exactly to the target. A piece that would exceed the target is rejected (`.rejected`) with the feedback `Det blir for mange. Prøv en mindre brikke!` and does not mutate the selection; when no remaining piece could fit anyway, the sentence continues with `Ingen brikke passer nå. Ta bort en brikke og prøv igjen.` so the advice is always followable.
- After each valid step the feedback is `Du har N. Du trenger M til.`; when no remaining pieces can complete the total it adds `Ingen brikke passer nå. Ta bort en brikke og prøv igjen.`
- `remove` takes back exactly the tapped piece before completion; `clearSelection` empties the selection; both are ignored after completion, when the session is locked until the next puzzle.
- Completion returns `.solved` exactly once, with feedback that lists the child's actual pieces, for example `15 pluss 15 pluss 10 er 40. Bra jobbet!`. The view increments `solvedTotal` on that outcome only.
- `hint` is `Prøv A og B.` before any selection, `Du trenger N til. Prøv brikken N.` or `Prøv brikkene X og Y.` when the current selection can still be completed, and otherwise suggests removing a piece or starting over with the generated pair.
- Every session exposes a spoken `prompt` (`Kan du lage 40?`, `18 pluss hvilket tall er 40?`, `Du har 40 prikker. Lag 17 prikker til venstre.`), read aloud when a puzzle starts if speech is on, and on demand through the **Les opp oppgaven** button.
- The optional `target:` parameter in `BuildPuzzle.make` exists for deterministic testing; production normally leaves it unspecified.

### PairPuzzle and PairSession

- Target is within 5…selected maximum.
- Both given and missing number are positive and add up to the target.
- The puzzle presents **four distinct positive integer choices**, all below the target, generated in an ordered array (not a `Set`) so a seeded run is reproducible.
- Exactly one choice equals the missing number.
- `PairSession.answer` returns `.incorrect` for a wrong choice, remembers it in `triedChoices`, keeps the puzzle active and sets feedback of the form `Prøv igjen. 18 pluss 7 er 25. Det er for lite. Tell hvor mange som mangler til 40.` (or `for mye`). The real sum is always stated; feedback never asserts a false equation.
- A correct choice returns `.solved` once with `Riktig! 18 pluss 22 er 40.`; later answers are ignored.
- The optional `target:` argument allows a test to force a total of 40.

### SplitPuzzle and SplitSession

- Total is within 5…selected maximum.
- `wantedLeft` is between 1 and total − 1; `wantedRight = total − wantedLeft` is also positive.
- `leftRange` is 1…total − 1. `startingLeft` is near the middle but never equal to `wantedLeft`, so the child always has to move something before checking.
- `SplitSession.setLeft` clamps to `leftRange`; `increase`/`decrease` stop at the range ends; `canIncrease`/`canDecrease` drive the button states. Left and right always add back to the immutable total and neither group is ever empty.
- `check` succeeds only when the current left count equals `wantedLeft`, returning `.solved` once with `Kjempebra! 40 er 17 og 23 sammen.` and locking every control. Otherwise it returns `.incorrect` with direction guidance: `Du har 12 til venstre. Du trenger flere prikker til venstre.` (or `færre`).
- The optional `total:` argument supports a deterministic total of 40 in tests.

### WorkshopRules and WorkshopSession (Tallverkstedet)

- First and second amounts are each >= 1 and start at 3 and 4.
- `first + second <= selectedLevel.maximum` at all times.
- A +1 control is enabled only if adding one would not exceed the maximum.
- A −1 control is enabled only when its operand exceeds 1.
- **39 + 1 = 40** and **20 + 20 = 40** are valid at level 4; **39 + 2 = 41** must be disallowed.
- `updateMaximum` applies a changed level by shrinking the larger amount until the total fits, so the session never shows an invalid state.
- The workshop does not increment `solvedTotal`, because it has no required correct answer.
- The workshop includes an explicit user-triggered speak-the-equation button that reads `GameCopy.workshopSpoken` (`39 pluss 1 er 40.`); this is independent of whether optional automatic speech feedback is enabled.

### BarRules, BarPuzzle and BarSession (Tallstolpene)

- `BarRules.maximumBarValue` is **10**: `isValidBar` accepts 1…10, `canCombine(a, b)` requires both valid and `a + b <= 10`, `canSplit(value, bottom:)` requires `1 <= bottom < value`. `rods(in:)`/`units(in:)` split a built total into tens rods and units (14 → 1 and 4). `numeralOpacity(forMaximum:)` is 0 for ranges up to 5, 0.55 up to 10, 0.8 up to 19 and 1 from 20, and never decreases with the range.
- `BarPuzzle.buildTargetRange(maximum:)` is 2…maximum up to ten and the last ten values above it (11…20 for a node to 20, so every task there needs a tens rod); `splitTotalRange(maximum:)` is 2…min(maximum, 10).
- A build puzzle offers a partition of the target (two parts up to 6, three from 7) plus two extra bars; every bar is 1…10 and strictly below the target, parts are offered as a multiset, and the target is solvable by placing whole bars (`BuildPuzzle.completion` is reused as the oracle). A split puzzle offers one bar of `target` and two positive `parts` that add up to it.
- `BarSession.combine(moving, onto:)` merges two shelf bars into one that takes the drop target's place; refused (`.rejected`, `To stolper kan ikke bli høyere enn 10 sammen.`) above ten and, in build mode, above the remaining amount (`Det blir for høyt. Prøv en lavere stolpe!`). `split(_, bottom:)` replaces a bar by its two parts in place (`.rejected` for impossible cuts, `.ignored` for unknown bars). `place` moves a shelf bar into the zone (build only): `.progress` with `Du har N. Du trenger M til.`, `.rejected` without side effects above the remaining amount, `.solved` exactly once with `A pluss B er T. Bra bygget!`. `takeBackLast` returns the last placed bar to the end of the shelf. Every mutation is ignored after completion.
- Split mode is solved when the shelf holds exactly the wanted parts in any order (`8 er 5 og 3. Kjempebra!`); a wrong two-part cut is `.incorrect` (`Du har 2 og 6. Oppgaven er 3 og 5. Dra stolpene sammen og del på nytt.`); three or more bars are `.progress`, and joining them again is allowed.
- `hint` (the sentence for `buildHintStep`) names the planned parts while nothing has moved; otherwise the fewest shelf bars that complete the zone (`BarRules.fewestBars`, larger bars first, two or more ones counted rather than listed: `Prøv stolpen 6 og 4 enere.`, and with several other bars in a clause of their own, `Prøv stolpene 6 og 3, og så 2 enere.`); otherwise the one cut after which the fewest bars complete the zone (`BarRules.cutToComplete`; ties go to the smaller bar and then to the larger lower part: `Del stolpen 3 i 2 og 1.`, and on a shelf of 9, 4, 2 and 2 with 12 missing `Del stolpen 4 i 3 og 1.` rather than a cut of a 2). Every hint can be followed with the bars on the shelf at that moment, however many cuts and combines came before, and the searches work on value counts, so a shelf of two dozen ones is as quick as five bars. The shelf always holds more than the missing amount, so a build task is always solvable. After completion it restates the result.

### IslandMap, MapProgress, ChallengeRules and ChallengeRun (Talløyene)

- `IslandMap.standard` has **6 islands and 23 nodes** since version 10 (4 and 14 in version 8, 5 and 20 in version 9), numbered 1…23 in order with unique, stable identifiers (`bars-build-5`, `bars-split-6`, `bars-build-10`, `bars-split-10`, `build-20`, `pair-20`, `split-20`, `bars-build-20`, `build-40`, `pair-40`, `split-40`, `build-100`, `pair-100`, `split-100`, `place-show-19`, `place-show-99`, `place-read-99`, `place-away-99`, `place-show-999`, `place-read-9999`, `balance-pictures`, `balance-hybrid`, `balance-symbols`). Identifiers are storage keys: never rename one. Islands: Stolpeøya (snail), Tjueøya (butterfly), Førtiøya (bee), Hundreøya (hedgehog), Tusenøya (hedgehog), Likevektsøya (butterfly). Every node has `taskCount` 4 (`ChallengeRules.defaultTaskCount`).
- `MapProgress` is parsed from and serialized to one string (`nodeID=stars` pairs, comma separated, sorted by identifier; values clamped to 1…3, damaged entries dropped). A node is **unlocked** when it is the first node or its predecessor has at least one star; **completed** when it has at least one star. `record(stars:for:)` keeps the best result and reports whether it improved. `nextNode(in:)` is the first unlocked, incomplete node. `maximumStars(in:)` is 3 per node (42 in version 8).
- `ChallengeRules.stars(mistakes:)` is 3 for 0–1 mistakes, 2 for 2–3 and 1 otherwise: completion always earns a star. `ChallengeRun(taskCount:)` counts `.solved` and mistakes (`.incorrect`, `.rejected`; `.progress`/`.ignored` are free, hints are free), is complete after `taskCount` solved tasks, reports 0 stars until then, and ignores every outcome after completion.

### PlaceValueBlocks, PlaceValuePuzzle and PlaceValueSession (Plassverdi)

- `PlaceValueUnit` is ones, tens, hundreds, thousands (raw values 0–3, `value` 1, 10, 100, 1000; Norwegian `enere`, `tiere`, `hundrere`, `tusenere`). `PlaceValueLevel` has raw values 1–4 with the ranges **11–19, 20–99, 100–999, 1000–9999** and offers ones and tens, plus hundreds from level 3 and thousands at level 4. These identifiers are stable like the learning levels.
- `PlaceValueBlocks` counts blocks per place; `number` is the weighted sum, `isCanonical` means every place holds fewer than ten. `regroup()` carries ten of a place into one of the next from ones upward, as often as needed (thousands never regroup), and returns the carries per place; `borrow(from:)` breaks one block into ten of the place below and keeps the number. Negative counts and numbers are clamped to zero.
- `PlaceValuePuzzle.make(task:level:)`: *show* picks targets whose digit sum is at most 12 (`PlaceValueRules.maximumDigitSum`), so the longest task stays a handful of drags; *read* offers four distinct choices inside the level whose distractors each differ in one place, the highest places first (a thousand, a hundred and a ten at the thousands level; a hundred, a ten and the digit-swapped twin at the hundreds level; the twin and a ten below), so the biggest blocks must be counted too; *take away* starts at least at 11 with a ones digit below 9 and a tens digit of at least 1 (`PlaceValuePuzzle.isTakeAwayTarget`) and asks for a single-digit amount above the ones digit, so exactly one ten must be broken and the result stays positive.
- `PlaceValueSession.add` (show) refuses a block that would pass the target (`Det blir for mye. Prøv en mindre brikke!`), otherwise regroups at once, reports the carries for the animation and names every one of them (`Ti enere ble én tier. Ti tiere ble én hundrer.`); the target returns `.solved` once with `4 tiere og 7 enere er 47. Flott!`. `removeOne` takes a block back (show) or away (take away, refused below the answer: `Da blir det for lite. Legg tilbake en brikke.`); `borrow` breaks a block and keeps the number (`Én tier ble ti enere.`), and in a take-away task it is refused once the ones can cover what is left to take away (`Du har nok enere. Ta bort enere først.`), so at most one ten is ever broken; `restoreLast` undoes the last removal; `answer` (read) is `.incorrect` for a wrong choice (`Prøv igjen. Tell de største brikkene først, så de små.`; the guide does not react) and `.solved` once for the number. Hints name the biggest missing place (`Legg til 4 tiere til.`), the blocks to count (`Tell de største brikkene først: 4 tiere og 7 enere.`), or the next removal or borrow. Everything is ignored after completion.

### BalanceRules, BalancePuzzle and BalanceSession (Likevekt)

- `BalancePhase` has raw values 1–3 (pictorial, hybrid, symbolic). `BalanceRules.cardValues` is `[1, 2, 5, 10]`; `cards(for:)` makes new positive cards for an amount, biggest first; `maximumAmount(for:)` is 15, 25 and 30 per phase; `stars(moves:optimal:)` is 3 within the shortest solution, 2 within two extra moves, 1 otherwise.
- `BalanceRules.apply(_:…)` decides every move: a card is allowed while the left amount stays at zero or more and both sides at most the maximum; a division needs the divisor to divide the number of buds and both amounts. **Curriculum decision:** the board never shows a negative amount. An inverse card takes away part of what lies beside the bud, never more (the right side always holds at least as much), so the activity stays inside the whole numbers the earlier islands use.
- `BalanceRules.shortestSolution(…)` is a breadth-first search over the boards the allowed moves reach (the state is the number of buds and both amounts, a few dozen boards at most); the goal is one bud alone on the left. It tries a division first, then inverse cards from the biggest, then positive cards from the smallest, so among shortest solutions it prefers dividing and big inverse cards. It finds shortcuts a fixed recipe misses: `? + 9 = 13` takes two moves (plus 1, then minus 10), `2 · ? + 4 = 10` is halved first. `BalancePuzzle.optimalMoves` is its length.
- `BalancePuzzle`: `coefficient` buds plus `leftConstant` on the left balance `rightConstant = coefficient × unknown + leftConstant`. Pictures: one bud, unknown and left amount 1–5, right side at most 10. Hybrid: 1–9 each, right side at most 18. Symbols: one to three buds, unknown 1–6, left amount 0–6 (never 0 with a single bud), right side at most 24.
- `BalanceSession` stores the cards of each side with stable identities. `add(value:inverse:)` puts a card on the left and a mirror (a card of its own) on the right (`Du la pluss 1 på begge sider.`); an inverse card takes its amount from each side so that the sentence tells exactly what the child sees: one card of exactly that amount if there is one; otherwise whole cards that add up to it; otherwise the smallest bigger card is changed, the amount goes and the rest stays (`5 ble 2, 2 og 1. 2 og minus 2 ble null.`, `10 ble 5 og 5. 5 og minus 5 ble null.`); only when every card is smaller do whole cards go and the last one needed is changed (`2 ble 1 og 1. 5 og minus 5 ble null.`). The sentence names the change beside the buds; the right side changes the same way without being told. A side with more than five cards gathers them into the fewest cards for its amount (`Kortene ble samlet til færre kort.`). Only positive cards rest on the board. `lastEffect` reports the placed cards, their mirrors and the cards taken, for the animations. A refused card (`Ved siden av knoppen er det bare 3. Prøv et mindre minuskort.` (`knoppene` with several buds), `Så mye får ikke plass på vekten. Prøv et mindre kort.`) is not a move. The rail offers exactly the number of buds; `divide(by:)` splits both sides when the left amount divides (`Begge sidene ble delt i 2 like deler.`), otherwise it is refused without a move (`3 kan ikke deles i 2 like deler. Legg kort på begge sider først.`). The board is solved when one bud stands alone: `Knoppen åpnet seg: tallet er 4! Du brukte 2 trekk.` The hint (`nextMove`) is the first step of a shortest solution from the board as it is, so following hints from any board finishes it in the fewest moves left. The prompt asks what the bud hides and says what to do (`Hva gjemmer seg i knoppen? Legg samme kort på begge sider til knoppen står alene.`; with several buds `Hver knopp gjemmer det samme tallet.` and the division). `challengeReports(for:)` turns an outcome into what the node's rating hears: nothing for a refusal, one mistake per missing star and then the solve for a solved board.

### Forced test targets and seeds

Generators accept an optional explicit total for deterministic tests; each validates with a precondition that the specified total belongs to that level's valid range. Do not allow tests or production code to bypass the selected maximum with arbitrary totals. Randomized tests use `SeededGenerator` with fixed seeds; `LogicChecks.checkDeterminism` asserts that the same seed reproduces the same puzzles.

## 6. Application state and persistence

### Persistent state

| Key | SwiftUI storage | Purpose | Existing default |
| --- | --- | --- | --- |
| `learningLevel` | `@AppStorage` integer | Selected number range | 2 |
| `speakNorwegian` | `@AppStorage` boolean | Spoken menus, prompts and feedback | true |
| `solvedTotal` | `@AppStorage` integer | Cumulative count of completed puzzles | 0 |
| `islandStars` | `@AppStorage` string | Stars per map node, `nodeID=stars,…` (`MapProgress.serialized`); unlocks are derived from it (version 8) | "" (nothing stored: only node 1 open) |

These values are stored using Apple's `UserDefaults`; the key strings live in `StorageKey`. `PrivacyInfo.xcprivacy` declares the relevant accessed-API category. There is no user identification, user account, profile database, analytics service, network endpoint, or progress upload. Settings offers an explicit, confirmed **Nullstill antall løste oppgaver** action that sets `solvedTotal` back to 0; changing the level never touches it. The level chooser opens automatically only while `learningLevel` has never been stored (no extra key is needed); afterwards it is reachable from the home screen's **Velg tall** button.

Version 8 adds one key, `islandStars`. It holds the best star count per completed map node as `bars-build-5=3,bars-split-6=1,…`; which nodes are unlocked follows from it (a node opens when its predecessor has a star), so no second key exists and the two can never disagree. `ChallengePlayView` writes it the moment a run completes; Settings offers **Nullstill stjerner og låser på Talløyene** (confirmed), which empties the string and locks everything but the first node again without touching `solvedTotal`. The three older keys are unchanged, and solving a puzzle inside a map node still increments `solvedTotal` exactly once per `.solved`. Place value adds no key: its progress is the same `islandStars` entries (`place-show-19`, `place-show-99`, `place-read-99`, `place-away-99`, `place-show-999`, `place-read-9999`). The balance adds no key either: `balance-pictures`, `balance-hybrid` and `balance-symbols` are ordinary `islandStars` entries. Inside a node, each missing star of a solved board counts as one mistake for the node (`BalanceSession.challengeReports`), like a wrong answer in the other activities, so four boards with one missing star each give the node one star; a refused card or division costs nothing.

### Ephemeral view state

Each game view holds one `@State` session created from `LearningLevel.stored()` (or the map node's fixed level) when the screen is created, plus small presentation state (drop-target highlight; for the bars the drag in progress, the selected cut markers and the one-shot animation flags). A challenge keeps its `ChallengeRun` in a `ChallengeHost` object owned by `ChallengePlayView` for the life of that screen. The workshop additionally observes `learningLevel` and applies a changed maximum through `updateMaximum`. Starting the next puzzle replaces the session.

If you implement profiles later, first define a migration plan that avoids mixing progress belonging to different children, specify how profiles are selected by a child, and add privacy review. Never add cloud sync or external telemetry as a side effect of improving persistence.

## 7. Interface and interaction standards

- **Platform:** iPad-only target (`TARGETED_DEVICE_FAMILY = 2`), minimum iPadOS 17, all four iPad orientations declared in the generated Info.plist.
- **Orientation and width:** Design to remain readable across iPad portrait and landscape. Use scrollable game content rather than clipping large quantity grids. The app takes part in Split View, Slide Over and Stage Manager, so widths down to 320 pt occur: the two-column rows (Del opp groups, workshop groups, the Bygg tallet action row) are wrapped in `ViewThatFits` and stack vertically when they do not fit, the selected-piece row scrolls horizontally instead of clipping, and the decorative example on the home screen is dropped in the compact width class. Full-screen iPads always get the two-column layouts. In the compact width class and at the accessibility text sizes (`xxLarge` and above) the title-row creature of a game, the chooser's butterfly and the chooser card posts are dropped, the backdrop shows a corner sun with three plants and one cloud, and the footer shows one flower per side, so titles never scale below 0.75 and the text columns keep their width.
- **Tap targets:** Important child controls are at least 48 pt tall (back and settings capsules 48, secondary actions 50, step buttons 58, primary actions 60) and pieces/choice cards are far larger. Every number bar has at least 48 pt of touch height (the 1-bar's extra area sits above it). The cut markers are the one exception: they sit on the 22 pt unit pitch, so each marker answers in its own one-unit band (`BarMetrics.cutMarkerHit`, 36 × 22 pt) and neighbouring markers never share a touch (the two end markers' bands also reach the outer edge of their discs); the sideways sweep is the larger way to cut.
- **Text:** Child-facing sentences use `Font.garden(_:weight:)`, which follows Dynamic Type up to `xxxLarge` (capped in `TallhagenApp`, because the equation rows and dot frames are not designed for the accessibility sizes). Large numerals use fixed `Font.display` sizes with `minimumScaleFactor` where space is tight. Do not hide the arithmetic equation behind animation.
- **Colour and contrast:** `GardenStyle` tints are chosen so teal, purple, blue and the muted gray reach at least 4.5:1 on white and on the paper background; orange (4.1:1) is reserved for large numerals, icons and fills. Feedback banners draw their sentence in ink and carry the colour in the symbol, so success and guidance are distinguished by symbol (check mark vs. bulb) and the text stays above 4.5:1 on the tinted banner. A tried answer in Finn tallvennen is dimmed only to 65 % and captioned `Prøvd`. The app always uses this light paper palette: `TallhagenApp` forces the light appearance, so Dark Mode is intentionally not followed.
- **Text on the garden (contrast guard):** child-facing text never sits bare on a hill, a plant, sand or the sun. On the home and the chooser every sentence is on white (cards, capsules, the progress card), on the soil signboard (white on soil 5.56:1) or on a cloud veil (`GardenStyle.cloudVeil`, white at 0.88, opaque under Reduce Transparency: the hero column, the `Velg en lek` heading and the chooser title block; muted text on the veil measures 5.44:1 or better over any scenery colour). Game screens keep paper with a 260 pt sky band whose colours keep muted text above 5.3:1. Ink reads on every scenery colour (6.03:1 on the nearest hill at the lowest); muted, teal, purple and blue text are allowed only on white, paper, the veil and the pale sky stops. Re-measure before changing any garden colour.
- **Spacing:** Generous gaps around independent controls reduce mis-taps. Do not place destructive or global navigation controls next to changing a number.
- **Stable layout:** Dot frames whose amount changes while the child taps (Del opp groups, the workshop groups and total, the Bygg tallet answer area) reserve the height of the largest amount possible at the current level through `BeadGroup.height(forCount:)`, so plus/minus buttons and the slider never move under a finger.
- **Drag and tap:** In Bygg tallet, selection by **tap** remains a first-class alternative to drag-and-drop. Drag support alone is insufficient for young children or assistive-technology users. Pieces are draggable only while the puzzle is active (`.disabled` alone does not stop drags), the answer panel highlights only while active, and a drop is accepted only when its text is the identifier of one of the puzzle's own pieces.
- **Accessibility:** Every quantity, piece, button and slider has a Norwegian label; feedback and the result of every plus/minus step are posted as high-priority VoiceOver announcements (`VoiceOverAnnouncer`), so VoiceOver's own focus speech does not cut them off; the Finn tallvennen equation is one element (`18 pluss hvilket tall er 40`); disabled step buttons expose the disabled state. Reconfirm the VoiceOver sequence after layout changes.
- **Identifiers:** Views carry stable accessibility identifiers (`home.settings`, `home.level`, `home.solvedTotal`, `home.game.build` and the other three games, `game.back`, `game.title`, `game.next`, `game.feedback`, `game.readPrompt`, `build.target`, `build.currentTotal`, `build.piece.<n>`, `build.selected.<n>`, `build.hint`, `build.restart`, `pair.equation`, `pair.choice.<n>`, `split.total`, `split.wanted`, `split.left`, `split.right`, `split.equation`, `split.slider`, `split.increase`, `split.decrease`, `split.check`, `workshop.first.value/increase/decrease` and the `workshop.second` set, `workshop.equation`, `workshop.speak`, `workshop.instruction`, `settings.level`, `settings.levelDetail`, `settings.speech`, `settings.solvedTotal`, `settings.reset`, `settings.done`, `settings.privacy` when `PrivacyPolicy.address` is set, and since version 8 `home.map`, `map.back`, `map.title`, `map.stars`, `map.readIntro`, `map.node.<nodeID>`, `challenge.back`, `challenge.node`, `challenge.progress`, `challenge.complete`, `challenge.stars`, `challenge.toMap`, `challenge.again`, `bar.target`, `bar.piece.<value>`, `bar.cut.<bottom>`, `bar.zone`, `bar.currentTotal`, `bar.hint`, `bar.takeBack`, `settings.mapStars`, `settings.resetMap`, since version 9 `place.target`, `place.tray.<unit>`, `place.column.<unit>`, `place.number`, `place.removed`, `place.choice.<n>`, `place.hint`, `place.restore`, and since version 10 `balance.goal`, `balance.symbols`, `balance.moves`, `balance.left`, `balance.right`, `balance.card.plus.<n>`, `balance.card.minus.<n>`, `balance.divide.<n>`, `balance.hint`, `balance.stars`). The authoritative set is whatever `TallhagenUITests.swift` reads. Piece and chip identifiers are value-based, so two pieces of the same value share one identifier: tests look them up with `firstMatch` or a `BEGINSWITH` predicate.
- **Haptics:** Optional tactile feedback accompanies steps, success and rejected actions but is never needed to comprehend correctness.
- **Sound cues (version 12):** quiet, synthesised cues accompany the same moments, because iPads have no haptic engine: a paper slide for a choice (a game card, the map card, Velg tall, an open stone, Neste oppgave, Til kartet, Spill igjen, a back arrow, a level in the chooser), a tick for a change (a piece, a bar, a bar chosen for cutting in Del stolpen, a block, a card, the Del opp slider and buttons, the workshop steppers, turning sound on), a soft knock for a refused move, a wrong answer or a locked stone, a chime for a solved task and a faint applause when the completion card of a map task appears. Checks bring their own outcome cue, so they have no paper slide. Turning sound off also cuts a cue that is still sounding; each cue takes a free voice of four, so a tick never cuts a chime short, and the tick variants come in random order. The cues follow the sound setting (`speakNorwegian`, the sound button and «Les opp på norsk»), never peak above about -22 dBFS and are never needed to understand anything: speech and the screen carry the meaning.
- **Animation:** Brief springs and fades. State-change animations and the button press animation are routed through `Motion`, which returns no animation when Reduce Motion is on; `BouncyButtonStyle` also drops its scale effect then, keeping only an instant 10 % opacity change while pressed.
- **Garden motion inventory:** one `TimelineView` clock per screen (20 fps, paused while the scene is inactive or the screen is covered) drives the sky's drifting mesh centre (iOS 18 only), the sun halo breath, the two clouds and the swaying flower field; each creature has its own clock for tiny idle motion (caps: 4 pt, 6°, periods of 1.6 s or longer). One-shot reactions run once per transition into `.happy` (snail and hedgehog hop through `PhaseAnimator`, butterfly and bee fly through `KeyframeAnimator`), with a short petal burst inside the creature's own frame (never for the hedgehog) and a 26 pt flower that sprouts at the guide's feet while a puzzle is solved. SF Symbol effects: the progress star bounces when `solvedTotal` rises, the feedback check mark bounces per success sentence, the bulb wiggles (iOS 18) or bounces (iOS 17) per hint, the read-aloud speakers pulse while narrating, the sound toggle swaps its symbol with the replace transition, and home cards settle in through `scrollTransition`. Nothing changes faster than 3 Hz and there is no full-screen flash. Under Reduce Motion no clock, `PhaseAnimator`, `KeyframeAnimator`, burst, symbol effect or scroll scale is created at all (if/else branches, not merely paused); the garden is a still image and pose changes apply instantly. The single exception is a 0.4 s opacity-only crossfade of creature eyes, highlights and halos, documented on `Motion` in `Theme.swift`.
- **Guide creatures:** each activity has one guide (`GardenCreature.forGame`). It sits under the icon on the home card (64 pt) and perks up (`.thinking`) while the narrator names its game; beside the game title (88 pt) it is attentive once the child has started (a placed piece, a moved group) and happy while the puzzle is solved. The snail's shell spiral turns with `creatureProgress` (current total over target), the hedgehog sniffs on every change of the workshop total and gives only a tiny, reward-free nod at the maximum. No creature ever reacts to a wrong answer, none carries text or an accessibility identifier, and all are hidden from VoiceOver and touch.
- **Notifications:** No permission prompts or push notifications in this version.
- **Settings:** Changing a level must not erase completed-task totals. Settings names the selected level and its maximum explicitly; its picker is bound to the resolved `LearningLevel`, so an unknown stored value still shows the level the app actually uses and choosing a segment normalises it.
- **Sound button:** it turns the automatic speech and, since version 12, the sound cues off and on. `SoundToggleButton` is pinned to the bottom of every screen inside `GardenFooter`, an opaque 92 pt grass strip set as a `safeAreaInset` on the navigation stack (and again inside the chooser) that also fills the home-indicator area with grass; screens pushed inside the stack do not inherit that inset (found in version 8 when a landscape page ended under the grass), so `GameScaffold` and the map apply `FooterClearance`, which reads the bottom safe-area inset the screen received and adds the footer's height only when it is missing; the footer's side flowers never sit under the button, and `sound.toggle` is its only accessible element. White capsule with a speaker means on; grey capsule with a slashed speaker means off. Turning it off stops speech immediately. It toggles the same `speakNorwegian` value as Settings.
- **Garden scenery:** `GardenBackground` replaces the plain paper behind every screen. Home and chooser: a pale morning sky (`MeshGradient` on iOS 18, a `LinearGradient` with a radial glow on iOS 17), a big faceless sun (behind the hero example card on the home, low at the left on the chooser), two clouds, three hill layers and a pinned field of daisies, tulips and grass tufts; the home header is a wooden signboard and the chooser cards stand on small posts. Game screens stay paper with a sky band and a corner sun so every panel sits on paper or white. Increase Contrast turns the sky into flat paper; Reduce Transparency makes clouds and veils opaque. `GardenTuning` holds the levers (frame interval, plant counts, bloom cap, footer height) if an old iPad drops frames.
- **Narrated menus:** When the home screen or the level chooser appears and speech is on, `NorwegianVoice.narrate` reads a short intro and then each choice; `narratedItem` names the choice being spoken and the matching card glows (`narrationGlow`: thick tinted border, halo, slight scale unless Reduce Motion). Both menus have a **Les opp valgene** button to hear it again. Narration is skipped while VoiceOver runs, which reads menus itself.
- **Talløyene (landscape-first map):** `IslandMapView` is a horizontally scrolling row of islands in a pond under a thin strip (back, title, star total, read-aloud; two rows when a narrow window has no room for one, so the back button never leaves the screen), so landscape shows two to three islands at once and portrait scrolls the same row; the safe central area is the island row itself, inset 26 pt from the edges, and nothing is letterboxed. It scrolls to the island of the next open node on appear. Nodes are `NavigationLink`s with `map.node.<id>`: a padlock and a disabled button while locked (`Oppgave 3. Bygg med stolper til 10. Låst. Løs oppgave 2 først.`), the number with the activity glyph once open, and the earned stars underneath once complete; the next node breathes a soft halo (still under Reduce Motion). Narration says `Velkommen til Talløyene. Trykk på et tall for å begynne.` and names the next node while it glows.
- **Challenge status strip:** inside a node `GameScaffold` replaces its back row and title row by `ChallengeStatusStrip`: an arrow button back to the map (`challenge.back`), the node number on the activity colour (`challenge.node`), one leaf per task that fills as tasks are solved (`challenge.progress`, label `2 av 4 oppgaver løst`), the activity name and the island's guide at regular widths. The sound button stays in the footer. After the last task the stars are stored at once, the whole node screen, the back arrow included, stops taking touches (no fifth task can start), and `ChallengeCompletionCard` appears after about a second (0.2 s under Reduce Motion) over a dimmed, non-interactive screen; should the screen go away first, the pending card is cancelled: the happy guide, three stars popping in one by one (all at once under Reduce Motion), `Du fikk 3 stjerner.` (`challenge.stars`), **Tilbake til kartet** (`challenge.toMap`) and **Spill igjen** (`challenge.again`). The whole sentence is announced and spoken after the last task's success sentence (`NorwegianVoice.sayAfterCurrent` queues it instead of cutting the success off).
- **Number bars:** a bar is 50 pt wide and 22 pt per unit tall on a faint unit grid (`BarMetrics`); its colour comes from `BarPalette` (ten deep colours, white on them 4.7:1 or better), its face from `BarFace` (dot eyes, line mouth, a few variants; the 10-bar has golden unit lines), and its white numeral fades with the node's range (`BarRules.numeralOpacity`: hidden to 5, 0.55 to 10, 0.8 to 19, opaque from 20). The numeral is decorative reinforcement: the unit lines and the accessibility label `Stolpe 7` carry the value, so a faint numeral never has to be read. Hit areas are 20 % larger than the drawing (`BarMetrics.hitMargin`, 5 pt on every side) and at least 48 pt tall; `BarMetrics.hitFrame` is the same area for touches and for drop detection. One `DragGesture` with no minimum distance and high priority handles every touch on a bar, so the scroll view behind the shelf never takes a lifted bar: a touch that ends before travelling 10 pt is a **tap** (places the bar in the zone in build mode, or shows its cut markers in split mode and for a bar too tall for the zone, which also shakes); a first movement that is mostly horizontal is a **cut** sweep on any bar taller than 1 (a 1-bar is carried instead; a dashed cut line follows the finger; releasing after at least 28 pt cuts there with a white flash and a small recoil of the two parts), and a sweep that travels past one slot, or lasts longer than 0.45 s after travelling 30 pt, turns into a carry so that dragging a bar onto its neighbour never cuts it; anything else is a **carry** with a 1.08 scale and a deeper shadow, the zone and the bar under the finger show dashed outlines, dropping on another bar combines them (squash-and-stretch of the result plus a ring of twelve capsules where the result stands), dropping on the zone places it, anywhere else springs back. The shelf draws above the zone and the play area above the rest of the scrolling screen, so a carried bar stays on top of the task panel, the zone, the feedback and the buttons; only the footer with the sound button stays above it. The outcome of a gesture is applied on the next run-loop turn (never inside the gesture's own end callback: removing the bar's view there left SwiftUI's update loop spinning on the simulator), the shelf never gets narrower than it started, so placing a bar never re-centres the shelf (bars to the right of the gap close it by one slot, the others stay where they are), and a drag the system cancels is cleared when the scene leaves the active phase. A refused move shakes the bar (three cycles, 0.35 s). Under Reduce Motion there is no shake, flash, recoil, squash or ring and layout changes are instant. Identifiers: `bar.target`, `bar.piece.<value>`, `bar.cut.<bottom>`, `bar.zone`, `bar.currentTotal`, `bar.hint`, `bar.takeBack`. VoiceOver gets every cut as a custom action (`Del i 3 og 4`) and the zone as a button that takes the last bar back. `Tallstolpene` is the feature's name in this document; the child sees and hears the activity titles (`Bygg med stolper til 10`, `Del stolpen til 6`).
- **Home:** a full-width `MapCard` (`home.map`) sits between the hero and the activity grid, showing the star total and the next node; it is narrated after the four games and glows while named. Settings gains a **Talløyene** section right under the level picker, so it is on screen without scrolling the sheet (`settings.mapStars`, `settings.resetMap`, confirmed by **Nullstill Talløyene**).
- **Place value (version 9):** `PlaceValueView` draws base-ten blocks at one scale (`PlaceBlockStyle.unit` 11 pt: a unit square, a rod of ten unit lines in the tens-rod brown, a teal ten-by-ten tile, an indigo cube with a lighter top and a darker side face). The tray offers one bin per place of the level (tap adds one block; the bin is also draggable onto the workspace through the system drag, like the pieces of Bygg tallet); the workspace shows one column per place, highest first, with the count digit above the stacked blocks while showing or taking away (a reading task hides the digits, which would spell the answer; VoiceOver hears the counts in the column labels): rods side by side, loose ones in ten-frames of two columns of five at the rods' unit size (ten ones are exactly as big as the rod they become), tiles and cubes fanned 12 pt apart with dark edges, so every one of them can be counted. Numbers on these screens are written digit for digit (`1630`, never `1,630` or `1 630`): a device's own grouping would put a comma, which is the decimal mark in Bokmål. Every column keeps the width its place can ever need, so the layout never changes during a task, and a window too narrow for the row lets it scroll sideways. Every column is a button: it takes one block away while showing, and in a take-away task the ones column removes a unit while a higher column breaks one block into ten (the borrow). A carry shows the ten blocks for 0.45 s before they slide off towards the next place up and the new block scales in; a broken block disappears and ten smaller ones scale in. Under Reduce Motion there is no pause and no movement. Tusenøya is wider than the four-stone islands, so its six stones keep the same spacing. Reading tasks show four numeral cards (`place.choice.<n>`, tried ones dimmed and captioned). Identifiers: `place.target`, `place.tray.<unit>`, `place.column.<unit>`, `place.number`, `place.removed`, `place.choice.<n>`, `place.hint`, `place.restore`. The island is hosted by the hedgehog.
- **Equation balance (version 10):** `BalanceView` shows a white board with two trays on a soil beam and a post between them (an `=` above the post from the hybrid phase on). The hidden number is a lilac closed bud with an ink question mark (it opens into six petals around a yellow disc with the number when solved; still under Reduce Motion). Positive cards are warm filled tiles and inverse cards white tiles with a dashed blue border; both show dots in the picture phase (the inverse card adds a bare minus), dots with `+n` or `−n` in the hybrid phase and the numeral alone with symbols; the hand holds eight cards (`balance.card.plus.<n>` / `balance.card.minus.<n>`). The trays are two rows high from the start and wrap their cards; a side never keeps more than five cards (more are gathered into the fewest cards, `Kortene ble samlet til færre kort.`), so the trays and the hand below them keep their place; both sides use one card size, so a mirror looks like its card. When the board is solved the hand stays where it is, dimmed, so **Neste oppgave** never appears under the finger. **Få et hint** is `balance.hint`. With VoiceOver the move sentence ends with the new board (`Vekten viser nå: knoppen pluss 1 er 5.`). A plus card lands on the left and its mirror on the right as a ghost (translucent, dashed) for a moment; a minus card is seen next to the amount it takes on both sides in a small capsule (`+2 −2 = 0`, no numeral in the picture phase) that fades upwards. Boards that start with two or three buds keep a single rail under the board with **Del i 2** or **Del i 3** (`balance.divide.<n>`, 50 pt tall), dimmed once used, so nothing below it moves. The task panel shows the question, the goal in words (`balance.goal`: `Legg samme kort på begge sider til knoppen står alene.`), from the hybrid phase on the symbols (`balance.symbols`, spoken as `knoppen pluss 3 er 7`) and the move count (`balance.moves`, `Trekk: N`); the solved banner carries the stars (`balance.stars`). Each side is one VoiceOver element (`balance.left`, `balance.right`). The island is hosted by the butterfly.
- **Recovery:** Child must always be able to return to the home screen, reset an in-progress selection where appropriate, and continue after an incorrect answer.

## 8. Norwegian text and speech

The child-facing UI uses Norwegian **Bokmål** conventions. Important established phrases include: `Bygg tallet`, `Finn tallvennen`, `Del opp`, `Tallverkstedet`, `Innstillinger`, `Tilbake`, `Neste oppgave`, `Start på nytt`, `Få et hint`, `Sjekk svaret`, `Les opp oppgaven`, `Les opp regnestykket`, `Les opp valgene`, `Velg tall`, `Lyd på` / `Lyd av`, `Hvor store tall?`, `Nullstill antall løste oppgaver`, and since version 8 `Talløyene`, `Byggeplassen`, `Ta tilbake`, `Tilbake til kartet`, `Spill igjen`, `Alle oppgavene er løst!`, `Nullstill stjerner og låser på Talløyene`, and since version 9 `Vis tallet`, `Les tallet`, `Ta bort og veksle`, `Brikker`, `Legg tilbake`, `enere`, `tiere`, `hundrere`, `tusenere`, and since version 10 `Likevekt`, `Kort til begge sider`, `Del i 2`, `Del i 3`, `Trekk`. Menu narration says `Velg en lek.` followed by the four game names and `Talløyene`, and `Hvor store tall vil du leke med?` followed by `Til 20`, `Til 40`, `Til 100`. Numbers on screen are written digit for digit with no grouping separator (`1630`): a device's own number formatting would print `1,630`, and in Bokmål the comma is the decimal mark, so any number that can reach four digits is drawn with `Text(verbatim:)`. Spoken button sentences use the definite form after prepositions (`Ta bort én fra det andre tallet`), and no level description promises subtraction: subtraction appears only on the map, in the place-value take-away task (`Ta bort og veksle`) and on the balance's minus cards. `Plassverdi` is the feature's name in this document and in the code; the child sees and hears the node titles (`Vis tallet til 19`, `Ta bort og veksle til 99`).

All feedback phrases are produced by `GameCopy` in `GameSessions.swift`, so they can be reviewed in one place and are covered by tests. Examples:

- `Du har 14. Du trenger 6 til.`
- `Det blir for mange. Prøv en mindre brikke!`
- `Prøv igjen. 18 pluss 7 er 25. Det er for lite. Tell hvor mange som mangler til 40.`
- `Riktig! 18 pluss 22 er 40.`
- `Kjempebra! 40 er 17 og 23 sammen.`
- `Du har 12 til venstre. Du trenger flere prikker til venstre.`
- `Bygg 14 med stolpene.` · `2 og 2 ble 4.` · `7 ble 3 og 4.` · `Det blir for høyt. Prøv en lavere stolpe!` · `6 pluss 4 er 10. Bra bygget!`
- `Del stolpen 8 i 3 og 5.` · `Du har 2 og 6. Oppgaven er 3 og 5. Dra stolpene sammen og del på nytt.` · `8 er 3 og 5. Kjempebra!`
- `Velkommen til Talløyene. Trykk på et tall for å begynne.` · `Oppgave 3. Del opp til 20.` · `Låst. Løs oppgave 2 først.` · `Alle oppgavene er løst! Du fikk 3 stjerner.`
- `Vis tallet 47 med brikkene.` · `Ti enere ble én tier. Ti tiere ble én hundrer. Du har 100. Du trenger 20 til.` · `4 tiere og 7 enere er 47. Flott!` · `Du har 32. Ta bort 5.` · `Ingen enere igjen. Trykk på en tier for å veksle den i ti enere.` · `32 minus 5 er 27. Kjempebra!`
- `Hva gjemmer seg i knoppen? Legg samme kort på begge sider til knoppen står alene.` · `Du la minus 2 på begge sider. 2 og minus 2 ble null.` · `5 ble 2, 2 og 1.` · `Begge sidene ble delt i 2 like deler.` · `3 kan ikke deles i 2 like deler. Legg kort på begge sider først.` · `Ved siden av knoppen er det bare 3. Prøv et mindre minuskort.` · `Knoppen åpnet seg: tallet er 4! Du brukte 2 trekk.`

Singular and plural forms are handled (`1 prikk` / `2 prikker`, `1 oppgave løst` / `2 oppgaver løst`). Ensure feedback reflects **the child's actual solution**, not only the originally generated pair. Avoid grammatical constructions that sound awkward when read by speech synthesis. Use digits on screen when they help quick recognition; on-device voices read short Norwegian arithmetic phrases well.

`NorwegianVoice` wraps `AVSpeechSynthesizer` and chooses the best installed Norwegian voice: `NorwegianVoice.bestNorwegianVoice(among:)` prefers a Bokmål tag (`nb`) over any other Norwegian tag (`nn`, `no`) and then the highest quality (Premium over Enhanced over the compact default), never a Personal Voice or a novelty voice; the choice is cached and recomputed when `AVSpeechSynthesizer.availableVoicesDidChangeNotification` fires, so a voice downloaded in Settings › Accessibility › Read & Speak (Spoken Content on iPadOS 17 and 18) › Voices is used without a restart. The rule works on plain `VoiceCandidate` values and is covered by `VoiceSelectionTests`. Siri's voices are not exposed to apps. If no Norwegian voice is installed, the iPad's default voice reads the Bokmål text (which may then be mispronounced). It stops previous feedback before speaking a new phrase; the one exception is the completion sentence of a map node, which `sayAfterCurrent` queues after the last task's success sentence. Automatic speech (the task prompt when a puzzle starts, feedback, hints) follows the `speakNorwegian` setting and steps aside while VoiceOver is running, because VoiceOver already reads the same text through announcements; the explicit **Les opp oppgaven** and **Les opp regnestykket** buttons always speak. The availability or exact character of the synthesized voice depends on the installed iPadOS voice resources. Do not embed cloud speech APIs, recorded children's voice data, or audio tracking without a separate user-approved design. Since version 12 the app sets the audio session category to ambient at launch (`SoundCuePlayer.prepare`), so speech and the sound cues mix with other apps' audio instead of stopping it and respect the iPad's silent mode.

## 9. Privacy, security, and dependencies

- This is an **offline-first and currently fully offline** educational app. Preserve that property.
- The app should not contain accounts, login, external links inside game screens, advertising SDKs, analytics, payment flows, or subscriptions.
- Do not collect names, birth dates, precise location, microphone recordings, voice input, photos, contact lists, or persistent child identifiers.
- Do not introduce permissions merely for convenience. Standard speech synthesis requires no microphone permission.
- Preserve the privacy manifest; review it when a new accessed API is introduced. The only declared category is UserDefaults (reason `CA92.1`).
- Never log sensitive user data. Local solved counts and difficulty are sufficient for this version.
- Avoid network libraries, third-party package managers, or runtime downloads in the current scope.
- If the project grows, list every external package and its license in documentation and review its data practices before merging.
- The app target carries the owner's bundle identifier `com.roysworld.tallhagen` and team (see Distribution below); the test targets keep `com.example.TallhagenTests` and `com.example.TallhagenUITests`. Anyone else installing the app sets their own identifier and team. Do not hardcode someone else's development team ID or credentials.
- Do not include provisioning profiles, signing certificates, API tokens, or personal keys in archives or version control.
- **Distribution (version 7):** the owner's bundle identifier and development team are set in the app target (automatic signing); keep them. Since version 11 the identifier is `com.roysworld.tallhagen`, lowercase at the owner's request (versions 7 to 10 used `com.roysworld.Tallhagen`). The app target sets `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` (no encryption of its own, no network) and `INFOPLIST_KEY_LSApplicationCategoryType = public.app-category.education`; both keys are verified in the generated Info.plist. App Review Guideline 5.1.1(i) wants the privacy policy reachable inside the app: `PrivacyPolicy.address` in `Theme.swift` holds the hosted address since version 11 (https://riversen.github.io/Tallhagen/privacy.html, served by GitHub Pages from `docs/privacy.html` in the public repository `riversen/Tallhagen`, which also serves `support.html`), and Settings shows a "Personvern" section (`settings.privacy`) with the address as plain text, neither a link nor selectable (selectable text offers Share on a long press, and Settings has no parental gate); `Tools/release.sh` refuses to archive unless it is an https address. The submission kit in `AppStore/` (texts in Norwegian Bokmål and English, privacy policy, questionnaire answers, screenshots, checklist) and `Tools/release.sh` (logic tests, Release archive for `generic/platform=iOS`, export or upload with `AppStore/ExportOptions.plist`) are maintained with the app: every listing text must describe only what the app does (App Review Guideline 2.3), the screenshots must be recaptured after visual changes (simulator captures carry an alpha channel; flatten them, and rotate landscape captures with `sips -r -90`), and the owner's email address never goes into the kit (placeholders only). Creating the App Store Connect record, signing and uploading are the owner's steps. The hosted pages live only in the `docs` folder of the public repository `riversen/Tallhagen`, not in the project folder the ZIP is made from, so the kit's copy of the policy keeps its placeholders. Since 2026-11-06 the same repository also holds this project's source (the files of the ZIP; `.gitignore` keeps out ZIPs, user data, build output, test results, signing material and App Store Connect API keys), like the owner's EriksDay repository. To publish a later version, mirror the project folder into a clone of the repository so that deleted and renamed files go there too (`rsync -a --delete --exclude=/.git/ --exclude=/docs/ --exclude=.DS_Store --exclude='*.zip' --exclude=xcuserdata/ --exclude=DerivedData/ --exclude=/Tallhagen.xcodeproj/project.xcworkspace/ <project folder>/ <clone>/`, both paths ending in a slash), keep its `docs` folder, stage everything with `git add -A`, check `git status`, commit and push; never copy `docs` into the project folder or a ZIP, because the hosted pages carry the contact address.

## 10. Build and test instructions

### On Linux or macOS with Swift installed

From the repository root:

```bash
./Tests/run.sh            # optionally: ./Tests/run.sh --rounds 1000
```

The script compiles `MathLogic.swift`, `GameSessions.swift`, `Tests/SeededGenerator.swift`, `Tests/LogicChecks.swift` and `Tests/main.swift` with `swiftc`, runs the checks and cleans up. The checks run in every build configuration (they do not rely on `assert`). They cover:

1. All five persisted level IDs, their Norwegian labels, maxima, and the fallback for unknown stored values.
2. **10,000 seeded randomized rounds per level** across the three puzzle generators, plus a short unseeded run with the system generator.
3. Valid positive operands, exact sums, piece identities, solvability from the offered pieces, the four unique multiple-choice answers, and split invariants.
4. A deterministic target sweep for each supported number limit, including explicit totals of **40**.
5. Seed reproducibility.
6. The workshop's ability to represent exactly 40 and prohibit 41, at every maximum.
7. The four session state machines: wrong answers keep puzzles active, overshooting pieces are rejected without side effects, `.solved` is reported exactly once, undo and restart, honest hints, locking after completion, clamping, and level changes in the workshop.
8. Norwegian copy helpers (singular/plural, lists).
9. (Version 8) The bar rules and both bar generators (10,000 seeded rounds per node range, every target of every range, seeded reproducibility), the bar session (combine with both refusals told apart, cut, place, take back, locking, hints, random play that never passes the target, a shelf cut into 24 ones, and a property check that plays random cuts, combines, placements and take-backs and then follows the hints to the solution: every hint names bars that are on the shelf), the searches behind the hints (`fewestBars`, `cutToComplete`), the numeral opacity table, the map (islands, numbering, every node identifier pinned as a storage key, fourteen in version 8 and twenty-three since version 10, four tasks per node, predecessor chain), `MapProgress` (parsing of damaged strings, best-result keeping, unlock derivation, round trips), `ChallengeRules`/`ChallengeRun` and the map copy.
10. (Version 9) Place value: units, blocks, regrouping and borrowing, the three task generators at every level (10,000 seeded rounds each, every read and take-away target), the session (carries, borrows, refusals, undo, reading, random play that never overshoots), and the copy.
11. (Version 10) The balance: cards, the board's maximum and stars, the allowed moves, the three phase generators (10,000 seeded rounds each), every board the generators can make against an independent depth-limited search (the breadth-first length is the true shortest), the session (mirrored cards with their own identities, change-making whose sentence matches the board, refusals that cost nothing, gathering past five cards, divisions, locking, random play from which the hints still take the shortest way, the node reports), and the copy.

For an additional syntax-only check (does not type-check SwiftUI against an Apple SDK):

```bash
swiftc -frontend -parse Tallhagen/*.swift
```

A syntax pass is not proof that SwiftUI layout, iOS APIs, or Xcode build settings are correct.

### Xcode project file checks

On macOS, inspect `Tallhagen.xcodeproj/project.pbxproj` or run:

```bash
plutil -lint Tallhagen.xcodeproj/project.pbxproj Tallhagen/PrivacyInfo.xcprivacy
xmllint --noout Tallhagen.xcodeproj/xcshareddata/xcschemes/Tallhagen.xcscheme
xcodebuild -list -project Tallhagen.xcodeproj
```

On a platform without the Apple `plutil` command, the project file is an OpenStep-style plist, not an XML plist; test with an appropriate OpenStep plist parser when available, or verify with Xcode on a Mac. Do not attempt to validate it by parsing it as JSON.

### Build and test with Xcode on macOS

1. Install Xcode 16 or newer with an iPadOS 17+ simulator runtime.
2. Open `Tallhagen.xcodeproj`; the shared `Tallhagen` scheme builds the app and tests both bundles.
3. For an actual device, select an Apple Personal Team or a provisioned development team under Signing & Capabilities and set unique bundle identifiers.
4. Select an iPad Simulator or connected iPad.
5. Build and Run (Command–R); Test (Command–U).
6. Confirm on-device speech and dragging; a simulator alone cannot replace a touch test with a child.

Command-line equivalents (substitute any available iPad simulator name and OS):

```bash
xcodebuild -project Tallhagen.xcodeproj -scheme Tallhagen -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4),OS=18.2' build

xcodebuild -project Tallhagen.xcodeproj -scheme Tallhagen \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4),OS=18.2' \
  -only-testing:TallhagenTests test

xcodebuild -project Tallhagen.xcodeproj -scheme Tallhagen \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4),OS=18.2' \
  -only-testing:TallhagenUITests test
```

The UI tests pin the level through UserDefaults launch arguments (`-learningLevel 4`) and read the random numbers from the screen through accessibility identifiers; they never pin `solvedTotal`, because an argument-domain value would shadow the app's own writes for the whole process. The map test clears `islandStars` through the Settings control first (the simulator keeps the stars between runs), reads the task from `bar.target`, solves four bar tasks by tapping bars whose values add up (a subset-sum over the shelf), checks the completion card, the opened padlock and the stars on the map, cuts a bar on node 2 with a cut marker, and resets again; it keeps screenshots of the map, the markers and the completion card as attachments. A second map test pins `islandStars` for one launch through the argument domain (`-islandStars "bars-build-5=3,…"`, so node 5 is open), opens *Bygg tallet til 20* while Til 100 is stored, checks that the strip replaces the title row, that the target stays within 20 and that one solved task fills a leaf, and goes back to the map. They force portrait orientation, scroll towards an element in either direction before tapping it, and bring a lazily rendered card grid on screen (its heading hittable) before counting cards, so they also hold on smaller iPads. One UI test changes the level through Settings, relaunches the app to confirm persistence, and then sets the level back to Til 20.

### Recorded results (Xcode 26.5, macOS, 2026-11-05 and 2026-11-06, versions 6 to 12)

| Check | Result |
| --- | --- |
| `./Tests/run.sh` (10,000 rounds per level, seed 2026, five levels) | Passed, 1,906,309 checks (identical count on repeated runs) |
| `swiftc -frontend -parse Tallhagen/*.swift` | Passed |
| Full type-check of every app source against the iOS 17.0 simulator SDK (`xcrun -sdk iphonesimulator swiftc -typecheck -target arm64-apple-ios17.0-simulator -swift-version 5 Tallhagen/*.swift`) | Passed, no warnings |
| `plutil -lint` on project and privacy manifest, `xmllint` on the shared scheme, `xcodebuild -list` | OK |
| App build, iPad Pro 13-inch (M4), iOS 18.2 simulator | Build succeeded, no Swift warnings |
| App build, iPad (10th generation), iOS 17.0 simulator (deployment target) | Build succeeded; the app was also installed and launched there with `xcrun simctl`, and the chooser and home screens rendered with the iOS 17 gradient sky |
| `TallhagenTests` on the iOS 18.2 simulator | 16 tests, 0 failures |
| `TallhagenUITests` on the iOS 18.2 simulator | 9 tests, 0 failures in one run (about 5 minutes; the garden's animation clocks did not slow the tests) |
| Manual simulator inspection (iOS 18.2, portrait and landscape) | Home, chooser, Bygg tallet idle and solved (snail reaction, sprouting flower, bouncing check mark), grass footer and progress bed checked by screenshot |
| Version 7: `TallhagenTests` (20 tests, with `VoiceSelectionTests`) and `TallhagenUITests` (9 tests) on the iOS 18.2 simulator | 0 failures in one run |
| Version 7: Release archive for `generic/platform=iOS` (unsigned, `CODE_SIGNING_ALLOWED=NO`) | Archive succeeded; the bundle carries `com.roysworld.Tallhagen`, version 1.0 (1), `ITSAppUsesNonExemptEncryption = false`, `LSApplicationCategoryType = public.app-category.education`, MinimumOSVersion 17.0 and the privacy manifest |
| Version 7: App Store screenshots | Nine simulator captures (seven portrait 2064x2752, two landscape 2752x2064) flattened to PNG without alpha in `AppStore/screenshots/13-inch` |
| Signed archive, upload, App Store Connect | Not performed (owner's Apple ID required) |
| Physical iPad, Reduce Motion, Increase Contrast, Split View | Not performed; the code paths are gated but were not exercised on a device |
| Version 8: `./Tests/run.sh` (10,000 rounds per level and per bar range, seed 2026) | Passed, 2,399,342 checks (identical count on repeated runs) |
| Version 8: `swiftc -frontend -parse Tallhagen/*.swift` and the full iOS 17.0 type-check of every app source | Passed, no warnings |
| Version 8: `plutil -lint` on project and privacy manifest, `xmllint` on the shared scheme, `xcodebuild -list` | OK |
| Version 8: App build, iPad (10th generation), iOS 17.0 simulator (deployment target) | Build succeeded, no Swift warnings; installed and launched there with the simulator tools |
| Version 8: `TallhagenTests` and `TallhagenUITests` on the iPad Pro 13-inch (M4), iOS 18.2 simulator, one full run of both bundles (the build of this run is the iOS 18.2 app build) | 28 unit tests and 12 UI tests, 0 failures (about 8 minutes, the device used by nothing else) |
| Version 8: Review before packaging | A five-lens code review with three adversarial verifiers per finding upheld 28 of 45 findings. The most serious was a crash: the bar hint searched every subset of the shelf with a limit of 12 bars, and about eight cuts on a *Bygg med stolper til 20* task passed it. All 28 were fixed or documented. A second review of the fixes (three lenses, two adversarial verifiers per finding) upheld eight smaller points: the wording of a hint that counts ones, two checks that pin the cut rule, the outer edge of the end cut markers, and five documentation details. They were fixed too, and the run above is on that code. Two earlier runs that day (10 of 11 UI tests, one wrong test expectation; then 11 of 11) were on the code before the review |
| Version 8: Manual simulator inspection (iOS 17.0 iPad (10th generation), portrait and landscape) | Home with the map card, the map (first node open, padlocks, halo), a bar node before and after placing, a refused bar with its cut marker, a cut by marker tap, a sideways cut, a lift-and-drop combine, a bar carried into the zone (recorded on video: it stays above the zone panel all the way), a tap above a 1-bar placing it, node 5 inside the map with the butterfly in its strip and a target within 20 while the stored level was Til 100, and the solved state with the next button above the footer in landscape, checked by screenshot |
| Version 8: Physical iPad, Reduce Motion, Increase Contrast, Split View, VoiceOver cut actions | Not performed; the code paths are gated but were not exercised on a device. The two-row map strip of narrow windows was not seen on screen |
| Version 9: `./Tests/run.sh` (adds place value: 10,000 seeded rounds per level and task, every read and take-away target) | Passed, 5,566,096 checks (identical count on repeated runs) |
| Version 9: `swiftc -frontend -parse Tallhagen/*.swift` and the full iOS 17.0 type-check of every app source | Passed, no warnings |
| Version 9: App build, iPad (10th generation), iOS 17.0 simulator (deployment target) | Build succeeded, no Swift warnings |
| Version 9: `TallhagenTests` and `TallhagenUITests` on the iPad Pro 13-inch (M4), iOS 18.2 simulator, one full run of both bundles | 32 unit tests and 13 UI tests, 0 failures (about 8 minutes, the device used by nothing else) |
| Version 9: Review before integration | A five-lens review of the prepared place-value and balance code, with two adversarial verifiers per finding, raised seventeen place-value points: fifteen upheld by both verifiers (two of them duplicates), one split, one refuted. All were addressed before the code entered the project: reading tasks no longer show the digits above the columns, wrong readings no longer change the guide, the reading distractors differ in the high places, loose ones match the rods' unit size, the columns keep their widths for the whole task, a take-away task breaks at most one ten, every carry is named, Tusenøya's six stones no longer overlap, and the seeded checks no longer depend on a per-process hash. The screenshot check then found two more, also fixed before the run above: four-digit choices printed with the device's thousands separator (`1,630`, a decimal number in Bokmål) and fanned tiles too close together to count |
| Version 9: Manual simulator inspection (iPad Pro 13-inch (M4), portrait and landscape) | Node 19 (*Vis tallet til 999*) in landscape with hundred tiles and tens rods; node 20 (*Les tallet til 9999*) with nine fanned cubes that can be counted and four-digit choices written without separators; node 17 (*Les tallet til 99*) with no digits above the columns; node 18 (*Ta bort og veksle til 99*) before and after breaking a ten, with the second break refused; the map with Tusenøya's six stones apart; the home screen in portrait. Checked by screenshot on the iPad Pro 13-inch (M4) simulator |
| Version 9: Physical iPad, Reduce Motion, VoiceOver column labels, Split View with nine cubes | Not performed |
| Version 10: `./Tests/run.sh` (adds the balance: 10,000 seeded boards per phase, random play from reached boards, and every board the generators can make checked against an independent search for the shortest solution) | Passed, 5,950,451 checks (identical count on three runs) |
| Version 10: `swiftc -frontend -parse Tallhagen/*.swift` and the full iOS 17.0 type-check of every app source | Passed, no warnings |
| Version 10: App build, iPad (10th generation), iOS 17.0 simulator (deployment target) | Build succeeded, no Swift warnings |
| Version 10: `TallhagenTests` and `TallhagenUITests` on the iPad Pro 13-inch (M4), iOS 18.2 simulator, one full run of both bundles | 36 unit tests and 14 UI tests, 0 failures (about 9 minutes, the device used by nothing else) |
| Version 10: Reviews of the balance | The review of the prepared code upheld eighteen balance points (several found by two lenses) and split on five: card identities rebuilt on every read (so the mirrored ghost never showed), only net amounts drawn, negative amounts, hints that were not always shortest, a refused division costing stars and suggesting a division that could not work, a stuck zero puff, clipping trays, two rails with the same identifiers, small rail buttons, a low-contrast question mark, a UI test that opened a locked node. The balance was rewritten before it entered the project. A second review of the rewrite (three lenses, two adversarial verifiers per finding) upheld seventeen smaller points and split on two: change-making that took small cards before breaking a big one, so the sentence did not match the board; refusals saying `knoppen` with several buds; a too-full sentence that misstated the rule; trays that changed height under the finger; mirrors drawn at another size; the goal never shown on screen; the next-task button appearing under the finger that solved the board; VoiceOver not hearing the new board; a node rating no check could reach; and documentation details. All were fixed before the run above |
| Version 10: Manual simulator inspection (iPad Pro 13-inch (M4), landscape and portrait) | Home (8 av 69) and the map with six islands in landscape and portrait (Tusenøya's six stones apart, Likevektsøya beside it); node 23 (*Likevekt med tall og tegn*) in both orientations with three buds, the goal line, the trays two rows high and the rail; a recorded minus move (the +2 −2 = 0 pair rising above both trays while the 2s leave) and the division opening the bud with its number, three stars and the dimmed hand. Checked by screenshot and by video on the iPad Pro 13-inch (M4) simulator |
| Version 10: Physical iPad, Reduce Motion, VoiceOver side labels, Split View | Not performed |
| Version 11: `./Tests/run.sh` | Passed, 5,950,451 checks (the same count as version 10; the number logic is unchanged) |
| Version 11: `swiftc -frontend -parse Tallhagen/*.swift` | Passed |
| Version 11: `./Tools/release.sh --dry-run` | All checks passed without a warning; it reports the app bundle identifier `com.roysworld.tallhagen` and the privacy policy address https://riversen.github.io/Tallhagen/privacy.html |
| Version 11: `TallhagenTests` and `TallhagenUITests` on the iPad Pro 13-inch (M4), iOS 18.2 simulator, one full run of both bundles after the last code change | 36 unit tests and 14 UI tests, 0 failures (about 13 minutes on a busy Mac). The run before it failed one UI test, `testIslandMapNodeCompletionUnlocksTheNextNodeAndResetLocksItAgain`: a longer Settings level line wrapped to two lines and pushed the Talløyene reset row out of the visible part of the sheet. The line was shortened to «Oppgavene i lekene går opp til N.» and the full run repeated |
| Version 11: App build, iPad (10th generation), iOS 17.0 simulator (deployment target) | Build succeeded, no Swift warnings; the built app carries `com.roysworld.tallhagen` |
| Version 11: Manual simulator inspection (iPad Pro 13-inch (M4), Settings) | The level line reads «Valgt: Til 20. Tallvenner og pluss til 20. Oppgavene i lekene går opp til 20.» on one line. The Personvern section shows «Appen samler ikke inn opplysninger. Personvernerklæring:» and, on its own line, the address as plain text without link tint; a long press on the address opens no Copy or Share menu (checked before the last two text changes, which did not touch that section) |
| Version 11: Hosted pages (public repository `riversen/Tallhagen`, GitHub Pages from `main:/docs`, HTTPS enforced) | https://riversen.github.io/Tallhagen/, `/privacy.html` and `/support.html` return HTTP 200 and are byte-identical to the published files (checked 2026-11-06); http redirects to https |
| Version 11: Reviews before publishing | An independent review of the pages and the project changes (four lenses, two verifiers per finding) upheld 20 of 23 findings, and a check of the applied fixes upheld 7 of 11 more (two that its cap left unverified were confirmed by hand). Fixed as a result: the Settings privacy address is no longer selectable, because a long press offered Share, a way out of a Kids-category app without a parental gate; the support page's description of the home screen, its level answer (the level applies to the four games, not to the map), the list of read-aloud buttons, the iPadOS 26 and 27 menu name «Opplesing og tale» (Read & Speak), and its English quotation marks and navigation labels; the policy now names the stored progress and says that iCloud and computer backups include the values, so "only on the iPad" was also removed from the store descriptions and from Settings; checklist, README and kit wording; the measurement script in `LIMITS.md` no longer skips the privacy-address check silently; the publish and check scripts |
| Version 11: Physical iPad with the new identifier, signed archive, upload, App Store Connect record | Not performed |
| Version 12: `./Tests/run.sh` | Passed, 5,950,559 checks (108 of them new, for the sound cues and their gate) |
| Version 12: `swiftc -frontend -parse Tallhagen/*.swift` | Passed |
| Version 12: `./Tools/release.sh --dry-run` | All checks passed without a warning |
| Version 12: `TallhagenTests` and `TallhagenUITests` on the iPad Pro 13-inch (M4), iOS 18.2 simulator, one full run of both bundles after the last code change | 37 unit tests (the new `SoundCueTests` included) and 14 UI tests, 0 failures (about 19 minutes on a busy Mac); the sound-button test runs with sound on, so the engine starts in it |
| Version 12: App build, iPad (10th generation), iOS 17.0 simulator (deployment target) | Build succeeded, no Swift warnings |
| Version 12: The sound cues, rendered with `Tools/RenderSounds.swift` and measured | Peaks -28 to -22.5 dBFS and RMS -36 to -48 dBFS, far below the speech; spectral centroids about 300 Hz (knock), 0.8 to 1.1 kHz (ticks), 0.9 kHz (chime), 1.8 kHz (paper) and 2.5 kHz (applause); less than 1 % of the energy above 8 kHz, except 3 % for the applause |
| Version 12: Smoke test with sound on, final build, iPad Pro 13-inch (M4) simulator | Opening Bygg tallet, placing a piece, a refused piece and going back: the system log shows the audio engine starting with the first cue of each burst and pausing six seconds after the last; no audio errors, no crash. Whether the cues sound pleasant was not judged by ear |
| Version 12: Review of the sound cues | An independent review (three lenses, one verifier per finding) raised 16 points: 9 verified and upheld, 7 judged by hand; all fixed before the final test run. They covered the engine prepared at once, a free voice for each cue, stops in the background and on Lyd av, a rebuild after a media-services reset, and the knock moved from 196 to 300 Hz for iPad speakers. Also fixed: Velg tall and the Del stolpen bar choice added, random tick order, tighter checks, and the Settings sentence |
| Version 12: Upload (`./Tools/release.sh --upload`, 2026-11-06) | The first attempt archived but stopped at `exportArchive Copy failed`: a Homebrew rsync 3.4.4 in `/usr/local/bin` shadowed Apple's, and Xcode's export rejected it. The script now puts `/usr/bin` first on the PATH. The second attempt archived, exported and uploaded version 1.1, build 2: "Upload succeeded", processing in App Store Connect |
| Version 12: Listening on a real iPad; the App Store version 1.1 record and its submission | Not performed (1.0 was still in App Review; a version can be submitted only after it) |

## 11. Manual acceptance test plan

Perform these tests on a real iPad or simulator **after any change to math UI**. Record device model, iPadOS version, orientation, and result for each failing case.

### Global settings and navigation

- Fresh install opens Tallhagen without a login or network connection, straight into the level chooser: three cards (20, 40, 100) read aloud one by one, each glowing while named; tapping one lands on the home screen, which is then narrated the same way.
- Home screen shows the chosen level, the **Velg tall** button, four activities, and the sound button at the bottom; the sound button silences speech and the sound cues at once and shows a slashed speaker.
- Sound cues (version 12; listen on a real iPad, they are meant to be barely there): with sound on, a choice (a game card, the map card, an open stone, Neste oppgave, a back arrow) gives a soft paper slide; a change (a piece, the Del opp slider or buttons, a workshop step) a soft tick; a wrong answer, a refused move or a locked stone a soft knock; a solved task a short chime; a finished map task a faint applause when its card appears. Every cue is much quieter than the speech, none plays with Lyd av or «Les opp på norsk» off, and music from another app keeps playing.
- The home and the chooser stand in the garden (sky, sun, clouds, hills, flowers, grass footer) and every sentence is readable on white, the signboard or a cloud veil; the four guides idle on their cards and the card being narrated shows its guide perking up. The progress card shows one flower per solved task (groups of five, a gap after ten) and the count sentence agrees with it up to 40.
- Open a game: the sky band, corner sun and the game's guide beside the title appear; solve a puzzle and the guide reacts once (hop, wing beats or a loop), a small flower sprouts at its feet and the check mark bounces; the next puzzle returns it to idle. A wrong answer changes nothing about the guide. Returning home with a higher count grows the newest flower in the bed.
- Settings presents five choices: Til 10, Til 20, Til 30, Til 40, Til 100, and names the selected maximum. A "Personvern" section with the privacy policy address appears only in a build where `PrivacyPolicy.address` is set; it is plain text, never a link and not selectable: a long press on it opens no Copy or Share menu.
- Closing and reopening the app preserves chosen level and solved count.
- Resetting the solved count asks for confirmation and sets the home counter to 0.
- Device airplane mode does not break puzzles or app navigation.
- Back navigation, settings sheet dismissal, and screen scrolling work in portrait and landscape.
- Voice feedback can be enabled/disabled without affecting gameplay. With it on, each puzzle's task is read aloud when it starts; **Les opp oppgaven** reads it again on demand, even with the setting off.
- Voice quality: on an iPad with only the compact Norwegian voice, speech works but sounds mechanical; after downloading Nora (Enhanced or Premium) under Settings › Accessibility › Read & Speak (Spoken Content on iPadOS 17 and 18) › Voices › Norwegian, the next spoken sentence uses the better voice without restarting the app.
- Dark Mode and Smart Invert do not change the palette (the app always uses the light paper palette).

### Bygg tallet

- At Til 40, encounter a target of 40 by repeated new puzzles. Count all target dots visually: four separated groups of ten. At Til 100, frames show rows of ten; a target of 100 is ten rows.
- Verify at least one valid positive-pair combination works and a different valid combination works where pieces allow it.
- Tap a piece; it disappears from the available pieces and appears in the answer region with its own small dots and a plus sign between pieces.
- Tap a selected piece to undo it; verify the total decreases correctly.
- Drag a piece into the answer region; verify it is only counted once and that an overshooting drag springs back.
- Attempt an overshooting piece; no incorrect number is added and the feedback explains. When nothing could fit anyway, the same feedback also says to take a piece back.
- Select a piece that leaves an amount no remaining piece can fill; the feedback says so and the hint suggests removing a piece.
- Hint before any selection displays a valid pair; after a selection it names the pieces that complete it. When solved, the solved count increases exactly once.
- Check particularly tall piece cards containing 30–39 dots for clipping or broken hit targets.

### Finn tallvennen

- At Til 40, a target equation can be `18 + ? = 40` or another valid positive pair totaling 40.
- Exactly four distinct choices appear and exactly one is correct.
- The dot frame shows the given amount filled and the missing amount as dashed empty slots.
- A wrong choice keeps the puzzle active, dims that choice, and the feedback states the real sum and direction.
- A correct choice reveals the missing number, fills the empty slots in a second colour, and permits the next puzzle.
- Two-digit numerals and operators fit without overlap in both orientations.

### Del opp

- At Til 40, show 40 dots and a requested left grouping of 1–39.
- The starting position is never already correct.
- Slider and +/- controls keep both groups nonempty; the buttons disable at the ends.
- At each movement, left + right remains exactly 40.
- Error guidance points in the correct direction.
- Correct grouping locks the controls and enables the next puzzle.
- Both dot panels remain countable and visible at their extremes.
- In Split View at the narrowest width, the two groups stack vertically and the buttons keep their size.

### Tallverkstedet

- In Til 40, increment until the displayed total is exactly 40; the total frame shows the two amounts in two colours.
- Verify `39 + 1 = 40` is accepted and + is disabled at that point.
- Verify `20 + 20 = 40` can be reached via +/- interactions.
- Neither operand can be decremented below 1.
- Total is never shown as 41 at the selected 40 limit.
- The speak-the-equation button reads an accurate Norwegian equation even when automatic speech is off.
- Repeat at each lower limit to confirm level-specific caps are preserved; change the level from 40 to 10 while 39 + 1 is shown and confirm it becomes 9 + 1.

### Talløyene and Tallstolpene

- The home screen shows the **Talløyene** card with the star total (`0 av 69` on a fresh install) and the next node; the card is narrated after the four games and glows while named.
- The map opens as a pond with six islands in a horizontal row (Tusenøya wider than the others for its six stones); in landscape two to three islands are visible at once, in portrait the row scrolls. Each island shows its guide, its sign (number and name) and its stepping stones joined by dotted paths. Only node 1 is open on a fresh install: every other node shows a padlock and cannot be tapped (VoiceOver reads `Låst. Løs oppgave N først.`). The next open node breathes a soft halo (still under Reduce Motion).
- Open node 1 (*Bygg med stolper til 5*): the status strip replaces the title row (arrow back, blue `1` badge, four empty leaves, the activity name and the snail at regular widths), the task reads `Bygg N med stolpene.` aloud, and the play area shows the shelf with four bars on a unit grid and the building zone with the dashed target bar beside it (landscape) or above it (portrait).
- Tap a bar: it moves into the zone and the zone shows the running total as bars (a tens rod plus units above ten). Tap a bar that is too tall: it shakes, `Det blir for høyt. Prøv en lavere stolpe!` is spoken and its cut markers appear; tapping a marker cuts it there. Drag a bar onto another: the result squashes and stretches and a ring of capsules flies out; dragging two bars whose sum would pass ten or the remaining amount shakes the dragged bar and springs it back. Sweep sideways across a bar: a dashed cut line follows the finger, releasing cuts the bar with a white flash and a small recoil. While dragging, the zone and the bar under the finger show dashed outlines and the zone tints when the bar is over it. Tap the zone or **Ta tilbake** to return the last placed bar. Carry a bar into the zone: it stays drawn above the zone panel all the way. Sweep sideways across a 1-bar: it is carried, never cut.
- On node 8 (*Bygg med stolper til 20*), cut bars into ones until the shelf is long, then tap **Få et hint**: the hint counts the ones (`Prøv 14 enere.`), names only bars that are on the shelf, and following it solves the task. After placing and combining so that no bar fits, the hint proposes one cut (`Del stolpen 3 i 2 og 1.`) and then the bars that complete the zone.
- Finish four tasks: after every solved task a leaf fills; after the fourth the screen stops taking touches for about a second, then the completion card appears over a dimmed screen with the happy snail, the stars popping in one by one, `Alle oppgavene er løst! Du fikk N stjerner.` spoken after the task's own success sentence, **Tilbake til kartet** and **Spill igjen**. Back on the map node 1 shows its stars, node 2's padlock has opened and node 2 now breathes the halo; the home card and Settings count the stars.
- Node 2 (*Del stolpen til 6*): one bar on the shelf, the task `Del stolpen 6 i 2 og 4.`; a wrong cut keeps the task active with `Du har 1 og 5. Oppgaven er 2 og 4. Dra stolpene sammen og del på nytt.`; dragging the parts together restores the bar; the right cut (either order) solves. Node 8 (*Bygg med stolper til 20*) always shows a tens rod in the ghost and in the built total.
- Settings › Talløyene names the star total and **Nullstill stjerner og låser på Talløyene** (disabled at zero) asks for confirmation, then every node but the first is locked again while `solvedTotal` is unchanged.
- Bars and the map under Reduce Motion: no shake, flash, recoil, squash, ring or halo pulse; stars appear at once; layout changes are instant.

### Plassverdi (Tusenøya)

- Node 15 (*Vis tallet til 19*): the tray shows an `ener` and a `tier` bin; tapping the tens bin adds a rod to the tens column, tapping the ones bin adds squares; the running total (`Ditt tall`) follows; a tenth unit becomes a rod with a short pause (the ten squares are seen, then they leave towards the tens column and a rod appears); one block too many is refused with `Det blir for mye`. Tapping a column takes a block back.
- Node 17 (*Les tallet til 99*): the workspace shows a number as rods and units, with no digits above the columns; the four cards hold the number, its digit-swapped twin and neighbours; a wrong card stays dimmed with `Prøvd`.
- Node 18 (*Ta bort og veksle til 99*): `Du har 32. Ta bort 5.`; the ones column removes units one at a time; when it is empty the feedback asks to break a ten, tapping the tens column turns one rod into ten squares (a second ten is refused with `Du har nok enere. Ta bort enere først.`), and the task is solved exactly at the difference; **Legg tilbake** restores the last unit.
- Nodes 19 and 20 show tiles and cubes; nine cubes still fit the workspace in portrait and landscape.

### Likevekt (Likevektsøya)

- Node 21 (*Likevekt med bilder*): both trays show dot cards and the bud, and the hand's cards show dots without numerals (a minus card adds a bare minus); with at least 2 beside the bud, tapping the minus card with two dots (`balance.card.minus.2`) shows above each side a capsule with a two-dot card beside a two-dot minus card, which fades upwards while 2 leaves each tray (a bigger card is changed into smaller ones first); tapping the plus card with one dot (`balance.card.plus.1`) puts a card on the left and its ghost on the right, which turns solid; when the bud is alone it opens with its number and the move count; the stars match the moves (three for the shortest).
- Node 22 (*med bilder og tall*): the symbols line reads `? + 3 = 7` and changes with every move; a minus card bigger than the amount beside the bud is refused without a move (`Ved siden av knoppen er det bare 3.`); taking 2 from a 5 changes the 5 into smaller cards first; following the hints always earns three stars.
- Node 23 (*med tall og tegn*): with two or three buds the prompt says that every bud hides the same number and the rail offers the matching division; a division the left amount does not allow is refused without counting a move; halving first is sometimes the shortest way, and the hint says so.

### Accessibility and usability

- VoiceOver reads every puzzle's essential instructions and actionable controls, announces feedback when it appears, and speaks the new amounts after every plus/minus step. With VoiceOver on, automatic speech does not double up with the announcements.
- Larger text sizes up to xxxLarge remain usable; no success state is communicated by colour alone.
- All important touch targets are easy to hit, even with a child's small hands.
- Dragging is optional rather than required.
- Reduce Motion removes the spring animations and stills the whole garden: no swaying flowers, drifting clouds, breathing sun, idle creatures, hops, bursts or symbol effects, only instant state changes and a brief fade of the creatures' eyes and halos.
- Increase Contrast shows flat paper instead of the sky; Reduce Transparency makes the cloud veils and clouds opaque; in both, every sentence stays readable and the dot frames are unchanged.
- In Split View at 320 pt and at the accessibility text sizes, the title-row creature and the chooser posts disappear, titles stay on one line, and the footer keeps the sound button clear of its flowers.
- A 40-dot screen scrolls naturally without accidentally tapping buttons off-screen.

## 12. Automated and static audit before delivery

Before producing an archive:

1. Run `./Tests/run.sh` and record the actual output.
2. Run `swiftc -frontend -parse Tallhagen/*.swift` and address any parse failures.
3. On a Mac, build and run both test bundles with `xcodebuild … test` and record the results in section 10.
4. Validate the Xcode project file, the shared scheme and the privacy manifest using suitable tools.
5. Search **all text files and filenames** for unapproved publisher/competitor names, stale number ranges, test scaffolding, secrets, and accidental placeholder branding. The creatures' working names (Rulle, Flagra, Summa, Noste) may appear only in code comments of `GardenCreatures.swift` and in this document, never in displayed or spoken text, assets or identifiers.
6. Check binary artwork separately for provenance; string search is not a substitute for reviewing images. The icon is generated by `Tools/MakeIcon.swift`; regenerate it from there if it changes. The garden and the creatures are code only (no image files); review their drawings on screen for resemblance to any third-party character before a release.
7. Confirm documentation describes 40 as an **available selectable level**, not as the limit of every lower level.
8. Confirm references to methods, storage keys, identifiers and file paths in this document still match the source.
9. Recreate the ZIP from the updated project directory with a new version number (`Tallhagen-iPad-vN.zip`), excluding `.DS_Store`, `xcuserdata`, DerivedData and earlier ZIPs (and, in a clone of the repository, `.git` and `docs`). Inspect ZIP contents to ensure the new `agent.md`, the shared scheme, `Tools/`, `AppStore/` and the test directories are included.
9b. Before a store submission: reread every file in `AppStore/metadata` against the current features and character limits (`AppStore/metadata/LIMITS.md`), recapture and flatten the screenshots if anything visible changed, run `Tools/release.sh --help` and an unsigned archive (`xcodebuild archive … CODE_SIGNING_ALLOWED=NO`) to prove the Release build, and bump `CURRENT_PROJECT_VERSION` for every upload.
10. If a Mac/Xcode build was not performed, report that limitation plainly. Never label a syntax parse or Foundation-only test as a successful iPad runtime test.

### When a test fails

- Reproduce with the smallest numeric input, ideally via an explicit test target or a fixed seed.
- Decide whether the bug is in the mathematical rule, the generator, the session state transition, or the UI.
- Fix the canonical math or session implementation before working around it in the UI.
- Add a regression test reproducing the exact boundary or invalid state to `Tests/LogicChecks.swift` (shared) or the XCTest/XCUITest files (Apple-only behaviour).
- Rerun the entire test suite and verify the selected maximum still works at every level.
- Do not silence a failed assertion by weakening it without a written rationale.

## 13. How to work effectively on this repository

Recommended order for a coding agent implementing a change:

1. **Read:** `README.md`, this file, `MathLogic.swift`, `GameSessions.swift`, the applicable view, and `Tests/LogicChecks.swift`.
2. **State the behavior:** Define what the child should see and what constitutes a correct mathematical result.
3. **Preserve state:** Identify any existing `@AppStorage` keys and view transitions affected.
4. **Implement pure logic first:** Add rules to `MathLogic.swift` and transitions to `GameSessions.swift`.
5. **Add tests:** Include normal, minimum, and upper-bound cases in `LogicChecks.swift` before adjusting presentation; add an XCUITest when the change is visible on screen.
6. **Implement UI:** Reuse existing components and design tokens. Keep Norwegian child-facing copy in `GameCopy` or the view. Keep or extend accessibility identifiers.
7. **Verify:** Run local logic tests, source parse, project validation, the Xcode test bundles, and the packaging audit.
8. **Device check:** Build in Xcode and test on iPad whenever tooling is available.
9. **Document:** Update `README.md` and this file if any behavior, architecture, defaults, permission, or dependency changes.
10. **Report:** Clearly distinguish verified results, expected behavior, and tasks that still need device validation.

Prefer small, reviewable changes. Do not rewrite all views to introduce a single new difficulty level. Keep the generated ZIP reproducible from the project folder. Avoid premature architectural patterns or dependencies for features that do not exist yet.

## 14. Possible future improvements (not implemented)

Prioritize only after the present build passes on-device verification:

- **Adaptive progression:** Recommend the next activity based on consistent performance, without forced difficulty jumps or timed scoring.
- **Meaningful learning history:** Store optional per-activity correct attempts and concept practice locally, with clear parental reset controls (the global reset exists; per-activity history does not).
- **Optional child profiles:** Local-only, non-identifying profiles with carefully separated data and a migration plan.
- **Small-screen and accessibility sizes:** Layouts for the accessibility Dynamic Type sizes, more explicit VoiceOver hints, and switch-control tests.
- **Additional math:** Number-line hopping and comparisons, all within explicitly selected bounds. Subtraction with visual removal and grouping ten blocks into the next place are done in version 9 (`Ta bort og veksle` and the regrouping on Tusenøya).
- **Polished original artwork:** Done in version 6 (the garden scenery and the four guide creatures). Possible follow-ups: a parental "calm garden" switch (would need a new documented storage key; today Reduce Motion is the only off switch), seasonal variations of the flower field, and a performance pass with Instruments on the oldest supported iPads.
- **Language review:** Have a native Bokmål-speaking teacher or parent review every instruction and synthesized phrase.
- **Long bar shelves:** every cut adds a shelf slot and nothing caps them, so cutting most bars of a *Bygg med stolper* task into ones makes the shelf wider than the screen (28 ones on a task to 10 need about 1,860 pt) and the outermost bars are hard to reach. The task stays solvable with the bars on screen. A horizontally scrolling shelf (with `scrollClipDisabled` so a carried bar is not clipped) or a second shelf row would remove the limit; either needs the drop and cut-marker geometry rechecked.

Do not treat this roadmap as permission to collect child data, add advertisements, create accounts, or extend the upper bound of the free-play levels past 100 without tests and user approval (the map's place-value island shows numbers to 9999 by design).

### Next build, as requested by the project owner on 2026-11-05 (all items done by version 10)

The owner asked for the following in the next build. Record decisions here before implementing; the originality rules in section 2 apply to every item, so the characters, icons, palette and layouts must be designed from scratch and must not reproduce the distinctive characters or interface arrangements of any existing commercial math game, even when the mechanic is similar.

1. **Child-friendly original icons** for the four activities on the home screen. **Done in version 4:** `GameIcon` in `HomeView.swift` draws a dot-based motif per game.
2. **Spoken Norwegian instructions.** **Done in version 3:** each puzzle's prompt is spoken on start when speech is on, and every activity has a **Les opp oppgaven** button (the workshop has **Les opp regnestykket**).
2b. **Speech on by default, narrated glowing menus, bottom sound button, three-range chooser (20/40/100).** **Done in version 5.**
2d. **A more natural voice.** **Done in version 7:** the app prefers the highest-quality installed Norwegian voice (Premium or Enhanced "Nora" once downloaded in Settings); Siri's voices cannot be used by apps.
2e. **App Store readiness.** **Done in version 7:** store keys in the generated Info.plist, a verified unsigned Release archive, and the submission kit in `AppStore/` with `Tools/release.sh` (section 9). Signing, upload and the App Store Connect record remain the owner's steps.
2c. **A fun, fresh, iPadOS-native layout with figures and items that bring the garden to life.** **Done in version 6:** original garden scenery and four guide creatures (sections 2, 3, 4 and 7), symbol effects and scroll transitions, all gated for Reduce Motion, Reduce Transparency and Increase Contrast; the puzzles, copy, identifiers and storage keys are unchanged.
3. **Textless, landscape-first navigation.** **Done in version 8:** Talløyene (`IslandMap.swift`, `Challenges.swift`): a horizontally scrolling map of connected islands with numbered nodes, padlocks on locked nodes and 0–3 stars under completed ones; every node plays inside a minimal status strip with a central play area. Decision: landscape full-screen with a safe central area (the inset island row and the activity's content column), not a letterboxed 16:9 canvas, so Split View and portrait keep working. Progress lives in the new documented key `islandStars` with a reset control in Settings.
4. **Number bars 1–10 with original characters.** **Done in version 8:** `NumberBars.swift` draws bars of fixed width and proportional height on a unit grid, ten deep colours and ten faces, a white numeral whose opacity grows with the range; tap and drag scaling with a shadow, combine-on-drop with squash-and-stretch and a capsule ring, split by sideways swipe with a flash and recoil (plus tap-to-cut markers as the accessible alternative), rejection shake and spring-back, hit areas 20 % larger than the drawing, dashed outlines on the zone and the drop target while dragging, and tens rods for totals above ten. Mechanics are generic; characters, palette, icons and layout are original.
5. **Place value.** **Done in version 9:** `PlaceValue.swift` and the place-value rules: 11–99 as tens rods beside unit squares (hundreds as tiles, thousands as cubes), automatic regrouping of ten blocks into the next place with a carrying animation, tray bins per place, borrowing by breaking a block, its own level set (`PlaceValueLevel`, four ranges to 9999 on Tusenøya), seeded tests and the curriculum note in section 4.
6. **Equation balance activity.** **Done in version 10:** `Balance.swift` and the balance rules: a two-sided board with a central post, the hidden number as a closed bud (an original object that opens with its number as the unlock animation), warm positive and cool dashed inverse cards, mirrored ghost moves that keep both sides equal, opposite pairs cancelling to zero, a division rail under the board, three scaffold phases from pictures through pictures with numerals and signs to symbols, and a move count with 1–3 stars.

Suggested order: items 1–2 (small), then 3–4 as one playable release (version 8), then 5 (version 9), then 6 (version 10). Each phase keeps `./Tests/run.sh` green, adds XCTest/XCUITest coverage, keeps the app offline and Norwegian-spoken, and updates this document.


---

**Definition of done for the current delivery:** The package contains no references to unrelated educational game brands; the difficulty settings include **Til 40** and **Til 100** and the chooser offers 20, 40 and 100; all three puzzle generators can explicitly produce each level's maximum; the workshop can reach exactly the maximum but never one more; the map's first node is open on a fresh install, every other node locked until its predecessor has a star, and the Settings reset locks them again; the logic checks, the Xcode unit tests and the UI tests pass on an iPad simulator; `README.md`, `agent.md`, and `AGENTS.md` accurately describe the delivered features and verification limits; the final ZIP contains these files.
