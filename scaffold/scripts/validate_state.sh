#!/usr/bin/env sh
# Check the state files are well-formed and mutually consistent before trusting them.
# The scaffold family this kit came from had no validator, and the schemas drifted.
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REG="$ROOT/projects/registry.yaml"
fail=0
say() { printf '%s\n' "$*"; }
bad() { printf 'FAIL  %s\n' "$*"; fail=1; }

[ -f "$REG" ] || { bad "missing $REG"; exit 1; }
say "registry: $REG"

active=$(grep -c '^[[:space:]]*active:[[:space:]]*true' "$REG" 2>/dev/null || true)
case "$active" in
  0) say "NOTE  no active project yet — expected in a fresh scaffold" ;;
  1) say "OK    exactly one active project" ;;
  *) bad "$active projects marked active; exactly one is allowed" ;;
esac

# Registry entries: slug, then any current_iteration it carries. project.yaml is the
# record of the current iteration; a registry copy that disagrees with it is drift.
entries=$(awk '
  /^[[:space:]]*#/ { next }
  /^[[:space:]]*-[[:space:]]*slug:/ {
    if (s != "") print s "\t" it
    s = $0; sub(/.*slug:[[:space:]]*/, "", s); sub(/[[:space:]]+#.*$/, "", s); it = ""; next }
  /^[[:space:]]+current_iteration:/ {
    it = $0; sub(/.*current_iteration:[[:space:]]*/, "", it); sub(/[[:space:]]+#.*$/, "", it); gsub(/"/, "", it) }
  END { if (s != "") print s "\t" it }' "$REG")
tab=$(printf '\t')
if [ -n "$entries" ]; then
  reg_problems=$(printf '%s\n' "$entries" | while IFS="$tab" read -r slug rit; do
    if [ ! -f "$ROOT/projects/$slug/project.yaml" ]; then
      echo "registry lists '$slug' but projects/$slug/project.yaml does not exist"; continue
    fi
    if [ -n "$rit" ]; then
      pit=$(grep -E '^current_iteration:' "$ROOT/projects/$slug/project.yaml" | sed 's/.*: *//; s/"//g' || true)
      if [ "$rit" != "$pit" ]; then
        echo "$slug: registry says iteration $rit, project.yaml says $pit — project.yaml is the record; remove the registry copy"
      fi
    fi
  done)
  if [ -n "$reg_problems" ]; then
    printf '%s\n' "$reg_problems" | sed 's/^/FAIL  /'; fail=1
  fi
fi

for p in "$ROOT"/projects/*/; do
  slug=$(basename "$p")
  [ "$slug" = "_template" ] && continue
  [ -f "$p/project.yaml" ] || { bad "$slug: no project.yaml"; continue; }
  if grep -q '{{' "$p/project.yaml"; then bad "$slug: project.yaml still has unfilled placeholders"; fi
  it=$(grep -E '^current_iteration:' "$p/project.yaml" 2>/dev/null | sed 's/.*: *//; s/"//g' || true)
  [ -n "$it" ] || { bad "$slug: no current_iteration"; continue; }
  f="$p/iterations/$it/iteration.yaml"
  [ -f "$f" ] || { bad "$slug: current_iteration $it has no $f"; continue; }
  if grep -q '{{' "$f"; then bad "$slug @ $it: iteration.yaml still has unfilled placeholders"; fi
  st=$(grep -E '^status:' "$f" | sed 's/.*: *//; s/[[:space:]]*#.*$//' || true)
  case "$st" in
    planned|survey|implement|experiment|analyze|conclude|completed) say "OK    $slug @ $it ($st)" ;;
    *) bad "$slug @ $it: status '$st' is not one of the seven loop states" ;;
  esac
  # The criterion must be fixed before the data are seen. Past 'survey' it is too late.
  # Read the value itself: the inline text and its continuation lines, never a comment.
  crit=$(awk -v sq="'" '
    /^success_criterion:/ {
      on = 1; v = $0; sub(/^success_criterion:[[:space:]]*/, "", v)
      if (v ~ /^#/ || v ~ /^[>|][-+0-9]*[[:space:]]*$/) v = ""
      sub(/[[:space:]]+#.*$/, "", v); out = v; next }
    on && /^[^[:space:]#]/ { exit }
    on && /^[[:space:]]*#/ { next }
    on { out = out $0 }
    END { gsub(/[[:space:]]/, "", out); gsub(/"/, "", out); gsub(sq, "", out); print out }' "$f")
  case "$st" in
    implement|experiment|analyze|conclude|completed)
      case "$crit" in
        '') bad "$slug @ $it: status is '$st' but success_criterion is empty — it should have been fixed before the data were seen" ;;
        *'{{'*) bad "$slug @ $it: status is '$st' but success_criterion is still the template placeholder" ;;
      esac ;;
  esac
  # Every recorded metric carries an evidence tier.
  for m in "$p"/iterations/*/metrics.yaml; do
    [ -f "$m" ] || continue
    problems=$(awk '
      /^[[:space:]]*#/ { next }
      /^[[:space:]]*-[[:space:]]*name:/ {
        if (n != "" && t == "") print "no tier: " n
        n = $0; sub(/.*name:[[:space:]]*/, "", n); t = ""; next }
      /^[[:space:]]+tier:/ {
        t = $0; sub(/.*tier:[[:space:]]*/, "", t); sub(/[[:space:]]+#.*$/, "", t)
        if (t !~ /^(benchmarked|consensus|single_study|inferred)$/) print "tier \"" t "\" is not one of benchmarked consensus single_study inferred: " n }
      END { if (n != "" && t == "") print "no tier: " n }' "$m")
    if [ -n "$problems" ]; then
      bad "${m#"$ROOT"/}:"
      printf '%s\n' "$problems" | sed 's/^/        /'
    fi
  done
done

[ "$fail" = "0" ] && { say "state OK"; exit 0; }
say "state has problems — fix them before trusting the assistant to resume"; exit 1
