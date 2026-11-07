#!/usr/bin/env bash
# Tools/release.sh - archive, export and optionally upload Tallhagen for App Store Connect.
#
# Usage, from any directory:
#   ./Tools/release.sh            run the checks, archive, export a signed .ipa to a folder outside the project
#   ./Tools/release.sh --upload   run the checks, archive, upload the build straight to App Store Connect
#   ./Tools/release.sh --dry-run  run the checks and print the commands without running tests or xcodebuild
#   ./Tools/release.sh --help     print this help
#
# Environment variables (all optional):
#   TEAM_ID        Apple Developer team identifier (10 characters). Overrides DEVELOPMENT_TEAM from
#                  Tallhagen.xcodeproj/project.pbxproj for this run only and is never written into the
#                  project; the team chosen in Xcode is stored there on purpose.
#   BUILD_NUMBER   passed to xcodebuild as CURRENT_PROJECT_VERSION=<n> (whole number; every upload of
#                  the same version needs a higher one). Default: the value in the project (1).
#   VERSION        passed to xcodebuild as MARKETING_VERSION=<x>, for example 1.0.1. Default: the project (1.0).
#   EXPORT_DIR     folder for the export; default "$HOME/Desktop/Tallhagen-export-<timestamp>"
#                  (or "$HOME/Desktop/Tallhagen-upload-<timestamp>" with --upload, where only logs land).
#                  Must lie outside the project folder.
#   ASC_KEY_PATH, ASC_KEY_ID, ASC_ISSUER_ID
#                  App Store Connect API key: the .p8 file, its key id and the issuer id. When all three
#                  are set, xcodebuild authenticates with the key instead of the Apple ID signed in to Xcode.
#
# What the script does, in order:
#   1. refuses to run while the app's PRODUCT_BUNDLE_IDENTIFIER still starts with com.example
#   2. reads DEVELOPMENT_TEAM from the project file (or TEAM_ID) and refuses when none is set
#   3. checks the app icon (no alpha channel) and lints the privacy manifest and export options
#   4. refuses while PrivacyPolicy.address in Tallhagen/Theme.swift is empty or not an https address
#      (--dry-run only warns; AppStore/SUBMISSION-CHECKLIST.md step 2.7 says how to set it)
#   5. runs ./Tests/run.sh
#   6. archives the Release configuration for generic/platform=iOS into
#      "$HOME/Library/Developer/Xcode/Archives/Tallhagen-<timestamp>.xcarchive" (visible in Xcode's Organizer)
#   7. exports the archive with a temporary copy of AppStore/ExportOptions.plist in which
#      TEAM_ID_PLACEHOLDER is replaced by the real team id (destination "export", or "upload" with --upload)
#   8. prints the next manual steps
#
# The script writes nothing inside the project folder: the temporary export options live in a
# temporary directory, the archive in Xcode's archive folder and the export in EXPORT_DIR.
set -euo pipefail
# Apple's own tools first. Xcode's export runs rsync from PATH, and a newer rsync placed before
# /usr/bin (Homebrew's 3.x, for example) rejects Xcode's options: the export would then stop with
# "error: exportArchive Copy failed".
PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export PATH

mode="export"
dry_run="no"

print_help() {
  # Print the comment block at the top of this file, up to the first line that is not a comment.
  awk 'NR > 1 && !/^#/ { exit } NR > 1 { sub(/^# ?/, ""); print }' "${BASH_SOURCE[0]}"
}

for argument in "$@"; do
  case "$argument" in
    --upload) mode="upload" ;;
    --dry-run) dry_run="yes" ;;
    -h|--help) print_help; exit 0 ;;
    *)
      printf 'release.sh: unknown argument "%s"\n\n' "$argument" >&2
      print_help >&2
      exit 64
      ;;
  esac
done

say() { printf '\n==> %s\n' "$*"; }
note() { printf '    %s\n' "$*"; }
die() { printf '\nrelease.sh: %s\n' "$*" >&2; exit 1; }

