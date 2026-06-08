#!/bin/sh
set -eu

file="whitespace/ScreenTimeShieldCenter.swift"
content_view="whitespace/ContentView.swift"

grep -q "blockedSelection" "$file"
grep -q "store\\.shield\\.applications = blockedSelection\\.applicationTokens" "$file"
grep -q "store\\.shield\\.webDomains = blockedSelection\\.webDomainTokens" "$file"

if grep -q "guard hasBlockedActivities else" "$file"; then
  echo "applyFocusShield must not require a second blocklist selection" >&2
  exit 1
fi

if grep -q "BlocklistContinuation\\|blocklistContinuation\\|guard screenTimeCenter\\.hasBlockedActivities else" "$content_view"; then
  echo "starting focus must not trigger a second App picker after the allowed list is selected" >&2
  exit 1
fi
