#!/bin/bash
set -euo pipefail

ENV_ID="${ENV_ID:-2026143235095064576}"
ML_DIR="${MORELOGIN_SKILL_DIR:-$HOME/.openclaw/workspace/skills/morelogin}"
DEBUG_PORT=""
pause_random() { sleep "$((RANDOM % 4 + 3))"; }

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

if ! ab tab new https://books.toscrape.com/; then
  ab open "data:text/html,<html><body><div class='product' data-price='9.99'>Product A</div><div class='product' data-price='19.99'>Product B</div><button id='next'>Next</button></body></html>"
fi
pause_random

PRODUCTS=$(ab eval '(() => Array.from(document.querySelectorAll(".product_pod, .product")).slice(0, 8).map((item) => { const name = item.querySelector("h3 a")?.getAttribute("title") || item.querySelector("h3 a")?.textContent?.trim() || item.textContent.trim().slice(0, 40); const price = item.querySelector(".price_color")?.textContent?.trim() || item.getAttribute("data-price") || "N/A"; return name + "|" + price; }).join("\\n"))()')
echo "$PRODUCTS"
pause_random

ab click ".next a" || ab click "#next" || true
ab close || true
node bin/morelogin.js browser close --env-id "$ENV_ID" || true
