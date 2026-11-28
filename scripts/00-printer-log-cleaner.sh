
#!/bin/sh
# Printer Log Cleaner
# Runs once per boot.
# Active logs are cleared only when larger than 50 MiB.
# Rotated logs are always deleted.

LOG_DIR="/usr/data/opencreator/klipper/logs"
EXTRA_LOG_DIR="/usr/data/logs"
DONE_MARKER="/tmp/printer-log-cleaner.done"
LOCK_DIR="/tmp/printer-log-cleaner.lock"
LOG_FILE="/tmp/printer-log-cleaner.log"
MAX_BYTES=52428800

log() {
    printf '%s [printer-log-cleaner] %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null)" "$*" >> "$LOG_FILE"
}

file_size() {
    wc -c < "$1" 2>/dev/null | tr -d ' '
}

release_lock() {
    rmdir "$LOCK_DIR" 2>/dev/null || true
}

acquire_lock() {
    n=0
    while ! mkdir "$LOCK_DIR" 2>/dev/null; do
        n=$((n + 1))
        if [ "$n" -ge 10 ]; then
            log "WARNING: lock unavailable; cleanup skipped"
            return 1
        fi
        sleep 1
    done
    return 0
}

clean_logs() {
    if [ ! -d "$LOG_DIR" ]; then
        log "WARNING: log directory not found: $LOG_DIR"
    else
        changed=0

        for name in printer.log moonraker.log AFC.log; do
            path="$LOG_DIR/$name"
            [ -f "$path" ] || continue

            size=$(file_size "$path")
            case "$size" in
                ''|*[!0-9]*)
                    log "WARNING: cannot read size of $name"
                    continue
                    ;;
            esac

            if [ "$size" -gt "$MAX_BYTES" ]; then
                if : > "$path"; then
                    log "CLEARED active log: $name ($size bytes)"
                    changed=1
                else
                    log "ERROR: failed to clear $name"
                fi
            else
                log "OK active log: $name ($size bytes)"
            fi
        done

        for pattern in printer.log.* moonraker.log.* AFC.log.*; do
            for path in "$LOG_DIR"/$pattern; do
                [ -f "$path" ] || continue
                name=${path##*/}

                if rm -f "$path"; then
                    log "DELETED rotated log: $name"
                    changed=1
                else
                    log "ERROR: failed to delete $name"
                fi
            done
        done

        [ "$changed" -eq 1 ] || log "No cleanup actions required in $LOG_DIR"
    fi

    if [ ! -d "$EXTRA_LOG_DIR" ]; then
        log "WARNING: log directory not found: $EXTRA_LOG_DIR"
        return 0
    fi

    changed=0

    # Clear active .log files only when larger than 50 MiB.
    for path in "$EXTRA_LOG_DIR"/*.log; do
        [ -f "$path" ] || continue
        name=${path##*/}

        size=$(file_size "$path")
        case "$size" in
            ''|*[!0-9]*)
                log "WARNING: cannot read size of $name"
                continue
                ;;
        esac

        if [ "$size" -gt "$MAX_BYTES" ]; then
            if : > "$path"; then
                log "CLEARED active log: $EXTRA_LOG_DIR/$name ($size bytes)"
                changed=1
            else
                log "ERROR: failed to clear $EXTRA_LOG_DIR/$name"
            fi
        else
            log "OK active log: $EXTRA_LOG_DIR/$name ($size bytes)"
        fi
    done

    # Delete rotated .log files regardless of size.
    for path in "$EXTRA_LOG_DIR"/*.log.*; do
        [ -f "$path" ] || continue
        name=${path##*/}

        if rm -f "$path"; then
            log "DELETED rotated log: $EXTRA_LOG_DIR/$name"
            changed=1
        else
            log "ERROR: failed to delete $EXTRA_LOG_DIR/$name"
        fi
    done

    [ "$changed" -eq 1 ] || log "No cleanup actions required in $EXTRA_LOG_DIR"
}

run_once() {
    if [ -f "$DONE_MARKER" ]; then
        log "Cleanup already completed this boot"
        return 0
    fi

    acquire_lock || return 0
    trap release_lock EXIT

    if [ ! -f "$DONE_MARKER" ]; then
        log "Starting once-per-boot cleanup"
        clean_logs
        : > "$DONE_MARKER" || log "WARNING: unable to create boot marker"
    fi

    release_lock
    trap - EXIT
    return 0
}

log "Startup check started"
run_once
log "Startup check finished"
exit 0
