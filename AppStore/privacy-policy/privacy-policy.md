# Tallhagen privacy policy (Markdown copy)

This file holds the same text as `index.html` in this folder, in Markdown, for anyone who wants to host the policy on a site that renders Markdown or paste it into another page. **The file to host as it is, is `index.html`**: a single self-contained page with no scripts, fonts, images or other dependencies, readable on a phone and on an iPad.

## Where it is hosted

Since 2026-11-06 the policy is online at https://riversen.github.io/Tallhagen/privacy.html, served by GitHub Pages from `docs/privacy.html` in the public repository `github.com/riversen/Tallhagen` (set up like EriksDay's pages). That copy has the effective date 6 November 2026 and the contact address filled in; the same folder holds `support.html`, the Support URL, and a short start page. To change the policy, edit `docs/privacy.html` there, update the effective date in both languages, and make the same text change in `index.html` and in this file (both keep their placeholders). The address is already in `PrivacyPolicy.address` and in `AppStore/metadata/*/privacy_url.txt`.

## Before you host it elsewhere

1. Replace the four placeholders in the copy you publish: `[dato]` and `[date]` with the effective date (for example `5. november 2026` / `5 November 2026`), and `[legg inn e-postadresse]` / `[insert email address]` with an email address that will actually be read. The two copies in this folder (`index.html` and this file) keep the placeholders on purpose, so that no email address is stored in the project files.
2. Keep the Norwegian and the English text together on one page. In `index.html` the Norwegian section has the anchor `#norsk` and the English section `#english`.
3. Do not add analytics, cookie banners, fonts or other external resources to the page. The policy says the app collects nothing; the page should not collect anything either.
4. Once the page is online, show its address inside the app as well (App Review Guideline 5.1.1(i) requires the privacy policy to be accessible within the app, not only on the store page): `SUBMISSION-CHECKLIST.md` step 2.7 says where: `PrivacyPolicy.address` in `Tallhagen/Theme.swift`, which Settings shows in a "Personvern" section as plain text, not a link, because a Kids-category app may not link out without a parental gate. Set it before archiving the build you submit.

## Hosting it for free

Any static web host works. The page must be reachable over `https://`, public (no login), and it must stay at the same address for as long as the app is on the App Store, because the policy promises that changes are published at that address.

Example with any static-site host (a personal web server or a static-site service): create a public site, upload `index.html` (placeholders filled in) at its root, open the resulting `https://` address on an iPad and on a phone to check that it reads well (`#norsk` and `#english` at the end of the address jump to each language), and keep that address unchanged for as long as the app is in the store. To change the policy later, replace the file at the same address and update the date.

## Where the final URL goes

