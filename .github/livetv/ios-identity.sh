#!/usr/bin/env bash
# Gives the iOS app its own identity: "Nuvio Live TV", bundle ID com.wgdively.nuvio.livetv.
# Runs AFTER the Live TV patch is applied, from the root of the Nuvio Mobile checkout.
# Kept out of the patch on purpose, so upstream updates can't break it.
# Usage: ios-identity.sh [apple-team-id] [build-number]
set -euo pipefail

team="${1:-}"
build="${2:-}"
proj=iosApp/iosApp.xcodeproj/project.pbxproj
plist=iosApp/iosApp/Info.plist
version=iosApp/Configuration/Version.xcconfig
id=com.wgdively.nuvio.livetv

# Widget first (its ID starts with the app's), then the app itself.
perl -pi -e "s/com\\.nuvio\\.(media|app)\\.DownloadsWidgetExtension/${id}.DownloadsWidgetExtension/g" "$proj"
perl -pi -e "s/(PRODUCT_BUNDLE_IDENTIFIER = \"?)com\\.nuvio\\.(media|app)(\"?;)/\${1}${id}\${3}/g" "$proj"

if [[ -n "$team" ]]; then
  perl -pi -e "s/DEVELOPMENT_TEAM = 8QBDZ766S3;/DEVELOPMENT_TEAM = ${team};/g" "$proj"
fi

if [[ -n "$build" ]]; then
  perl -pi -e "s/^CURRENT_PROJECT_VERSION\\s*=.*/CURRENT_PROJECT_VERSION=${build}/" "$version"
fi

PB=/usr/libexec/PlistBuddy
$PB -c "Set :CFBundleDisplayName 'Nuvio Live TV'" "$plist" 2>/dev/null || $PB -c "Add :CFBundleDisplayName string 'Nuvio Live TV'" "$plist"
$PB -c "Set :ITSAppUsesNonExemptEncryption false" "$plist" 2>/dev/null || $PB -c "Add :ITSAppUsesNonExemptEncryption bool false" "$plist"

# Fail loudly if any upstream ID is left behind.
if grep -nE 'PRODUCT_BUNDLE_IDENTIFIER = \"?com\.nuvio\.' "$proj"; then
  echo "::error::Some upstream bundle IDs were not replaced."
  exit 1
fi
echo "iOS identity set:"
grep -n 'PRODUCT_BUNDLE_IDENTIFIER' "$proj" | sort -u -k3
grep -n 'DEVELOPMENT_TEAM' "$proj" | head -n 2
grep -n 'CURRENT_PROJECT_VERSION\|MARKETING_VERSION' "$version"
