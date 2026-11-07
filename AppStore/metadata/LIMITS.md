# Character limits and actual counts

Every value below was measured by a script, not estimated. "Characters" is the number of Unicode characters (code points) in the file's text without its single final line break, which is what App Store Connect counts after a paste; the `wc -m` column is the raw count of the whole file, including that final line break. All files are plain UTF-8 with LF line endings. The three URL files hold the hosted support and privacy pages (GitHub Pages) and the marketing page; the script checks that each is a single https address and that the privacy address equals `PrivacyPolicy.address` in `Tallhagen/Theme.swift`. App Store Connect publishes no character limit for them, only that they must be valid URLs.

Re-measure after any edit with:

```sh
python3 -I count_metadata.py AppStore/metadata
```

where `count_metadata.py` is the small script reproduced at the end of this file. A one-line equivalent for a single file is `python3 -c 'import sys; print(len(open(sys.argv[1], encoding="utf-8").read().rstrip("\n")))' FILE`, and `LC_ALL=en_US.UTF-8 wc -m FILE` gives the raw count (without a UTF-8 locale, `wc -m` counts bytes, so every æ, ø or å would count twice).

| File | App Store Connect field | Limit | Characters (without final line break) | wc -m (with it) | Status |
| --- | --- | --- | ---: | ---: | --- |
| nb-NO/name.txt | Name | 30 | 9 | 10 | ok |
| nb-NO/subtitle.txt | Subtitle | 30 | 25 | 26 | ok |
| nb-NO/promotional_text.txt | Promotional text | 170 | 158 | 159 | ok |
| nb-NO/description.txt | Description | 4000 | 3549 | 3550 | ok |
| nb-NO/keywords.txt | Keywords (commas included) | 100 | 99 | 100 | ok |
| nb-NO/release_notes.txt | What's New in This Version | 4000 | 230 | 231 | ok |
| nb-NO/support_url.txt | Support URL | none published (must be a valid URL) | 49 | 50 | ok |
| nb-NO/marketing_url.txt | Marketing URL | none published (must be a valid URL) | 34 | 35 | ok |
| nb-NO/privacy_url.txt | Privacy Policy URL | none published (must be a valid URL) | 49 | 50 | ok |
| en-US/name.txt | Name | 30 | 9 | 10 | ok |
| en-US/subtitle.txt | Subtitle | 30 | 28 | 29 | ok |
| en-US/promotional_text.txt | Promotional text | 170 | 168 | 169 | ok |
| en-US/description.txt | Description | 4000 | 3990 | 3991 | ok |
| en-US/keywords.txt | Keywords (commas included) | 100 | 96 | 97 | ok |
| en-US/release_notes.txt | What's New in This Version | 4000 | 258 | 259 | ok |
| en-US/support_url.txt | Support URL | none published (must be a valid URL) | 49 | 50 | ok |
| en-US/marketing_url.txt | Marketing URL | none published (must be a valid URL) | 34 | 35 | ok |
| en-US/privacy_url.txt | Privacy Policy URL | none published (must be a valid URL) | 49 | 50 | ok |
| review_notes.md | App Review notes (pasted into App Store Connect) | 4000 | 3982 | 3983 | ok |

The keyword files were also checked for the two keyword rules: no spaces after commas, and no word that already appears in the name or subtitle of the same locale.

## Script used for the counts

