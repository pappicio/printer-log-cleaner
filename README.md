# Printer Log Cleaner

OpenCreator plugin for FlashForge Creator 5.

## Behavior
- Threshold: 50 MiB (52,428,800 bytes), checked independently per file.
- Active `printer.log`, `moonraker.log`, and `AFC.log` files over the threshold are truncated in place. This preserves the inode and avoids breaking processes that already have the log open.
- Rotated files matching `printer.log.*`, `moonraker.log.*`, and `AFC.log.*` are always deleted, regardless of size.
- No archives are created.
- The plugin installs `00-printer-log-cleaner.sh` in `startup/scripts/` with mode 755.
- A per-boot marker ensures cleanup runs only once per boot. A temporary lock prevents concurrent executions.

## Install
Install the ZIP with `oc-plugin install` / the OpenCreator Plugin Manager.

## Important
The active log files are truncated, not unlinked. Unlinking an active log can leave the running process writing to a deleted inode and may prevent new log data from appearing at the expected path.
