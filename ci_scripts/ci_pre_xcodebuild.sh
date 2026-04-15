#!/bin/bash
# Runs before xcodebuild archive.
# Sets CURRENT_PROJECT_VERSION to CI_BUILD_NUMBER so every Xcode Cloud run
# gets a unique, auto-incrementing build number without touching the project file.
# MARKETING_VERSION is left as-is from the project file.

set -euo pipefail

if [[ -z "${CI_BUILD_NUMBER:-}" ]]; then
  echo "ci_pre_xcodebuild: CI_BUILD_NUMBER not set — running outside Xcode Cloud, skipping."
  exit 0
fi

BUILD_OFFSET=27
BUILD_NUMBER=$(( CI_BUILD_NUMBER + BUILD_OFFSET ))
echo "ci_pre_xcodebuild: setting build number to $BUILD_NUMBER (CI_BUILD_NUMBER=$CI_BUILD_NUMBER + offset=$BUILD_OFFSET)"
xcrun agvtool new-version -all "$BUILD_NUMBER"
