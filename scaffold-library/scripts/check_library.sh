#!/usr/bin/env sh
# Recount the collection from the filesystem and check it against its own conventions.
#
# The rule this exists to enforce: a total is never carried forward from a previous
# session. It is recounted. Everything else here is a convention that is cheap to
# state and expensive to keep by hand.
#
# POSIX sh. Needs nothing installed beyond find, grep, sed, awk and a checksum tool.
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CFG="$ROOT/library.yaml"
[ -f "$CFG" ] || { echo "no library.yaml at $CFG" >&2; exit 1; }

val() { sed -n "s/^$1:[[:space:]]*//p" "$CFG" | sed "s/^'//; s/'$//; s/^\"//; s/\"$//" | head -1; }
COLL="$ROOT/$(val root)"
INTAKE="$ROOT/$(val intake)"
PATTERN="$(val naming_pattern)"
MARKER="$(val unidentified_marker)"
EXTS="$(val item_extensions)"
REFRESH="$(val refresh_interval_days)"
[ -n "$EXTS" ] || EXTS="pdf"

fail=0
ok()   { printf 'OK    %s\n' "$*"; }
bad()  { printf 'FAIL  %s\n' "$*"; fail=1; }
note() { printf 'NOTE  %s\n' "$*"; }

# Build the find expression for item extensions.
set -- ; first=1
for e in $EXTS; do
  if [ "$first" = "1" ]; then set -- -iname "*.$e"; first=0
  else set -- "$@" -o -iname "*.$e"; fi
done
[ -d "$COLL" ] || { echo "collection root not found: $COLL" >&2; exit 1; }
items=$(find "$COLL" -type f \( "$@" \) 2>/dev/null | sort)
total=$(printf '%s\n' "$items" | grep -c . || true)

printf '=== recount, %s ===\n' "$(date -u +%Y-%m-%d)"
printf 'collection root: %s\n\n' "$COLL"

# --- per-folder counts, ground truth ----------------------------------------
if [ "$total" -gt 0 ]; then
  printf '%s\n' "$items" | sed "s|^$COLL/||" | awk -F/ 'NF>1 {d=$1} NF==1 {d="(root)"} {c[d]++}
    END { for (k in c) printf "  %-44s %6d\n", k, c[k] }' | sort
else
  printf '  (collection is empty)\n'
fi
printf '  %-44s %6d\n\n' "TOTAL FILES" "$total"

# --- 1. nothing loose in the collection root --------------------------------
loose=$(printf '%s\n' "$items" | sed "s|^$COLL/||" | awk -F/ 'NF==1' | grep -c . || true)
if [ "$loose" = "0" ]; then ok "no loose items in the collection root"
else bad "$loose item(s) sitting in the collection root — file them in a themed folder"; fi

# --- 2. intake is empty ------------------------------------------------------
if [ -d "$INTAKE" ]; then
  pending=$(find "$INTAKE" -type f \( "$@" \) 2>/dev/null | grep -c . || true)
  if [ "$pending" = "0" ]; then ok "intake is empty"
  else bad "$pending item(s) still in intake — identify, rename, dedupe, file and log them"; fi
fi

# --- 3. filenames follow the convention -------------------------------------
offenders=$(printf '%s\n' "$items" | while IFS= read -r f; do
  [ -n "$f" ] || continue
  b=$(basename "$f")
  case "$b" in *"$MARKER"*) continue ;; esac
  printf '%s' "$b" | grep -qE "$PATTERN" || printf '%s\n' "${f#"$COLL"/}"
done)
n=$(printf '%s\n' "$offenders" | grep -c . || true)
if [ "$n" = "0" ]; then ok "every filename matches the naming convention"
else
  bad "$n filename(s) do not match the convention:"
  printf '%s\n' "$offenders" | head -15 | sed 's|^|        |'
  [ "$n" -gt 15 ] && printf '        ... and %s more\n' "$((n-15))"
fi

# --- 4. unidentified items are all logged -----------------------------------
unid=$(printf '%s\n' "$items" | grep -F "$MARKER" || true)
un=$(printf '%s\n' "$unid" | grep -c . || true)
if [ "$un" = "0" ]; then ok "no unidentified items"
else
  note "$un item(s) carry the unidentified marker — correct, if each is logged"
  missing=0
  printf '%s\n' "$unid" | while IFS= read -r f; do
    [ -n "$f" ] || continue
    b=$(basename "$f")
    grep -qF "$b" "$ROOT/INDEX.md" 2>/dev/null || printf '        unlogged: %s\n' "$b"
  done
  printf '%s\n' "$unid" | while IFS= read -r f; do
    [ -n "$f" ] || continue
    grep -qF "$(basename "$f")" "$ROOT/INDEX.md" 2>/dev/null || echo x
  done | grep -q x && bad "unidentified items above are not logged in INDEX.md" \
                   || ok "every unidentified item is logged in INDEX.md"
fi

# --- 5. byte-identical duplicates -------------------------------------------
if command -v md5sum >/dev/null 2>&1; then SUM="md5sum"
elif command -v md5 >/dev/null 2>&1; then SUM="md5 -r"
elif command -v shasum >/dev/null 2>&1; then SUM="shasum"
elif command -v cksum >/dev/null 2>&1; then SUM="cksum"
else SUM=""; fi
if [ -z "$SUM" ]; then
  note "no checksum tool found; duplicate check skipped (say so when you report)"
elif [ "$total" -gt 0 ]; then
  dups=$(printf '%s\n' "$items" | while IFS= read -r f; do
           [ -n "$f" ] || continue; $SUM "$f" 2>/dev/null; done \
         | awk '{print $1}' | sort | uniq -d | grep -c . || true)
  if [ "$dups" = "0" ]; then ok "no byte-identical duplicates"
  else note "$dups checksum group(s) have identical copies — deliberate repeats are fine, but each should be marked and counted once"; fi
else
  ok "no items to check for duplicates"
fi

# --- 6. the index agrees with the filesystem --------------------------------
logged=$(grep -oE '\*\*Totals:\*\*[^|]*' "$ROOT/INDEX.md" 2>/dev/null | grep -oE '[0-9]+' | head -2 | tail -1 || true)
if [ -n "$logged" ]; then
  if [ "$logged" = "$total" ]; then ok "INDEX.md file total ($logged) matches the filesystem ($total)"
  else bad "INDEX.md logs $logged files, the filesystem has $total — flag the gap in the update log, do not silently overwrite"; fi
else
  note "no totals line parsed from INDEX.md"
fi

# --- 7. is a refresh overdue ------------------------------------------------
lastv=$(grep -oE '\*\*Last verified:\*\*[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}' "$ROOT/INDEX.md" 2>/dev/null | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' || true)
if [ -n "$lastv" ] && [ -n "$REFRESH" ]; then
  days=$(awk -v d="$lastv" 'BEGIN{
    split(d,a,"-");
    t=mktime(a[1]" "a[2]" "a[3]" 00 00 00");
    if (t<0) { print -1 } else { print int((systime()-t)/86400) } }' 2>/dev/null || echo -1)
  if [ "$days" -lt 0 ]; then note "could not compute days since last verification"
  elif [ "$days" -gt "$REFRESH" ]; then note "last verified $days days ago; the refresh interval is $REFRESH — a maintenance pass is due"
  else ok "verified $days days ago, within the $REFRESH-day refresh interval"; fi
fi

printf '\n'
if [ "$fail" = "0" ]; then printf 'library OK — use the counts above in INDEX.md\n'; exit 0; fi
printf 'library has problems — flag them in the update log rather than resolving them silently\n'; exit 1