```python
"""Measure every App Store metadata text file and print a Markdown table.

Usage: python3 -I count_metadata.py /path/to/AppStore/metadata [--write LIMITS.md]
Counts are Unicode code points of the file text without its single final line
break (what App Store Connect counts after a paste); the raw `wc -m` figure,
which includes that line break, is shown as well; wc runs with a UTF-8 locale so that
Norwegian letters count as one character each.
"""
import os
import re
import subprocess
import sys
import unicodedata

root = sys.argv[1]
write_path = sys.argv[3] if len(sys.argv) > 3 and sys.argv[2] == "--write" else None

LIMITS = [
    ("name.txt", "Name", 30),
    ("subtitle.txt", "Subtitle", 30),
    ("promotional_text.txt", "Promotional text", 170),
    ("description.txt", "Description", 4000),
    ("keywords.txt", "Keywords (commas included)", 100),
    ("release_notes.txt", "What's New in This Version", 4000),
    ("support_url.txt", "Support URL", None),
    ("marketing_url.txt", "Marketing URL", None),
    ("privacy_url.txt", "Privacy Policy URL", None),
]
EMOJI = re.compile("[\U0001F000-\U0001FAFF\u2600-\u27BF\u2B00-\u2BFF\uFE0F]")

problems = []
rows = []


def measure(path, field, limit):
    raw = open(path, "rb").read()
    try:
        text = raw.decode("utf-8", errors="strict")
    except UnicodeDecodeError as error:
        problems.append(f"{path}: not valid UTF-8 ({error})")
        return
    if "\r" in text:
        problems.append(f"{path}: contains CR (needs LF line endings)")
    if EMOJI.search(text):
        problems.append(f"{path}: contains an emoji-range character")
    body = text[:-1] if text.endswith("\n") else text
    count = len(body)
    wc = subprocess.run(["wc", "-m", path], capture_output=True, text=True, env=dict(os.environ, LC_ALL="en_US.UTF-8")).stdout.split()[0]
    if limit is not None and count > limit:
        problems.append(f"{path}: {count} characters exceeds the limit of {limit}")
    status = "ok" if limit is None or count <= limit else "OVER"
    rows.append((os.path.relpath(path, root), field, "none published (must be a valid URL)" if limit is None else str(limit), str(count), wc, status))
    return body


for locale in ("nb-NO", "en-US"):
    folder = os.path.join(root, locale)
    texts = {}
    for name, field, limit in LIMITS:
        texts[name] = measure(os.path.join(folder, name), field, limit)
    # Keyword rules: no spaces, no word already in the name or subtitle.
    keywords = texts["keywords.txt"]
    if " " in keywords:
        problems.append(f"{locale}/keywords.txt: contains a space")
    used = set()
    for source in ("name.txt", "subtitle.txt"):
        used |= {w.lower() for w in re.findall(r"[^\W\d_]+", texts[source])}
    for word in keywords.split(","):
        if word.lower() in used:
            problems.append(f"{locale}/keywords.txt: '{word}' already appears in the name or subtitle")
    for name in ("support_url.txt", "marketing_url.txt", "privacy_url.txt"):
        value = texts[name] or ""
        if not re.fullmatch(r"https://\S+", value) or "REPLACE-WITH" in value:
            problems.append(f"{locale}/{name}: not a single real https address")
    # The privacy address of the listing must be the one the app shows in Settings.
    theme = os.path.join(root, "..", "..", "Tallhagen", "Theme.swift")
    if not os.path.exists(theme):
        problems.append(f"{locale}/privacy_url.txt: not compared with PrivacyPolicy.address, {os.path.normpath(theme)} not found (run the script on the project's AppStore/metadata)")
    else:
        shown = re.search(r'static let address = "([^"]*)"', open(theme, encoding="utf-8").read())
        if not shown or shown.group(1) != texts["privacy_url.txt"]:
            problems.append(f"{locale}/privacy_url.txt: differs from PrivacyPolicy.address in Tallhagen/Theme.swift")
    if texts["name.txt"] != "Tallhagen":
        problems.append(f"{locale}/name.txt: not 'Tallhagen'")

measure(os.path.join(root, "review_notes.md"), "App Review notes (pasted into App Store Connect)", 4000)

header = "| File | App Store Connect field | Limit | Characters (without final line break) | wc -m (with it) | Status |\n| --- | --- | --- | ---: | ---: | --- |\n"
table = header + "\n".join("| " + " | ".join(r) + " |" for r in rows) + "\n"
print(table)
if problems:
    print("PROBLEMS:")
    for p in problems:
        print(" -", p)
else:
    print("No problems found.")

if write_path:
    with open(write_path, "w", encoding="utf-8", newline="\n") as out:
        out.write("# Character limits and actual counts\n\n")
        out.write("Every value below was measured by a script, not estimated. ")
        out.write("\"Characters\" is the number of Unicode characters (code points) in the file's text without its single final line break, which is what App Store Connect counts after a paste; ")
        out.write("the `wc -m` column is the raw count of the whole file, including that final line break. ")
        out.write("All files are plain UTF-8 with LF line endings. The three URL files hold the hosted support and privacy pages (GitHub Pages) and the marketing page; the script checks that each is a single https address and that the privacy address equals `PrivacyPolicy.address` in `Tallhagen/Theme.swift`. App Store Connect publishes no character limit for them, only that they must be valid URLs.\n\n")
        out.write("Re-measure after any edit with:\n\n```sh\npython3 -I count_metadata.py AppStore/metadata\n```\n\n")
        out.write("where `count_metadata.py` is the small script reproduced at the end of this file. A one-line equivalent for a single file is `python3 -c 'import sys; print(len(open(sys.argv[1], encoding=\"utf-8\").read().rstrip(\"\\n\")))' FILE`, and `LC_ALL=en_US.UTF-8 wc -m FILE` gives the raw count (without a UTF-8 locale, `wc -m` counts bytes, so every æ, ø or å would count twice).\n\n")
        out.write(table)
        out.write("\nThe keyword files were also checked for the two keyword rules: no spaces after commas, and no word that already appears in the name or subtitle of the same locale.\n")
        out.write("\n## Script used for the counts\n\n```python\n")
        out.write(open(sys.argv[0], encoding="utf-8").read())
        out.write("```\n")
    print(f"Wrote {write_path}")
```
