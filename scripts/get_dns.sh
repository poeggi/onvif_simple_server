#!/bin/sh
# Output the first non-loopback nameserver address.
# Checks /run/systemd/resolve/resolv.conf first (real upstream on
# systemd-resolved systems where /etc/resolv.conf points to the stub),
# then falls back to /etc/resolv.conf.

for f in /run/systemd/resolve/resolv.conf /etc/resolv.conf; do
    [ -r "$f" ] || continue
    while read -r key addr rest; do
        [ "$key" = "nameserver" ] || continue
        case "$addr" in
            127.*) continue ;;
            ::1)   continue ;;
        esac
        [ -n "$addr" ] && printf '%s\n' "$addr" && exit 0
    done < "$f"
done

exit 1
