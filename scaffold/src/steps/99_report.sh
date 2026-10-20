#!/usr/bin/env sh
# INPUTS:  results/reports/provenance.tsv, and every table under results/tables
# OUTPUTS: results/reports/99_run_manifest.tsv
# PURPOSE: Record what produced these results, and refuse to finish if any table lacks provenance.
# Regenerated on every run by design: it describes the latest run, not the first.
. "$(dirname "$0")/../utils/common.sh"
init_step "99_report" "${1:-}"

tables="$(cfg paths.tables results/tables)"
reports="$(cfg paths.reports results/reports)"
prov="$reports/provenance.tsv"
require_input "$prov"
tools="$(cfg provenance.tools '')"
# shellcheck disable=SC2086  # a space-separated list, split on purpose
if [ -n "$tools" ]; then require_tool $tools; fi

cfgrel="${STEP_CONFIG#"$REPO_ROOT"/}"
out="$reports/99_run_manifest.tsv"
if emit "$out"; then
  # The guard. Every table must have been recorded by the step that wrote it, and must
  # still be the file that was recorded. A table edited by hand, or written by anything
  # that bypassed the step contract, stops the report here.
  problems=""
  for f in "$tables"/*; do
    if [ ! -f "$f" ]; then continue; fi
    want=$(awk -F'\t' -v p="$f" '$3 == p { c = $4 } END { print c }' "$prov")
    if [ -z "$want" ]; then
      problems="$problems
    no provenance: $f"
    elif [ "$want" != "$(checksum "$f")" ]; then
      problems="$problems
    changed since its step recorded it: $f"
    fi
  done
  if [ -n "$problems" ]; then
    die "provenance guard failed:$problems
  Re-run the step that makes each file (FORCE=1), or remove the file. Do not edit results by hand."
  fi
  {
    printf 'field\tvalue\n'
    printf 'generated\t%s\n' "$(_ts)"
    printf 'seed\t%s\n'      "$(cfg run.seed 1)"
    printf 'threads\t%s\n'   "$(cfg run.threads 1)"
    printf 'config\t%s\n'    "${cfgrel:-<defaults only>}"
    printf 'config_checksum\t%s %s\n' "configs/pipeline.yaml" "$(checksum "$PIPELINE_CONFIG")"
    if [ -n "$STEP_CONFIG" ]; then
      printf 'config_checksum\t%s %s\n' "$cfgrel" "$(checksum "$STEP_CONFIG")"
    fi
    printf 'system\t%s\n'    "$(uname -sr 2>/dev/null || echo unknown)"
    if git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
      printf 'commit\t%s\n' "$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo '<no commits yet>')"
      printf 'dirty\t%s\n'  "$(git -C "$REPO_ROOT" status --porcelain | head -c1 | grep -q . && echo yes || echo no)"
    else
      printf 'commit\t<not a git repo>\n'
    fi
    for t in $tools; do
      printf 'tool\t%s %s\n' "$t" "$( ("$t" --version 2>&1 || true) | head -1)"
    done
    for f in "$tables"/*; do
      if [ -f "$f" ]; then printf 'table\t%s %s\n' "$f" "$(checksum "$f")"; fi
    done
  } > "$out"
  log "manifest written; every table has provenance"
fi
end_step

exit 0
