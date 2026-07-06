#!/usr/bin/env bash
# One-time Linux setup: udev rule granting access to the traffic light,
# so hooks work without dialout membership or per-replug chmod.
# Usage: sudo scripts/setup-linux.sh
set -e
[ "$(id -u)" -eq 0 ] || exec sudo "$0" "$@"

# Espressif VID 303a = ESP32 native USB (JTAG/serial)
echo 'SUBSYSTEM=="tty", ATTRS{idVendor}=="303a", MODE="0666"' \
  > /etc/udev/rules.d/99-claude-traffic-light.rules
udevadm control --reload-rules
udevadm trigger --subsystem-match=tty
echo "udev rule installed. Replug the board if the light doesn't respond."
