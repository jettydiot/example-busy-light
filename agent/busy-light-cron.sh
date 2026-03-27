#!/bin/bash
# Busy Light Agent — checks Google Calendar and sets LED color
#
# Run via OpenClaw cron every 5 minutes:
#   openclaw cron set busy-light --schedule "*/5 * * * *" \
#     --command "bash ~/Projects/example-busy-light/agent/busy-light-cron.sh"
#
# Or via the OpenClaw skill/hook system.
#
# Requires:
#   - gog CLI (Google Calendar access)
#   - jettyd API key + device ID

JETTYD_API_KEY="${JETTYD_API_KEY:-tk_YOUR_API_KEY}"
DEVICE_ID="${DEVICE_ID:-YOUR_DEVICE_ID}"
API_URL="${API_URL:-https://api.jettyd.com}"

# Get current calendar events
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EVENTS=$(gog calendar events primary --from today --to today --json 2>/dev/null)

# Check if in a meeting right now
IN_MEETING=false
MEETING_SOON=false

if echo "$EVENTS" | python3 -c "
import sys, json
from datetime import datetime, timezone
now = datetime.now(timezone.utc)
events = json.load(sys.stdin) if sys.stdin.readable() else []
in_meeting = False
meeting_soon = False
for e in events:
    start = datetime.fromisoformat(e.get('start',{}).get('dateTime','').replace('Z','+00:00'))
    end = datetime.fromisoformat(e.get('end',{}).get('dateTime','').replace('Z','+00:00'))
    if start <= now <= end:
        in_meeting = True
    elif now < start and (start - now).total_seconds() < 600:
        meeting_soon = True
if in_meeting:
    print('IN_MEETING')
elif meeting_soon:
    print('MEETING_SOON')
else:
    print('FREE')
" 2>/dev/null | grep -q "IN_MEETING"; then
    STATUS="busy"
elif echo "$EVENTS" | python3 -c "
import sys, json
from datetime import datetime, timezone
now = datetime.now(timezone.utc)
events = json.load(sys.stdin) if sys.stdin.readable() else []
for e in events:
    start = datetime.fromisoformat(e.get('start',{}).get('dateTime','').replace('Z','+00:00'))
    if now < start and (start - now).total_seconds() < 600:
        print('MEETING_SOON')
        break
" 2>/dev/null | grep -q "MEETING_SOON"; then
    STATUS="soon"
else
    STATUS="free"
fi

# Send command to device
send_command() {
    local cmd_type="$1"
    local target="$2"
    local duration="${3:-0}"
    curl -s -X POST "$API_URL/v1/devices/$DEVICE_ID/commands" \
        -H "Authorization: Bearer $JETTYD_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"command_type\": \"$cmd_type\", \"payload\": {\"target\": \"$target\", \"duration_sec\": $duration}}" \
        > /dev/null 2>&1
}

case "$STATUS" in
    busy)
        send_command "switch_off" "green"
        send_command "switch_off" "amber"
        send_command "switch_on" "red" 0
        ;;
    soon)
        send_command "switch_off" "green"
        send_command "switch_off" "red"
        send_command "switch_on" "amber" 0
        ;;
    free)
        send_command "switch_off" "red"
        send_command "switch_off" "amber"
        send_command "switch_on" "green" 0
        ;;
esac

echo "[busy-light] $(date): status=$STATUS"
