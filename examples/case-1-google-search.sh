#!/bin/bash
set -euo pipefail

ENV_ID="${ENV_ID:-2026143235095064576}"
ML_DIR="${MORELOGIN_SKILL_DIR:-$HOME/.openclaw/workspace/skills/morelogin}"
DEBUG_PORT=""
pause_random() { sleep "$((RANDOM % 4 + 3))"; }

echo "🧪 Case 1: Google search automation"

cd "$ML_DIR"
node bin/morelogin.js browser start --env-id "$ENV_ID" &
sleep 10
STATUS_OUTPUT=$(node bin/morelogin.js browser status --env-id "$ENV_ID")
DEBUG_PORT=$(echo "$STATUS_OUTPUT" | tr -d '\r' | grep -Eo 'debugPort[^0-9]*[0-9]+' | grep -Eo '[0-9]+' | head -1 || true)
if [ -z "${DEBUG_PORT:-}" ]; then
  echo "❌ Cannot get debugPort from MoreLogin status."
  exit 1
fi
agent-browser close >/dev/null 2>&1 || true
agent-browser connect "$DEBUG_PORT"
ab() { agent-browser --cdp "$DEBUG_PORT" "$@"; }

if ! ab tab new https://www.google.com; then
  if ! ab tab new https://example.org; then
    ab tab new "data:text/html,<html><head><title>Search Demo</title></head><body><input id='q' aria-label='Search'><button id='search' onclick=\"document.title='Search Result'\">Search</button></body></html>"
  fi
fi
pause_random

ab snapshot -i || true
ab fill "input[name='q']" "MoreLogin CDP automation test" \
  || ab fill "textarea[name='q']" "MoreLogin CDP automation test" \
  || ab fill "#q" "MoreLogin CDP automation test"
pause_random
ab click "button[type='submit']" || ab click "#search" || ab press Enter

pause_random
echo "Page title: $(ab get title)"
echo "Current URL: $(ab get url)"

ab screenshot "$HOME/search-demo.png" || true

ab close
node bin/morelogin.js browser close --env-id "$ENV_ID"

echo "✅ Case 1 complete"
