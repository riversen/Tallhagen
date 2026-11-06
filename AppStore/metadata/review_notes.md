# Notes for App Review: Tallhagen 1.0

Tallhagen is an original, offline math game for children aged about 6 to 8, iPad only (iPadOS 17 or later). Interface and speech are Norwegian (Bokmål) by design; there is no English mode. No login or configuration is needed: open the app and play.

## How to try it in a minute

1. The first launch shows a chooser ("Hvor store tall?", how big should the numbers be?) with three cards, Til 20, Til 40 and Til 100, read aloud with a glow because speech is on by default; tap one.
2. The home screen ("Velg en lek", choose a game) lists a map card (Talløyene) and four game cards. Tap "Bygg tallet"; the task is read aloud. Tap or drag number pieces into the answer area until the total matches the target number; a check mark and "3 pluss 8 er 11. Bra jobbet!" (Well done!) appear. "Neste oppgave" gives another task, "Tilbake" goes home.
3. "Finn tallvennen": an addition is missing one number; tap one of the four answers.
4. "Del opp": move the slider or tap plus and minus until the left group shows the requested number, then tap "Sjekk svaret".
5. "Tallverkstedet": tap plus and minus under either number; "Les opp regnestykket" reads the sum aloud.
6. "Talløyene": a map of numbered tasks on six islands; tap the first open number. A task is four short puzzles (number bars 1 to 10 first; base-ten blocks to 9999 and an equation balance last) and ends with one to three stars, which unlock the next task (a padlock until then).
7. The speaker button at the bottom of every screen turns automatic speech off and on. "Innstillinger" (top of the home screen) has the level picker (Til 10 to Til 100), the speech toggle, two confirmed resets (solved tasks; map stars and locks) and the privacy policy address as plain text.

## Glossary (Norwegian to English)

| On screen | Meaning |
| --- | --- |
| Bygg tallet | Build the number |
| Finn tallvennen | Find the number friend (the missing addend) |
| Del opp | Split it up |
| Tallverkstedet | The number workshop (free play) |
| Talløyene | The number islands (a map of tasks with stars) |
| Tilbake / Neste oppgave / Start på nytt | Back / Next task / Start over |
| Få et hint / Sjekk svaret | Get a hint / Check the answer |
| Les opp oppgaven / regnestykket / valgene | Read the task / the sum / the choices aloud |
| Lyd på / Lyd av | Sound on / off |
| Riktig! / Bra jobbet! / Kjempebra! / Prøv igjen / Prøvd | Correct! / Well done! / Great! / Try again / Tried |
| Tilbake til kartet / Spill igjen | Back to the map / Play again |
| Nullstill antall løste oppgaver | Reset the number of solved tasks |
| Nullstill stjerner og låser på Talløyene | Reset the stars and locks on the map |

## Speech

All speech is Apple's on-device speech synthesis with the Norwegian voice installed on the iPad: no recordings, no network, never the microphone. A fresh device or simulator has only the compact voice; an enhanced one downloaded in Settings > Accessibility > Read & Speak > Voices > Norwegian is used automatically. With no Norwegian voice installed, the default voice reads the text.

## Privacy, data and the Kids category

Nothing is collected. The app stores four values locally in UserDefaults (level, speech on or off, solved-task count, map stars); deleting the app deletes them. The privacy manifest declares only the UserDefaults API (reason CA92.1), no tracking and no collected data types. The app requests no permissions, makes no network requests and contains no third-party code, advertising, purchases, subscriptions, accounts or links to websites; there is no parental gate because there is nothing to gate. The app has no encryption of its own, so the export compliance answer is No.

## Other facts

- Works in all four iPad orientations.
- Accessibility: VoiceOver labels and announcements in Norwegian, Dynamic Type up to the xxxLarge size.
- The garden, the creatures, the number bars, the blocks, the balance and the app icon are original drawings made in code.