# --- Locate the project -------------------------------------------------------------------------
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
project_root="$(cd "$script_dir/.." && pwd -P)"
cd "$project_root"

project_file="$project_root/Tallhagen.xcodeproj/project.pbxproj"
export_options_template="$project_root/AppStore/ExportOptions.plist"
privacy_manifest="$project_root/Tallhagen/PrivacyInfo.xcprivacy"
app_icon="$project_root/Tallhagen/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
tests_script="$project_root/Tests/run.sh"

[[ -f "$project_file" ]] || die "cannot find $project_file; run the script from the Tallhagen project."
[[ -f "$export_options_template" ]] || die "cannot find $export_options_template."
[[ -x "$tests_script" ]] || die "cannot find an executable $tests_script."

say "Tallhagen release ($mode mode$( [[ "$dry_run" == "yes" ]] && printf ', dry run' ))"
note "project: $project_root"

# --- Tooling ------------------------------------------------------------------------------------
command -v xcodebuild >/dev/null 2>&1 || die "xcodebuild is not available; install Xcode and run 'xcode-select --install'."
command -v plutil >/dev/null 2>&1 || die "plutil is not available; this script needs macOS."
note "$(xcodebuild -version | tr '\n' ' ')"

# --- (a) Bundle identifier of the app target ----------------------------------------------------
say "Checking the bundle identifier"
bundle_ids="$(grep -E '^[[:space:]]*PRODUCT_BUNDLE_IDENTIFIER = ' "$project_file" \
  | sed -E 's/^[[:space:]]*PRODUCT_BUNDLE_IDENTIFIER = "?([^";]+)"?;.*$/\1/' \
  | sort -u || true)"
app_bundle_id="$(printf '%s\n' "$bundle_ids" | grep -vE 'Tests$' || true)"
app_bundle_id_count="$(printf '%s\n' "$app_bundle_id" | sed '/^$/d' | wc -l | tr -d ' ')"
[[ "$app_bundle_id_count" == "1" ]] || die "expected exactly one app bundle identifier in the project file, found $app_bundle_id_count:
$bundle_ids"
case "$app_bundle_id" in
  com.example.*|com.example)
    die "the app target still uses the placeholder bundle identifier '$app_bundle_id'.
Set a bundle identifier of your own in Xcode (Tallhagen target > Signing & Capabilities) before releasing."
    ;;
esac
note "app bundle identifier: $app_bundle_id"
if printf '%s\n' "$bundle_ids" | grep -qE '^com\.example\..*Tests$'; then
  note "the test targets still use com.example identifiers; that is fine, tests are not part of the archive."
fi

# --- (b) Development team ------------------------------------------------------------------------
say "Checking the development team"
if [[ -n "${TEAM_ID:-}" ]]; then
  team_id="$TEAM_ID"
  team_source="TEAM_ID environment variable"
else
  team_ids="$(grep -E '^[[:space:]]*DEVELOPMENT_TEAM = ' "$project_file" \
    | sed -E 's/^[[:space:]]*DEVELOPMENT_TEAM = "?([^";]*)"?;.*$/\1/' \
    | sed '/^[[:space:]]*$/d' | sort -u || true)"
  team_count="$(printf '%s\n' "$team_ids" | sed '/^$/d' | wc -l | tr -d ' ')"
  if [[ "$team_count" == "0" ]]; then
    die "no DEVELOPMENT_TEAM is set in the project file.
Select your team in Xcode (Tallhagen target > Signing & Capabilities) or run: TEAM_ID=XXXXXXXXXX ./Tools/release.sh"
  elif [[ "$team_count" != "1" ]]; then
    die "the project file names more than one development team; pass the one to use as TEAM_ID:
$team_ids"
  fi
  team_id="$team_ids"
  team_source="DEVELOPMENT_TEAM in project.pbxproj"
fi
[[ "$team_id" =~ ^[A-Z0-9]{10}$ ]] || die "'$team_id' does not look like an Apple team identifier (10 letters or digits)."
note "team: $team_id (from $team_source)"
note "App Store uploads need the team of a paid Apple Developer Program membership, not a Personal Team."

# --- Optional overrides ---------------------------------------------------------------------------
say "Version and build number"
build_setting_overrides=()
if [[ -n "${BUILD_NUMBER:-}" ]]; then
  [[ "$BUILD_NUMBER" =~ ^[0-9]+$ ]] || die "BUILD_NUMBER must be a whole number, got '$BUILD_NUMBER'."
  build_setting_overrides+=("CURRENT_PROJECT_VERSION=$BUILD_NUMBER")
  note "build number: $BUILD_NUMBER (BUILD_NUMBER)"
else
  note "build number: as set in the project (CURRENT_PROJECT_VERSION); pass BUILD_NUMBER=<n> to override."
fi
if [[ -n "${VERSION:-}" ]]; then
  [[ "$VERSION" =~ ^[0-9]+(\.[0-9]+){0,2}$ ]] || die "VERSION must look like 1.0 or 1.0.1, got '$VERSION'."
  build_setting_overrides+=("MARKETING_VERSION=$VERSION")
  note "version: $VERSION (VERSION)"
else
  note "version: as set in the project (MARKETING_VERSION); pass VERSION=<x> to override."
fi
if [[ -n "${TEAM_ID:-}" ]]; then
  build_setting_overrides+=("DEVELOPMENT_TEAM=$team_id")
fi
note "App Store Connect accepts each build number only once per version; the export options leave the numbers unmanaged."

# --- App Store Connect authentication -------------------------------------------------------------
say "Authentication"
authentication_arguments=()
asc_set_count=0
for variable in ASC_KEY_PATH ASC_KEY_ID ASC_ISSUER_ID; do
  [[ -n "${!variable:-}" ]] && asc_set_count=$((asc_set_count + 1))
done
if [[ "$asc_set_count" == "3" ]]; then
  [[ -f "$ASC_KEY_PATH" ]] || die "ASC_KEY_PATH '$ASC_KEY_PATH' is not a file."
  authentication_arguments=(
    -authenticationKeyPath "$ASC_KEY_PATH"
    -authenticationKeyID "$ASC_KEY_ID"
    -authenticationKeyIssuerID "$ASC_ISSUER_ID"
  )
  note "App Store Connect API key $ASC_KEY_ID (issuer $ASC_ISSUER_ID) from $ASC_KEY_PATH"
elif [[ "$asc_set_count" == "0" ]]; then
  note "Apple ID signed in to Xcode (Xcode > Settings > Accounts). Set ASC_KEY_PATH, ASC_KEY_ID and ASC_ISSUER_ID to use an API key instead."
else
  die "set all three of ASC_KEY_PATH, ASC_KEY_ID and ASC_ISSUER_ID, or none of them."
fi

# --- Paths outside the project --------------------------------------------------------------------
timestamp="$(date +%Y%m%d-%H%M%S)"
archive_path="$HOME/Library/Developer/Xcode/Archives/Tallhagen-$timestamp.xcarchive"
if [[ "$mode" == "upload" ]]; then
  export_dir="${EXPORT_DIR:-$HOME/Desktop/Tallhagen-upload-$timestamp}"
else
  export_dir="${EXPORT_DIR:-$HOME/Desktop/Tallhagen-export-$timestamp}"
fi
case "$export_dir" in
  "$project_root"|"$project_root"/*) die "EXPORT_DIR '$export_dir' lies inside the project folder; choose a folder outside it." ;;
esac
[[ "$export_dir" == /* ]] || die "EXPORT_DIR must be an absolute path, got '$export_dir'."

# --- Static checks --------------------------------------------------------------------------------
say "Checking the app icon and the property lists"
if [[ -f "$app_icon" ]] && command -v sips >/dev/null 2>&1; then
  icon_alpha="$(sips -g hasAlpha "$app_icon" | awk '/hasAlpha/ { print $2 }')"
  icon_width="$(sips -g pixelWidth "$app_icon" | awk '/pixelWidth/ { print $2 }')"
  icon_height="$(sips -g pixelHeight "$app_icon" | awk '/pixelHeight/ { print $2 }')"
  [[ "$icon_alpha" == "no" ]] || die "the app icon has an alpha channel; App Store Connect rejects it. Regenerate it with Tools/MakeIcon.swift."
  [[ "$icon_width" == "1024" && "$icon_height" == "1024" ]] || die "the app icon is ${icon_width}x${icon_height}, expected 1024x1024."
  note "app icon: 1024x1024, no alpha channel"
else
  note "app icon not checked (file or sips missing)"
fi
plutil -lint "$privacy_manifest" >/dev/null || die "the privacy manifest does not lint."
note "privacy manifest lints: $privacy_manifest"
plutil -lint "$export_options_template" >/dev/null || die "AppStore/ExportOptions.plist does not lint."
grep -q 'TEAM_ID_PLACEHOLDER' "$export_options_template" \
  || die "AppStore/ExportOptions.plist no longer contains TEAM_ID_PLACEHOLDER; the project copy must never hold a real team id."
note "export options template lints and still holds the placeholder"
if grep -q 'INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO' "$project_file"; then
  note "export compliance: ITSAppUsesNonExemptEncryption = NO is generated into Info.plist"
else
  note "note: INFOPLIST_KEY_ITSAppUsesNonExemptEncryption is not set in the project; App Store Connect will ask the export compliance question for every build (answer: no encryption of its own)."
fi
# App Review Guideline 5.1.1(i): the privacy policy must be reachable inside the app. Settings shows
# PrivacyPolicy.address (Tallhagen/Theme.swift) as plain text once it is set.
privacy_address="$(sed -nE 's/^[[:space:]]*static let address = "([^"]*)".*$/\1/p' "$project_root/Tallhagen/Theme.swift" | head -n 1)"
if [[ "$privacy_address" =~ ^https://[^[:space:]]+$ ]]; then
  note "privacy policy address in the app: $privacy_address"
elif [[ "$dry_run" == "yes" ]]; then
  note "WARNING: PrivacyPolicy.address in Tallhagen/Theme.swift is empty or not an https address; a real run refuses to archive until it is set (host AppStore/privacy-policy/index.html first)."
else
  die "PrivacyPolicy.address in Tallhagen/Theme.swift is empty or not an https address.
Host AppStore/privacy-policy/index.html, put its https address into PrivacyPolicy.address and rebuild (App Review Guideline 5.1.1(i)); see AppStore/SUBMISSION-CHECKLIST.md step 2.7."
fi

# --- Temporary export options with the real team id -------------------------------------------
temporary_base="${TMPDIR:-/tmp}"
temporary_dir="$(mktemp -d "${temporary_base%/}/tallhagen-release.XXXXXX")"
trap 'rm -rf "$temporary_dir"' EXIT
export_options="$temporary_dir/ExportOptions.plist"
sed "s/TEAM_ID_PLACEHOLDER/$team_id/g" "$export_options_template" > "$export_options"
if [[ "$mode" == "upload" ]]; then
  plutil -replace destination -string upload "$export_options"
fi
plutil -lint "$export_options" >/dev/null || die "the temporary export options do not lint."
grep -q 'TEAM_ID_PLACEHOLDER' "$export_options" && die "the placeholder was not replaced in the temporary export options."
say "Export options (temporary copy, deleted when the script ends)"
plutil -p "$export_options" | sed 's/^/    /'

# --- Commands -------------------------------------------------------------------------------------
archive_command=(
  xcodebuild archive
  -project "$project_root/Tallhagen.xcodeproj"
  -scheme Tallhagen
  -configuration Release
  -destination "generic/platform=iOS"
  -archivePath "$archive_path"
  -allowProvisioningUpdates
)
if (( ${#authentication_arguments[@]} )); then archive_command+=("${authentication_arguments[@]}"); fi
if (( ${#build_setting_overrides[@]} )); then archive_command+=("${build_setting_overrides[@]}"); fi

export_command=(
  xcodebuild -exportArchive
  -archivePath "$archive_path"
  -exportOptionsPlist "$export_options"
  -exportPath "$export_dir"
  -allowProvisioningUpdates
)
if (( ${#authentication_arguments[@]} )); then export_command+=("${authentication_arguments[@]}"); fi

show_command() {
  printf '    '
  printf '%q ' "$@"
  printf '\n'
}

if [[ "$dry_run" == "yes" ]]; then
  say "Dry run: these commands would run next"
  note "tests:"
  show_command "$tests_script"
  note "archive:"
  show_command "${archive_command[@]}"
  note "$mode:"
  show_command "${export_command[@]}"
  note "archive would be written to: $archive_path"
  note "export folder would be: $export_dir"
  say "Dry run finished; nothing was built."
  exit 0
fi

# --- (c) Logic tests ------------------------------------------------------------------------------
say "Running the logic tests (./Tests/run.sh)"
"$tests_script"

# --- (d) Archive ----------------------------------------------------------------------------------
say "Archiving the Release configuration"
note "archive: $archive_path"
show_command "${archive_command[@]}"
"${archive_command[@]}"
[[ -d "$archive_path" ]] || die "the archive was not created at $archive_path."

# --- (e)/(f) Export or upload --------------------------------------------------------------------
if [[ "$mode" == "upload" ]]; then
  say "Uploading the archive to App Store Connect"
else
  say "Exporting a signed .ipa"
fi
mkdir -p "$export_dir"
note "export folder: $export_dir"
show_command "${export_command[@]}"
"${export_command[@]}"

# --- Summary and next manual steps ---------------------------------------------------------------
app_version="$(plutil -extract ApplicationProperties.CFBundleShortVersionString raw -o - "$archive_path/Info.plist" 2>/dev/null || printf 'unknown')"
app_build="$(plutil -extract ApplicationProperties.CFBundleVersion raw -o - "$archive_path/Info.plist" 2>/dev/null || printf 'unknown')"

say "Done: Tallhagen version $app_version, build $app_build"
note "archive: $archive_path (Xcode > Window > Organizer > Archives)"
if [[ "$mode" == "upload" ]]; then
  note "upload logs: $export_dir"
  printf '\nNext manual steps, in the order of AppStore/SUBMISSION-CHECKLIST.md steps 6 and 7:\n'
  printf '  1. Wait for the e-mail from App Store Connect that says the build has completed processing (about 10 to 60 minutes).\n'
  printf '  2. Open App Store Connect > Apps > Tallhagen. If the build shows "Missing Compliance", answer that the app uses no encryption of its own.\n'
  printf '  3. On the version page, under Build, choose the processed build (%s).\n' "$app_build"
  printf '  4. App Review Information: enter your contact details and paste AppStore/metadata/review_notes.md into Notes.\n'
  printf '  5. Version Release: choose manual or automatic release.\n'
  printf '  6. Press Save, then Add for Review, then Submit to App Review.\n'
  printf '  7. After approval follow AppStore/SUBMISSION-CHECKLIST.md step 8.\n'
else
  ipa_path="$(find "$export_dir" -maxdepth 1 -name '*.ipa' | head -n 1 || true)"
  if [[ -n "$ipa_path" ]]; then
    note "signed app: $ipa_path"
  else
    note "no .ipa was found in $export_dir; read $export_dir/Packaging.log (and DistributionSummary.plist) for the reason."
  fi
  printf '\nNext manual steps:\n'
  printf '  1. Upload the build: run ./Tools/release.sh --upload (archives again), or open Xcode > Window > Organizer,\n'
  printf '     select this archive and press Distribute App > App Store Connect > Upload, or drop the .ipa on the Transporter app.\n'
  printf '  2. Wait for the processing e-mail from App Store Connect, then follow AppStore/SUBMISSION-CHECKLIST.md from step 6.\n'
  printf '  3. Keep the archive; App Store Connect needs a higher BUILD_NUMBER for every further upload of version %s.\n' "$app_version"
fi
printf '\n'
