#!/usr/bin/env sh
# INPUTS:  results/tables/
# OUTPUTS: results/reports/99_run_manifest.tsv
# PURPOSE: Record what produced these results, so a future reader can re-examine them.
. "$(dirname "$0")/../utils/common.sh"
init_step "99_report" "${1:-}"

tables="$(cfg paths.tables results/tables)"
require_input "$tables"

out="$(cfg paths.reports results/reports)/99_run_manifest.tsv"
if emit "$out"; then
  {
    printf 'field\tvalue\n'
    printf 'generated\t%s\n' "$(_ts)"
    printf 'seed\t%s\n'      "$(cfg run.seed 1)"
    printf 'config\t%s\n'    "${STEP_CONFIG:-<defaults only>}"
    printf 'shell\t%s\n'     "$( (readlink /proc/$$/exe 2>/dev/null) || echo sh)"
    printf 'commit\t%s\n'    "$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo '<not a git repo>')"
    printf 'dirty\t%s\n'     "$(git -C "$REPO_ROOT" status --porcelain 2>/dev/null | head -c1 | grep -q . && echo yes || echo no)"
    for f in "$tables"/*; do [ -e "$f" ] || continue; printf 'table\t%s\n' "$f"; done
  } > "$out"
  log "manifest written"
fi
end_step

exit 0
