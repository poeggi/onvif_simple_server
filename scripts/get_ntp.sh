#!/bin/sh
# Output every configured NTP server, one per line, de-duplicated.

seen=""
found=0

emit() {
    # Args are word-split on whitespace so space-separated server lists work.
    for s in "$@"; do
        [ -n "$s" ] || continue
        printf '%s\n' "$seen" | grep -qxF "$s" && continue
        seen="${seen}${s}
"
        printf '%s\n' "$s"
        found=1
    done
}

# chrony: if chronyd is actually running it is the authoritative NTP daemon,
# so it must be checked before timedatectl (which still reports compiled-in
# FallbackNTPServers even on a chrony host, where they are never used).
# Report the configured server/pool/peer directives -- the admin-entered
# hostnames -- rather than chrony's resolved runtime peers, which for a pool
# expand to many addresses and are shown truncated / numeric by "sources".
if command -v chronyc >/dev/null 2>&1 && chronyc tracking >/dev/null 2>&1; then
    conf=$(
        cat /etc/chrony/chrony.conf /etc/chrony.conf 2>/dev/null
        cat /etc/chrony/conf.d/*.conf /etc/chrony/sources.d/*.sources 2>/dev/null
    )
    servers=$(printf '%s\n' "$conf" | awk '$1=="server"||$1=="pool"||$1=="peer"{print $2}')
    emit $servers
    # Fall back to the live peers only if the config was unreadable.
    if [ "$found" -eq 0 ]; then
        peers=$(chronyc -c sources 2>/dev/null | awk -F, 'NF>=3 && $3 != "" {print $3}')
        emit $peers
    fi
    [ "$found" -eq 1 ] && exit 0
fi

# systemd-timesyncd: timedatectl show-timesync
# SystemNTPServers / FallbackNTPServers are space-separated lists; ServerName
# is the currently-selected peer (may not appear in either list).
if command -v timedatectl >/dev/null 2>&1; then
    td=$(timedatectl show-timesync 2>/dev/null)
    if [ -n "$td" ]; then
        sys=$(printf '%s\n' "$td" | sed -n 's/^SystemNTPServers=//p')
        fb=$(printf '%s\n' "$td" | sed -n 's/^FallbackNTPServers=//p')
        active=$(printf '%s\n' "$td" | sed -n 's/^ServerName=//p')
        emit $sys $fb $active
        [ "$found" -eq 1 ] && exit 0
    fi
fi

exit 1