- App Store Connect, then Apps, then Tallhagen, then **App Privacy** in the sidebar, then **Privacy Policy**, then Edit, then **Privacy Policy URL**. The field exists for each localisation of the store page; use the same address for every localisation, exactly as in `PrivacyPolicy.address` (https://riversen.github.io/Tallhagen/privacy.html, without `#norsk` or `#english`). Leave "User Privacy Choices URL" empty. Changes to this field are released together with the next app version.
- `AppStore/metadata/*/privacy_url.txt`: both locale folders already hold this address. Keep each file identical to the Privacy Policy URL of its localisation in App Store Connect and to `PrivacyPolicy.address` (`SUBMISSION-CHECKLIST.md` step 4.6); the script in `AppStore/metadata/LIMITS.md` compares both files with `PrivacyPolicy.address`.

## The policy inside the app

App Review Guideline 5.1.1(i) requires a link to the privacy policy both in the App Store Connect metadata field and within the app in an easily accessible manner. Tallhagen contains no links on purpose, and an app in the Kids category may not link out of the app without a parental gate, so the kit's answer is to show the hosted address as plain text in a "Personvern" section of the Settings screen. Settings has no parental gate, so the address is neither a link nor selectable (selectable text would offer Share on a long press). Since project version 11 the section shows https://riversen.github.io/Tallhagen/privacy.html, the address held by `PrivacyPolicy.address` in `Tallhagen/Theme.swift` (`SUBMISSION-CHECKLIST.md` step 2.7). Every build shows the address it was built with, so keep the page at that address, as the policy itself promises. If the address ever has to change, host the page at its new address first, then change `PrivacyPolicy.address`, `AppStore/metadata/*/privacy_url.txt` and the App Store Connect field together, rebuild, run the tests and upload a new build (`SUBMISSION-CHECKLIST.md` step 4.6). `Tools/release.sh` refuses to archive unless the address is an https address. `metadata/review_notes.md` tells App Review where to find the address.

---

# Personvernerklæring for Tallhagen

Gjelder fra: [dato]

Tallhagen er et matematikkspill for iPad, laget for barn på rundt 6–8 år. Denne erklæringen forteller hva appen gjør med opplysninger. Svaret er kort: nesten ingenting.

**Kort fortalt**

- Appen virker helt uten internett og kobler seg aldri til nettet.
- Appen samler ikke inn personopplysninger om noen, verken barn eller voksne.
- Appen bruker ingen analyseverktøy, ingen reklame og ingen sporing.
- To innstillinger og fremgangen i spillet lagres på iPaden. Appen sender dem aldri noe sted, og de slettes fra iPaden når appen slettes.

## Hvem appen er for

Tallhagen er laget for barn som holder på å lære hva tall betyr, vanligvis i alderen 6 til 8 år. Voksne kan velge tallområde, slå lyden av og på og nullstille tellingen av løste oppgaver og stjernene på Talløyene i innstillingene.

## Appen virker helt uten nett

Tallhagen trenger ikke internett og tar aldri kontakt med noen server. Alt som skjer i appen, skjer på iPaden. Appen sender ingenting ut og henter ingenting inn.

## Ingen personopplysninger samles inn

Appen samler ikke inn navn, e-postadresser, fødselsdatoer, bilder, posisjon, kontakter, enhets-ID-er eller andre opplysninger som kan knyttes til en person. Den inneholder ingen analyseverktøy, ingen reklame og ingen sporing av noe slag. Den ber heller ikke om tilgang til mikrofon, kamera, posisjon eller kontakter.

## Dette lagres på iPaden

For å huske hvordan appen sist ble brukt, lagrer den fire verdier lokalt på iPaden, i Apples vanlige lager for app-innstillinger (UserDefaults):

1. **Valgt tallområde**, for eksempel «Til 20», slik at barnet fortsetter med de samme tallene neste gang.
2. **Om lyden er på eller av**, slik at valget blir husket.
3. **Antall løste oppgaver**, slik at blomsterbedet på forsiden kan vise hvor mange oppgaver som er løst. Tallet kan nullstilles når som helst i innstillingene.
4. **Stjerner på Talløyene**, slik at kartet husker hvilke oppgaver som er løst og hvor mange stjerner hver av dem fikk. Også dette kan nullstilles i innstillingene.

Verdiene inneholder ingen personopplysninger, og appen sender dem aldri ut av iPaden. Hvis iPaden sikkerhetskopieres til iCloud eller en datamaskin, er verdiene med i sikkerhetskopien, på samme måte som data fra andre apper. Vil du slette dem fra iPaden, sletter du appen. Det finnes ingenting å be om å få slettet hos noen andre, fordi appen ikke sender noe ut av iPaden.

## Opplesing

Oppgaver og tilbakemeldinger kan leses opp på norsk. Stemmen lages av Apples innebygde talesyntese på selve iPaden. Appen tar ikke opp lyd, lytter ikke og bruker ikke mikrofonen. Ingen lyd eller tekst sendes noe sted.

## Ingen kontoer, kjøp eller lenker

Appen har ingen brukerkontoer, ingen innlogging, ingen kjøp i appen, ingen abonnementer og ingen lenker til nettsider eller andre apper. Et barn kan ikke havne noe annet sted fra appen.

## Ingen deling med andre

Siden appen ikke samler inn opplysninger, har den heller ingenting å dele. Ingen opplysninger gis videre til tredjeparter, og appen inneholder ingen kode fra tredjeparter.

## Barns personvern

Tallhagen er laget for barn, og den enkleste måten å verne om barns personvern på er å ikke samle inn noe. Det er nettopp det appen gjør: Den samler ikke inn opplysninger fra noen, og derfor heller ikke fra barn. Fordi ingenting samles inn, trengs det ikke samtykke fra foreldre eller foresatte for at et barn skal kunne bruke appen.

## Endringer

Hvis denne erklæringen endres, publiseres den nye versjonen på samme adresse som denne, med ny dato øverst.

## Kontakt

Kontakt: [legg inn e-postadresse]

---

# Privacy Policy for Tallhagen

Effective date: [date]

Tallhagen is a math game for iPad, made for children around 6 to 8 years old. This policy explains what the app does with information. The short answer is: almost nothing.

**In short**

- The app works fully offline and never connects to the internet.
- The app collects no personal data from anyone, neither children nor adults.
- The app uses no analytics, no advertising and no tracking.
- Two settings and the game progress are stored on the iPad. The app never sends them anywhere, and they are deleted from the iPad when the app is deleted.

## Who the app is for

Tallhagen is made for children who are learning what numbers mean, typically between 6 and 8 years old. Adults can choose the number range, turn sound on or off and reset the count of solved tasks and the stars on the island map in Settings.

## The app works fully offline

Tallhagen does not need an internet connection and never contacts any server. Everything that happens in the app happens on the iPad. The app sends nothing out and fetches nothing in.

## No personal data is collected

The app does not collect names, email addresses, dates of birth, photos, location, contacts, device identifiers or any other information that could be linked to a person. It contains no analytics tools, no advertising and no tracking of any kind. It does not ask for access to the microphone, camera, location or contacts.

## What is stored on the iPad

To remember how it was last used, the app stores four values locally on the iPad, in Apple's standard store for app settings (UserDefaults):

1. **The chosen number range**, for example "Til 20", so the child continues with the same numbers next time.
2. **Whether sound is on or off**, so the choice is remembered.
3. **The number of solved tasks**, so the flower bed on the home screen can show how many tasks have been solved. The count can be reset at any time in Settings.
4. **Stars on the island map (Talløyene)**, so the map remembers which tasks are done and how many stars each of them earned. This too can be reset in Settings.

These values contain no personal information, and the app never sends them off the iPad. If the iPad is backed up to iCloud or a computer, the values are part of that backup, like the data of other apps. To delete them from the iPad, delete the app. There is nothing to ask anyone else to delete, because the app sends nothing off the iPad.

## Speech

Tasks and feedback can be read aloud in Norwegian. The voice is produced by Apple's built-in speech synthesis on the iPad itself. The app does not record audio, does not listen and does not use the microphone. No audio or text is sent anywhere.

## No accounts, purchases or links

The app has no user accounts, no sign-in, no in-app purchases, no subscriptions and no links to websites or other apps. A child cannot end up anywhere else from inside the app.

## No sharing with third parties

Because the app collects no information, it has nothing to share. No information is passed on to third parties, and the app contains no third-party code.

## Children's privacy

Tallhagen is made for children, and the simplest way to protect children's privacy is to collect nothing. That is exactly what the app does: it collects no information from anyone, and therefore none from children. Because nothing is collected, no parental consent is needed for a child to use the app.

## Changes

If this policy changes, the new version is published at this same address, with a new effective date at the top.

## Contact

Contact: [insert email address]
