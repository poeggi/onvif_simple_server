#!/bin/sh
# Output every non-loopback nameserver address, one per line, de-duplicated.
# Checks /run/systemd/resolve/resolv.conf first (real upstream on
# systemd-resolved systems where /etc/resolv.conf points to the stub),
# then falls back to /etc/resolv.conf.

seen=""
found=0

emit() {
    # Skip duplicates while preserving order.
    printf '%s\n' "$seen" | grep -qxF "$1" && return
    seen="${seen}${1}
"
    printf '%s\n' "$1"
    found=1
}

for f in /run/systemd/resolve/resolv.conf /etc/resolv.conf; do
    [ -r "$f" ] || continue
    while read -r key addr rest; do
        [ "$key" = "nameserver" ] || continue
        [ -n "$addr" ] || continue
        case "$addr" in
            127.*) continue ;;
            ::1)   continue ;;
        esac
        # Strip any IPv6 zone index (fe80::...%3 -> fe80::...) so the address
        # passes inet_pton validation; the scope id is only meaningful locally.
        addr="${addr%%\%*}"
        emit "$addr"
    done < "$f"
    # Prefer the systemd upstream file: if it yielded servers, stop.
    [ "$found" -eq 1 ] && break
done

[ "$found" -eq 1 ] && exit 0
exit 1
