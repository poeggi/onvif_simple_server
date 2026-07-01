#!/bin/sh
# Output the active NTP server hostname or address.

# systemd-timesyncd: timedatectl show-timesync
if command -v timedatectl >/dev/null 2>&1; then
    td=$(timedatectl show-timesync 2>/dev/null)
    if [ -n "$td" ]; then
        server=$(printf '%s\n' "$td" | sed -n 's/^ServerName=//p')
        [ -z "$server" ] && \
            server=$(printf '%s\n' "$td" | sed -n 's/^SystemNTPServers=//p' | sed 's/[[:space:]].*//')
        [ -z "$server" ] && \
            server=$(printf '%s\n' "$td" | sed -n 's/^FallbackNTPServers=//p' | sed 's/[[:space:]].*//')
        [ -n "$server" ] && printf '%s\n' "$server" && exit 0
    fi
fi

# chrony: chronyc tracking
if command -v chronyc >/dev/null 2>&1; then
    server=$(chronyc tracking 2>/dev/null | sed -n 's/^Reference ID[^(]*(\([^)]*\)).*/\1/p')
    [ -n "$server" ] && printf '%s\n' "$server" && exit 0
fi

exit 1
