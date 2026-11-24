#!/bin/sh
set -eu

PLUGIN_DIR=${OC_PLUGIN_DIR:-$(CDPATH= cd -- "$(dirname "$0")" && pwd)}
STARTUP_DIR="/usr/data/opencreator/startup/scripts"
TARGET="$STARTUP_DIR/00-printer-log-cleaner.sh"

mkdir -p "$STARTUP_DIR"
cp "$PLUGIN_DIR/scripts/00-printer-log-cleaner.sh" "$TARGET"
chmod 755 "$TARGET"

echo "Printer Log Cleaner installed."
