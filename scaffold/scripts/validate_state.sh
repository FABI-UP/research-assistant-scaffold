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

for p in "$ROOT"/projects/*/; do
  slug=$(basename "$p")
  [ "$slug" = "_template" ] && continue
  [ -f "$p/project.yaml" ] || bad "$slug: no project.yaml"
  it=$(grep -E '^current_iteration:' "$p/project.yaml" 2>/dev/null | sed 's/.*: *//; s/"//g' || true)
  [ -n "$it" ] || { bad "$slug: no current_iteration"; continue; }
  f="$p/iterations/$it/iteration.yaml"
  [ -f "$f" ] || { bad "$slug: current_iteration $it has no $f"; continue; }
  st=$(grep -E '^status:' "$f" | sed 's/.*: *//' || true)
  case "$st" in
    planned|survey|implement|experiment|analyze|conclude|completed) say "OK    $slug @ $it ($st)" ;;
    *) bad "$slug @ $it: status '$st' is not one of the seven loop states" ;;
  esac
  # The criterion must be fixed before the data are seen. Past 'survey' it is too late.
  case "$st" in
    implement|experiment|analyze|conclude|completed)
      crit=$(sed -n '/^success_criterion:/,/^[a-z_]*:/p' "$f" | sed '1d;$d' | tr -d ' \n')
      case "$crit" in
        ''|'{{ITERATION_CRITERION}}')
          bad "$slug @ $it: status is '$st' but success_criterion is empty — it should have been fixed before the data were seen" ;;
      esac ;;
  esac
  grep -q '{{' "$p/project.yaml" && bad "$slug: project.yaml still contains {{PLACEHOLDERS}}"
done

[ "$fail" = "0" ] && { say "state OK"; exit 0; }
say "state has problems — fix them before trusting the assistant to resume"; exit 1
