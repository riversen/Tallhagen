# Age rating questionnaire answers for Tallhagen

Where: App Store Connect, then Apps, then Tallhagen, then **App Information** (sidebar, under General), then **Age Ratings**, then **Set Up Age Ratings** (later: Edit at the top of the page). The age rating is required app information; without it the app cannot be published. Apple calculates the rating from the answers; you do not pick the rating directly.

Everything in Tallhagen is number puzzles, countable dots, a drawn garden and four friendly garden animals (a snail, a butterfly, a bumblebee and a hedgehog). Nothing in the questionnaire applies, so every answer is the lowest one.

## Step 1: In-app controls and capabilities

The first dialog lists in-app controls and capabilities and asks you to tick the ones the app includes. Tick **none** of them.

| Item | Answer | Why |
| --- | --- | --- |
| Parental Controls | No | The Settings screen chooses the number range, turns speech on or off and resets the solved-task count and the stars on the island map. These are ordinary settings; they do not restrict content or features, so they are not parental controls in Apple's sense. |
| Age Assurance | No | The app never asks for or checks anyone's age. |
| Unrestricted Web Access | No | No browser, no web view, no links. |
| User-Generated Content | No | Nothing a user creates is shared with anyone. |
| Social Media, and Social Media Disabled for Users Under 13 | No (not applicable) | No feeds, no sharing, no communication. |
| Messaging and Chat | No | No communication features. |
| Advertising | No | No advertising of any kind. |

## Step 2: Content descriptions

Go through each section of the progress bar and choose the lowest option, **None**, for every content description. Gambling and Loot Boxes are yes/no questions: answer **No**.

| Section | Content description | Answer |
| --- | --- | --- |
| Mature Themes | Profanity or Crude Humor | None |
| Mature Themes | Horror/Fear Themes | None |
| Mature Themes | Alcohol, Tobacco, or Drug Use or References | None |
| Medical or Wellness | Medical or Treatment Information | None |
| Medical or Wellness | Health or Wellness Topics | None |
| Sexuality or Nudity | Mature or Suggestive Themes | None |
| Sexuality or Nudity | Sexual Content or Nudity | None |
| Sexuality or Nudity | Graphic Sexual Content and Nudity | None |
| Violence | Cartoon or Fantasy Violence | None |
| Violence | Realistic Violence | None |
| Violence | Prolonged Graphic or Sadistic Realistic Violence | None |
| Violence | Guns or Other Weapons | None |
| Chance-Based Activities | Gambling | No |
| Chance-Based Activities | Simulated Gambling | None |
| Chance-Based Activities | Contests | None |
| Chance-Based Activities | Loot Boxes | No |

Notes for anyone who hesitates on a line:

- Contests: the app has no rankings, leaderboards, prizes or competition between users. The count of solved tasks, the flower bed and the stars on the island map (Talløyene) are private encouragement on one iPad and are never compared with anyone. "None" is correct.
- Violence: the guide creatures only idle, and hop or flap once when a puzzle is solved. Nothing is harmed, and nothing reacts to a wrong answer.
- Medical or wellness: there is no health content; the app teaches numbers.
- If the form shows a question that is not listed here, the answer for Tallhagen is still None or No, for the same reason: the app contains only number puzzles and a garden.

## Step 3: Age categories and override

- Under Age Categories and Override choose **Made for Kids** with the age range **6–8**. The kit's texts require it: the subtitle, promotional text, description and keywords present children as the main audience, which App Review Guideline 5.1.4 allows only for apps in the Kids category. Choosing "Not Applicable" would mean rewriting every listing text without children as the audience (the replacements are listed at the end of this file). The next section says what the Kids category binds the app to.
- Override to Higher Age Rating: not needed. The app has no licence agreement with a minimum age.
- Age Suitability URL: leave empty.
- Republic of Korea (Add RCN): not needed unless the app is distributed in Korea with a separate rating.

Click Save. The dialog closes and returns to the App Information page, which now shows the calculated rating.

## Expected result

**4+**, the lowest tier (regional equivalents shown by App Store Connect are likewise the lowest tier). If the calculated rating is anything else, an answer was mis-selected: go back through the sections and check each line against the tables above.

## Why the kit chooses the Kids category (Made for Kids, ages 6–8)

