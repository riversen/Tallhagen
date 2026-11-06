# Export compliance answer for Tallhagen

## The short version

- Tallhagen uses **no encryption at all**: it has no cryptographic code of its own, links no third-party libraries, makes no network connections (so there is no HTTPS or TLS either) and stores nothing encrypted.
- The accurate answer to Apple's export compliance question is therefore **No**: the app does not use non-exempt encryption.
- The Info.plist key **`ITSAppUsesNonExemptEncryption` = NO** in the build makes App Store Connect skip the question for every upload. Because this project generates its Info.plist from build settings (`GENERATE_INFOPLIST_FILE = YES`), the key is the build setting **`INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO`** on the Tallhagen target.
- No export compliance documentation, no `ITSEncryptionExportComplianceCode` and no French encryption declaration are needed.

## Why "No" is accurate

Apple's rule for the key: set it to NO if the app, including any third-party libraries it links against, either uses no encryption or only uses encryption that is exempt from export documentation requirements (for example HTTPS connections made through the operating system). Set it to YES only when the app uses non-exempt encryption, such as proprietary or non-standard cryptography.

Tallhagen is the simplest case, no encryption of any kind:

| Check | Finding in the source (`Tallhagen/*.swift`) |
| --- | --- |
| Cryptographic frameworks | None. No CryptoKit, CommonCrypto, Security framework or Keychain use. |
| Network | None. No URL loading, sockets, web views or URLs; the app never connects to anything, so it never negotiates TLS. |
| Third-party libraries | None. No Swift packages, no package managers, no vendored code. The only imports are SwiftUI, Foundation, UIKit and AVFoundation. |
| Stored data | Four plain values in UserDefaults. The app never writes files and applies no encryption of its own. (iPadOS encrypts the device's storage by itself; that is operating-system protection, not encryption the app uses, and it does not change the answer.) |
| Speech | Apple's on-device speech synthesis. No audio leaves the device; nothing is encrypted or decrypted. |

So nothing in the app uses, accesses, contains, implements or incorporates encryption in the sense of Apple's export compliance overview.

## What the key does at upload

- When a build is uploaded without the key, App Store Connect shows an export compliance questionnaire for that build (for TestFlight and for the App Store) before the build can be used. Its first question asks whether the app uses encryption; the wording varies a little between versions of App Store Connect. The answer for Tallhagen is **No**. After a "No", no documents are requested.
- When the key is present with the value NO, the questionnaire is skipped and the build becomes available as soon as processing finishes. This is what the project should rely on, so nobody has to remember the answer for every build.

## How to set it in this project

The Tallhagen target has no Info.plist file; its Info.plist is generated from `INFOPLIST_KEY_*` build settings. Xcode 26.5 supports this key as such a setting (`INFOPLIST_KEY_ITSAppUsesNonExemptEncryption`), so:

- In Xcode: select the project, then the **Tallhagen** target, then **Build Settings**, search for "non-exempt" and set **App Uses Non-Exempt Encryption** to **No** for all configurations.
- In `Tallhagen.xcodeproj/project.pbxproj` the result is one line in each of the Tallhagen target's Debug and Release build configurations, next to the other `INFOPLIST_KEY_*` lines:

```
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO;
```

- Alternative: in the target's **Info** tab, add the row "App Uses Non-Exempt Encryption" with the value NO; Xcode writes the key for you.

Only the app target needs it; the test targets are not uploaded.

Status: the key is set in both configurations of the Tallhagen target; `grep -c 'INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO' Tallhagen.xcodeproj/project.pbxproj` prints 2, and `Tools/release.sh` confirms it before archiving. Nothing has to be answered per build.

## How to verify before uploading

After archiving (Product, then Archive), check the Info.plist inside the archive:

```
plutil -p "$HOME/Library/Developer/Xcode/Archives/<date>/<archive name>.xcarchive/Products/Applications/Tallhagen.app/Info.plist" | grep ITSAppUsesNonExemptEncryption
```

Expected output:

```
"ITSAppUsesNonExemptEncryption" => 0
```

Or, from the project without archiving:

```
xcodebuild -project Tallhagen.xcodeproj -target Tallhagen -showBuildSettings 2>/dev/null | grep INFOPLIST_KEY_ITSAppUsesNonExemptEncryption
```

Expected: `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO`.

## Related points

- `ITSEncryptionExportComplianceCode`: not needed. Apple issues that code only after reviewing documentation for apps that use non-exempt encryption.
- Annual self-classification report to the United States Bureau of Industry and Security: Apple notes that it may be required for apps that use exempt forms of encryption. Tallhagen uses no encryption, so there is nothing to classify. The declaration remains the owner's responsibility; the statements above describe what the app contains and are not legal advice.
- France: Apple's overview notes that France controls encryption apps in the categories secure storage, secure communications and security or anti-virus. Tallhagen is none of these and uses no encryption, so no French declaration applies.
- If a future version ever adds networking through the operating system (for example HTTPS through URLSession), the answer stays No, because operating-system encryption is exempt; the privacy policy and the App Privacy answers would have to be revisited first, though. Adding any proprietary encryption would change the answer to Yes.
