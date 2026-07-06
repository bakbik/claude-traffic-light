#!/usr/bin/env bash
# traffic.sh — Linux/macOS counterpart of traffic.ps1, called by the plugin hooks.
# Usage: traffic.sh R|Y|G|O
COLOR="$1"
case "$COLOR" in R|Y|G|O) ;; *) exit 0 ;; esac

DIR="$(cd "$(dirname "$0")" && pwd)"

resolve_port() {
  if [ -n "$TRAFFIC_COM" ]; then echo "$TRAFFIC_COM"; return; fi
  # ESP32 USB-JTAG serial (Espressif VID 303a) — by-id names embed the maker string
  for p in /dev/serial/by-id/*[Ee]spressif* /dev/serial/by-id/*303[Aa]*; do
    [ -e "$p" ] && { echo "$p"; return; }
  done
  # macOS has no /dev/serial; fall back to the usual USB modem device
  for p in /dev/cu.usbmodem*; do
    [ -e "$p" ] && { echo "$p"; return; }
  done
}

PORT="$(resolve_port)"
SENT=false
if [ -n "$PORT" ] && [ -w "$PORT" ]; then
  TO=""
  command -v timeout >/dev/null && TO="timeout 1"  # wedged tty must never stall the hook; macOS lacks timeout
  # stty: -F on Linux, -f on macOS
  if $TO bash -c "{ stty -F '$PORT' 115200 raw -echo || stty -f '$PORT' 115200 raw -echo; } 2>/dev/null; printf '%s' '$COLOR' > '$PORT'" 2>/dev/null; then
    SENT=true
  fi
fi

# breadcrumb: proves the hook actually ran (mirrors traffic.ps1)
echo "$(date +%H:%M:%S)  $COLOR  sent=$SENT" >> "$DIR/traffic.log"
exit 0  # never fail a hook, even if the light is unplugged
