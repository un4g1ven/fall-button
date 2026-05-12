#!/usr/bin/env bash
# ntfy test-fire — validate the notification chain before involving HA or the button.
#
# Usage:
#   ./ntfy_test_fire.sh <topic>             # interactive menu
#   ./ntfy_test_fire.sh <topic> emergency   # single-shot the emergency alert
#   ./ntfy_test_fire.sh <topic> battery     # low-battery alert
#   ./ntfy_test_fire.sh <topic> watchdog    # offline-watchdog alert
#   ./ntfy_test_fire.sh <topic> all         # fire all three with a 5s gap

set -euo pipefail

TOPIC="${1:-}"
TEST="${2:-menu}"

if [[ -z "$TOPIC" ]]; then
  cat <<EOF
Usage: $0 <topic> [emergency|battery|watchdog|all]

Generate a topic first if you don't have one:
    echo "fallbutton-\$(openssl rand -hex 16)"

Treat the topic like a password — anyone who knows it can read AND send.
EOF
  exit 1
fi

# Edit these to make the test-fire look like your real production alert.
# (Optional — the chain works fine with the defaults.)
WEARER_PHONE_TEL="tel:+15551234567"
WEARER_MAP_URL="https://maps.google.com/?q=123%20Main%20Street%20Anytown%20CA%2090210"
NTFY_HOST="https://ntfy.sh"

fire_emergency() {
  echo "Firing EMERGENCY (priority 5, click-to-call)..."
  curl -s -X POST "$NTFY_HOST/$TOPIC" \
    -H "Title: EMERGENCY BUTTON (TEST)" \
    -H "Priority: 5" \
    -H "Tags: rotating_light,sos" \
    -H "Click: $WEARER_PHONE_TEL" \
    -H "Actions: view, Call them, $WEARER_PHONE_TEL, clear=true; view, Open map, $WEARER_MAP_URL" \
    -H "Content-Type: text/plain" \
    --data-raw "TEST press at $(date '+%a %I:%M %p'). This is a TEST. In a real alert, tap to call."
  echo
  echo "Sent. All subscribed phones should buzz LOUDLY within ~3 sec, even on silent if Critical Alerts is enabled."
  echo "On tap, the phone dialer should open with the test number pre-filled."
}

fire_battery() {
  echo "Firing battery-low warning (priority 3)..."
  curl -s -X POST "$NTFY_HOST/$TOPIC" \
    -H "Title: Fall button battery low (TEST)" \
    -H "Priority: 3" \
    -H "Tags: battery,warning" \
    -H "Content-Type: text/plain" \
    --data-raw "TEST: Battery at 18%. Plug in the USB-C cable to charge."
  echo
  echo "Sent. Should arrive as a normal notification — no alarm sound."
}

fire_watchdog() {
  echo "Firing watchdog (button silent) alert (priority 4)..."
  curl -s -X POST "$NTFY_HOST/$TOPIC" \
    -H "Title: Fall button is silent (TEST)" \
    -H "Priority: 4" \
    -H "Tags: warning,signal_strength" \
    -H "Content-Type: text/plain" \
    --data-raw "TEST: Button has not reported in 38 hours. It may be off, out of battery, or out of WiFi range."
  echo
  echo "Sent. Higher-than-normal priority but not max."
}

case "$TEST" in
  emergency) fire_emergency ;;
  battery)   fire_battery ;;
  watchdog)  fire_watchdog ;;
  all)
    fire_emergency
    sleep 5
    fire_battery
    sleep 5
    fire_watchdog
    ;;
  menu|*)
    echo
    echo "ntfy test-fire — topic: $TOPIC"
    echo
    echo "  1) Emergency press (max priority, click-to-call)"
    echo "  2) Battery low warning"
    echo "  3) Watchdog (button silent for 36h+)"
    echo "  4) Fire all three (5s apart)"
    echo "  q) quit"
    echo
    read -rp "Pick > " choice
    case "$choice" in
      1) fire_emergency ;;
      2) fire_battery ;;
      3) fire_watchdog ;;
      4) fire_emergency; sleep 5; fire_battery; sleep 5; fire_watchdog ;;
      *) echo "bye." ;;
    esac
    ;;
esac