The listing texts say who the app is for ("Tallforståelse for 6–8 år", "for barn på rundt 6–8 år", keywords such as barn and førskole). Guideline 5.1.4 states that apps not in the Kids Category cannot include any terms in the app name, subtitle, icon, screenshots or description that imply the main audience for the app is children, and guideline 2.3.8 reserves such wording for the Kids category. The kit therefore assumes Made for Kids; the selection is made in the age rating dialog (Step 3 above). What follows is what that choice requires and changes, and the replacement texts if the owner nevertheless refuses it.

### What opting in requires (App Review Guidelines 1.3 and 5.1.4)

- No links out of the app, no purchase opportunities and no other distractions for children, unless they sit in a designated area behind a parental gate (an adult-level task).
- No third-party analytics and no third-party advertising (Apple allows narrow, strictly controlled exceptions; they do not matter here).
- No personally identifiable information or device information sent to third parties.
- A privacy policy, and compliance with children's privacy law.
- A calculated age rating of 4+ or 9+.

Tallhagen already meets all of these: it has no links, no purchases, no third-party code at all, no network use, the privacy policy is hosted at https://riversen.github.io/Tallhagen/privacy.html, and the rating will be 4+. No parental gate is needed, because there is nothing to gate.

### What opting in changes

- App Review checks the Kids requirements specifically and may ask questions about them, so the first review can take a little longer and is stricter.
- The Made for Kids selection cannot be changed once the app has been approved by App Review (App Store Connect help states this).
- Guideline 1.3 adds that once customers expect an app to follow the Kids requirements, it must keep meeting them in later updates, even if the category is deselected later.
- In practice the app may not later add outbound links (not even a link to the privacy policy or a page for parents), in-app purchases, advertising or analytics, unless they sit behind a parental gate and still satisfy the rules. Leaving the category is not something to plan on.

### What not opting in changes

- Guideline 2.3.8 reserves wording such as "for kids" or "for children" in app metadata for the Kids category. An app outside the category may not use a name, subtitle, icon, screenshots or description that imply children are its main audience. The App Store text would then have to describe what the app does (numbers shown as countable dots, bars and blocks, four activities and an island map, everything read aloud in Norwegian) without presenting it as made for children.
- The app is listed only in its ordinary categories (for example Education) and does not appear in the Kids section of the App Store.

### What the choice means for the owner

The constraints above hold for the lifetime of the app: no external links, purchases, advertising or analytics in any future version (or only behind a parental gate), and a Made for Kids selection that cannot be undone. The project's own rules (`agent.md` sections 2 and 9) already forbid accounts, advertising, analytics, payments and external links in the game, so today those constraints cost nothing, and the Kids category lets the store page say plainly who the app is for. The statement for App Review (fully offline, no third-party code, no links, no parental gate because there is nothing to gate) is already part of `review_notes.md`, under "Privacy, data and the Kids category".

### If the owner refuses the Kids category: texts to replace before pasting

Choose "Not Applicable" in Step 3 only together with all of these replacements, so that no listing text presents children as the main audience (guidelines 2.3.8 and 5.1.4):

- `nb-NO/subtitle.txt`: `Tell, bygg og del opp tall`
- `en-US/subtitle.txt`: `Math with dots, in Norwegian`
- `nb-NO/keywords.txt`: remove `barn` and `førskole`; `en-US/keywords.txt`: remove `kids`, `children` and `preschool`
- first two sentences of `nb-NO/description.txt`: `Tallhagen er et rolig mattespill der tallene vises som prikker, stolper og brikker man kan telle, så et tall blir en mengde man kan se, ikke bare et tegn på skjermen.`
- first two sentences of `en-US/description.txt`: `Tallhagen (Norwegian for "the number garden") is a calm math game in which numbers are shown as dots, bars and blocks you can count, so a number becomes a quantity you can see, not just a symbol on the screen.`
- `nb-NO/promotional_text.txt` and `en-US/promotional_text.txt`: drop "for ages 6 to 8" and any mention of children
- reword the remaining sentences that say "barnet" / "the child" (for example "Barnet bygger et måltall" becomes "Man bygger et måltall"), and the first sentence of `review_notes.md`

Then re-measure the files (`LIMITS.md`) before pasting. The privacy policy may keep its wording; it is not store metadata.
