# Agent instructions for Tallhagen

**Before editing this repository, read the full [`agent.md`](agent.md).** It contains the definitive project specification, component map, Norwegian educational-copy rules, original-content restrictions, privacy requirements, mathematical invariants, and device acceptance tests.

Minimum requirements for every change:

1. Preserve Norwegian Bokmål as the child-facing language.
2. Maintain the five difficulty levels with maximum totals 10, 20, 30, **40** and **100** (stored identifiers 1–5); the first-launch chooser offers 20, 40 and 100.
3. Keep the application original and offline, with no advertisements, third-party branding, or user accounts.
4. Make number-rule changes in `Tallhagen/MathLogic.swift` and state-transition changes in `Tallhagen/GameSessions.swift`. Both are Foundation-only; add coverage in `Tests/LogicChecks.swift`, which both `./Tests/run.sh` and the Xcode unit tests execute.
5. Run `./Tests/run.sh` and `swiftc -frontend -parse Tallhagen/*.swift` before packaging. On a Mac, also run `xcodebuild -project Tallhagen.xcodeproj -scheme Tallhagen -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4),OS=18.2' test`.
6. Keep the `@AppStorage` keys `learningLevel`, `speakNorwegian` and `solvedTotal` unchanged.
7. Keep the accessibility identifiers used by `TallhagenUITests` (for example `game.next`, `build.piece.<n>`, `workshop.first.increase`) when changing views, or update the UI tests with them.
8. Do not claim an iPad/Xcode build or test passed unless it was actually performed.
