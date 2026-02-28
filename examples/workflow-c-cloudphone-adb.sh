#!/bin/bash
set -euo pipefail

PHONE_ID="${PHONE_ID:-your-cloud-phone-id}"
API_URL="${MORELOGIN_API_URL:-http://127.0.0.1:40000}"
ADB_HOST="${ADB_HOST:-127.0.0.1}"
ADB_PORT="${ADB_PORT:-5555}"

curl -X POST "$API_URL/api/cloudphone/powerOn" \
  -H "Content-Type: application/json" \
  -d "{\"id\":\"$PHONE_ID\"}"

curl -X POST "$API_URL/api/cloudphone/info" \
  -H "Content-Type: application/json" \
  -d "{\"id\":\"$PHONE_ID\"}"

curl -X POST "$API_URL/api/cloudphone/updateAdb" \
  -H "Content-Type: application/json" \
  -d "{\"ids\":[\"$PHONE_ID\"],\"enableAdb\":true}"

adb connect "${ADB_HOST}:${ADB_PORT}"
adb shell ls /sdcard
adb shell input tap 500 1000

curl -X POST "$API_URL/api/cloudphone/powerOff" \
  -H "Content-Type: application/json" \
  -d "{\"id\":\"$PHONE_ID\"}"
