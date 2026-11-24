#!/bin/sh
set -eu

STARTUP_DIR="/usr/data/opencreator/startup/scripts"
TARGET="$STARTUP_DIR/00-printer-log-cleaner.sh"

rm -f "$TARGET"
rm -f /tmp/printer-log-cleaner.done

echo "Printer Log Cleaner removed."
