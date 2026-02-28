#!/bin/bash
set -euo pipefail

ENV_ID="${ENV_ID:-2026143235095064576}"
TARGET_URL="${TARGET_URL:-https://www.google.com}"
API_URL="${MORELOGIN_API_URL:-http://127.0.0.1:40000}"
ML_DIR="${MORELOGIN_SKILL_DIR:-$HOME/.openclaw/workspace/skills/morelogin}"
DEBUG_PORT=""
pause_random() { sleep "$((RANDOM % 4 + 3))"; }

echo "🚀 Start basic browser automation workflow"

on_error() {
  local exit_code=$?
  echo "❌ Workflow failed (exit code: $exit_code)"
  echo "💡 Troubleshooting hints:"
  echo "   1) Ensure MoreLogin desktop app is open and logged in"
  echo "   2) Ensure Local API is enabled and listening on 127.0.0.1:40000"
  echo "   3) Check whether another process is occupying required local ports"
}
trap on_error ERR

echo "🔎 Preflight: checking MoreLogin Local API..."
if ! curl -sS --max-time 3 -X POST "$API_URL/api/env/page" \
  -H "Content-Type: application/json" \
  -d '{"page":1,"pageSize":1}' >/dev/null; then
  echo "❌ Cannot connect to MoreLogin Local API: $API_URL"
  echo "   Please open MoreLogin and confirm Local API is enabled."
  exit 1
fi

echo "📱 [1/5] Starting MoreLogin browser profile..."
cd "$ML_DIR"
START_OUTPUT=$(node bin/morelogin.js browser start --env-id "$ENV_ID" 2>&1 || true)
echo "$START_OUTPUT"

if echo "$START_OUTPUT" | grep -qiE "EADDRINUSE|address already in use"; then
  echo "❌ Browser launch failed: port already in use."
  echo "   Close conflicting local process and retry."
  exit 1
fi

if echo "$START_OUTPUT" | grep -qiE "ECONNREFUSED|connect ECONNREFUSED"; then
  echo "❌ Browser launch failed: cannot reach MoreLogin Local API."
  echo "   Confirm MoreLogin desktop app is running and Local API is enabled."
  exit 1
fi

echo "⏳ Waiting profile to reach running status..."
RUNNING=0
STATUS_OUTPUT=""
for _ in {1..15}; do
  STATUS_OUTPUT=$(node bin/morelogin.js browser status --env-id "$ENV_ID" 2>&1 || true)
  if echo "$STATUS_OUTPUT" | grep -q '"status"[[:space:]]*:[[:space:]]*"running"'; then
    RUNNING=1
    break
  fi
  sleep 2
done

if [ "$RUNNING" -ne 1 ]; then
  echo "❌ Browser was not ready after 30s."
  echo "   Last status response:"
  echo "$STATUS_OUTPUT"
  echo "   Hint: MoreLogin may still be opening the profile in background; retry after a few seconds."
  exit 1
fi
echo "✅ Browser started and confirmed running."

echo "🔗 [2/5] Connecting Agent-Browser to CDP..."
DEBUG_PORT=$(echo "$STATUS_OUTPUT" | tr -d '\r' | grep -Eo 'debugPort[^0-9]*[0-9]+' | grep -Eo '[0-9]+' | head -1 || true)
if [ -z "${DEBUG_PORT:-}" ]; then
  echo "❌ debugPort is empty in browser status response."
  exit 1
fi
agent-browser close >/dev/null 2>&1 || true
agent-browser connect "$DEBUG_PORT"
ab() { agent-browser --cdp "$DEBUG_PORT" "$@"; }

if ! ab tab new "$TARGET_URL"; then
  if ! ab tab new https://example.org; then
    echo "⚠️ External sites unavailable, reconnecting then using local fallback page."
    agent-browser close >/dev/null 2>&1 || true
    agent-browser connect "$DEBUG_PORT"
    ab open "data:text/html,<html><head><title>Local Search Demo</title></head><body><input id='q' aria-label='Search' value=''><button id='search' onclick=\"document.title='Search Result';document.body.insertAdjacentHTML('beforeend','<p>done</p>')\">Search</button></body></html>"
  fi
fi
pause_random

echo "🤖 [3/5] Executing automation..."
SNAPSHOT=$(ab snapshot -i)
echo "$SNAPSHOT"

ab fill "input[name='q']" "MoreLogin automation test" \
  || ab fill "textarea[name='q']" "MoreLogin automation test" \
  || ab fill "#q" "MoreLogin automation test"
pause_random
ab click "button[type='submit']" || ab click "#search" || ab press Enter
pause_random

echo "🔍 [4/5] Verifying results..."
echo "Title: $(ab get title)"
echo "URL: $(ab get url)"

echo "🧹 [5/5] Cleaning resources..."
ab close || true
node bin/morelogin.js browser close --env-id "$ENV_ID" || true

echo "🎉 Workflow finished!"
