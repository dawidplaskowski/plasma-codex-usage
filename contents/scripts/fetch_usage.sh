#!/bin/sh
# Report Codex rate limits.
#
# Output, line by line:
#   "LIVE <json>"  current limits from chatgpt.com (the endpoint Codex CLI
#                  uses for /status), only when the stored token still works
#   <json>...      the latest snapshot per limit from local session logs,
#                  which also carry the token stats; or "NODATA"
#
# Log snapshots are only as fresh as the last Codex run, and they miss limit
# resets that happen in between, hence the live query first. The token is
# never refreshed here: that rotates the refresh token behind Codex's back.

CODEX_DIR="${CODEX_CONFIG_DIR:-$HOME/.codex}"
SESSIONS="$CODEX_DIR/sessions"

AUTH=$(tr -d '\n\r' < "$CODEX_DIR/auth.json" 2>/dev/null)
field() {
    printf '%s' "$AUTH" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
        | head -n 1 | sed 's/.*:[[:space:]]*"//;s/"$//'
}
TOKEN=$(field access_token)
ACCOUNT=$(field account_id)
# Both are single opaque words. Anything else means extraction went wrong,
# and passing it on would inject extra lines into the curl header block.
case "$TOKEN$ACCOUNT" in
    *[!A-Za-z0-9_.=-]*) TOKEN="" ;;
esac
if [ -n "$TOKEN" ]; then
    # Headers via stdin (-H @-) so the token never appears in process arguments.
    RESP=$(printf 'Authorization: Bearer %s\nChatGPT-Account-Id: %s\n' "$TOKEN" "$ACCOUNT" \
        | curl -sS --max-time 10 -H @- -w '\n%{http_code}' \
            "https://chatgpt.com/backend-api/wham/usage" 2>/dev/null)
    if [ "${RESP##*
}" = 200 ]; then
        printf 'LIVE %s\n' "$(printf '%s' "${RESP%
*}" | tr -d '\n\r')"
    fi
fi

if [ ! -d "$SESSIONS" ]; then
    echo "NODATA"
    exit 0
fi

# Find the 5 most recently modified .jsonl files
FILES=$(find "$SESSIONS" -name '*.jsonl' -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -5 | cut -d' ' -f2-)

if [ -z "$FILES" ]; then
    echo "NODATA"
    exit 0
fi

# Newer Codex CLIs log several limit types (limit_id "codex" is the account
# limit; others, e.g. "codex_bengalfox", are separate model quotas like
# GPT-Codex-Spark). Emit the newest line PER limit_id, account limit first.
# Legacy lines without limit_id count as the account limit.
OUT=$(for f in $FILES; do
    tail -c 262144 "$f" 2>/dev/null | grep '"rate_limits"' | tac
done | awk '
{
    id = "codex"
    if (match($0, /"limit_id"[[:space:]]*:[[:space:]]*"[^"]*"/)) {
        id = substr($0, RSTART, RLENGTH)
        sub(/^"limit_id"[[:space:]]*:[[:space:]]*"/, "", id)
        sub(/"$/, "", id)
    }
    # Pick the newest snapshot per limit by its own timestamp, not by file
    # order: resuming an old session touches its file before it logs a new
    # snapshot, so a recently modified file can still hold a weeks-old value.
    ts = ""
    if (match($0, /"timestamp"[[:space:]]*:[[:space:]]*"[^"]*"/)) {
        ts = substr($0, RSTART, RLENGTH)
        sub(/^"timestamp"[[:space:]]*:[[:space:]]*"/, "", ts)
        sub(/"$/, "", ts)
    }
    if (!(id in seen)) {
        order[n++] = id
        seen[id] = $0
        best[id] = ts
    } else if (ts > best[id]) {
        seen[id] = $0
        best[id] = ts
    }
}
END {
    if ("codex" in seen) print seen["codex"]
    for (i = 0; i < n; i++) if (order[i] != "codex") print seen[order[i]]
}')

if [ -n "$OUT" ]; then
    printf '%s\n' "$OUT"
    exit 0
fi

echo "NODATA"
