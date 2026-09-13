#!/usr/bin/env sh
# Shared step utilities. POSIX sh — no bashisms, so it behaves the same on an old
# macOS /bin/sh, a Linux container and a login node. Source this at the top of every step.
#
# Contract for every step:
#   init_step  NN_name  <config.yaml>     # once, first
#   require_input  <path> [<path>...]     # predecessor outputs, checked before work
#   require_tool   <name> [<name>...]     # hard gate; dies loudly, never skips
#   emit  <path>                          # declare an output; refuses to write under DRY_RUN
#   end_step                              # once, last
#
# There is deliberately no soft gate. A step that reports success after silently
# skipping its real work hands the wrong answer onward, which is worse than a crash.

set -eu

STEP_NAME=""; STEP_CONFIG=""; STEP_START=""; STEP_OUTPUTS=""
DRY_RUN="${DRY_RUN:-0}"

_ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }
log()  { printf '%s [%s] %s\n' "$(_ts)" "${STEP_NAME:-init}" "$*" >&2; }
die()  { printf '%s [%s] FATAL: %s\n' "$(_ts)" "${STEP_NAME:-init}" "$*" >&2; exit 1; }
warn() { printf '%s [%s] WARN: %s\n' "$(_ts)" "${STEP_NAME:-init}" "$*" >&2; }

# --- configuration -----------------------------------------------------------
# Reads a dotted key from a restricted YAML subset: two-space indentation,
# `key: value`, no lists, no anchors, no multi-line scalars. That is all the
# scaffold's own config uses. If you outgrow it, install PyYAML and this switches
# to it automatically.
_yaml_get() {
  _f="$1"; _key="$2"
  [ -f "$_f" ] || { printf ''; return 0; }
  # Two readers are used depending on what is installed, so they MUST agree
  # exactly. A YAML library returns Python objects: True, False, None. Printed
  # raw those become "True", "False", "None", which no shell comparison expects
  # and which the fallback reader would never produce. Normalise them.
  # SCAFFOLD_YAML_READER=awk forces the fallback; the smoke test uses it to check
  # the two readers still agree.
  if [ "${SCAFFOLD_YAML_READER:-auto}" != "awk" ] \
     && command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1; then
    python3 - "$_f" "$_key" <<'YAMLREADER'
import sys, yaml
doc = yaml.safe_load(open(sys.argv[1])) or {}
cur = doc
for part in sys.argv[2].split('.'):
    if isinstance(cur, dict) and part in cur:
        cur = cur[part]
    else:
        print(''); sys.exit(0)
if cur is None:    print('')
elif cur is True:  print('true')
elif cur is False: print('false')
else:              print(cur)
YAMLREADER
    return 0
  fi
  awk -v key="$_key" '
    function depth(l,  s){ s=match(l, /[^ ]/); return (s-1)/2 }
    /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
    {
      d = depth($0)
      line = $0; sub(/^[ ]+/, "", line)
      k = line; sub(/:.*/, "", k)
      v = line; sub(/^[^:]*:[ ]?/, "", v)
      path[d] = k
      for (i = d+1; i <= 16; i++) path[i] = ""
      full = path[0]
      for (i = 1; i <= d; i++) full = full "." path[i]
      if (full == key && v != "") {
        gsub(/^["'"'"']|["'"'"']$/, "", v)
        sub(/[ ]+#.*$/, "", v)
        print v; exit
      }
    }' "$_f"
}

# cfg <dotted.key> [default]
# Project config wins over repository defaults.
cfg() {
  _k="$1"; _default="${2:-}"
  _v=""
  [ -n "${STEP_CONFIG:-}" ] && _v="$(_yaml_get "$STEP_CONFIG" "$_k")"
  if [ -z "$_v" ] && [ -n "${PIPELINE_CONFIG:-}" ]; then
    _v="$(_yaml_get "$PIPELINE_CONFIG" "$_k")"
  fi
  [ -z "$_v" ] && _v="$_default"
  printf '%s' "$_v"
}

# --- lifecycle ---------------------------------------------------------------
init_step() {
  STEP_NAME="$1"
  STEP_CONFIG="${2:-}"
  STEP_START="$(_ts)"
  [ -n "$STEP_CONFIG" ] && [ ! -f "$STEP_CONFIG" ] && die "config not found: $STEP_CONFIG"
  : "${REPO_ROOT:=$(cd "$(dirname "$0")/../.." && pwd)}"
  export REPO_ROOT
  : "${PIPELINE_CONFIG:=$REPO_ROOT/configs/pipeline.yaml}"
  export PIPELINE_CONFIG
  if [ "$(cfg run.dry_run false)" = "true" ]; then DRY_RUN=1; fi
  if [ "$DRY_RUN" = "1" ]; then log "start (DRY RUN — writes nothing)"; else log "start"; fi
  log "seed=$(cfg run.seed 1) threads=$(cfg run.threads 1)"
}

end_step() {
  if [ -n "$STEP_OUTPUTS" ]; then
    log "outputs:"
    printf '%s\n' "$STEP_OUTPUTS" | while IFS= read -r o; do
      if [ -n "$o" ]; then log "  $o"; fi
    done
  fi
  log "done (started $STEP_START)"
}

# --- gates -------------------------------------------------------------------
# A dry run is a wiring check: predecessors have written nothing, so a missing input
# is expected and is reported rather than fatal. In a real run it is always fatal.
require_input() {
  _missing=""
  for _p in "$@"; do
    if [ ! -e "$_p" ]; then _missing="$_missing $_p"; fi
  done
  if [ -z "$_missing" ]; then log "inputs present: $*"; return 0; fi
  if [ "$DRY_RUN" = "1" ]; then
    log "DRY RUN: input(s) not present yet, expected from a predecessor:$_missing"
    return 0
  fi
  die "required input missing:$_missing
  A predecessor step did not produce it, or produced it somewhere else.
  Fix the predecessor. Do not create a placeholder."
}

require_tool() {
  for _t in "$@"; do
    command -v "$_t" >/dev/null 2>&1 || die "required tool not on PATH: $_t
  This is a hard gate on purpose. Install it, or change the step — do not skip it."
  done
}

# emit <path>  — declare and prepare an output. Refuses to write under a dry run.
emit() {
  _p="$1"
  STEP_OUTPUTS="$STEP_OUTPUTS
$_p"
  if [ "$DRY_RUN" = "1" ]; then
    log "DRY RUN: would write $_p (nothing written)"
    return 1
  fi
  mkdir -p "$(dirname "$_p")"
  return 0
}

# skip_if_done <path> — idempotency. Re-running a completed step is a no-op.
skip_if_done() {
  if [ "${FORCE:-0}" != "1" ] && [ -e "$1" ]; then
    log "already done, skipping: $1  (FORCE=1 to redo)"
    return 0
  fi
  return 1
}

# quality_gate LABEL ACTUAL min|max THRESHOLD
# Assert a measured value before an expensive or irreversible step runs. Stopping
# here costs an hour; not stopping can cost the whole downstream analysis and,
# worse, produce a result that looks fine.
quality_gate() {
  _label="$1"; _actual="$2"; _dir="$3"; _thr="$4"
  if [ "$(cfg quality.enabled true)" != "true" ]; then
    log "quality gate '$_label' skipped (quality.enabled is false)"
    return 0
  fi
  _pass=$(awk -v a="$_actual" -v t="$_thr" -v d="$_dir" \
    'BEGIN { print (d == "min" ? (a+0 >= t+0) : (a+0 <= t+0)) ? "1" : "0" }')
  if [ "$_pass" = "1" ]; then
    log "quality gate '$_label' passed ($_actual $_dir $_thr)"
    return 0
  fi
  die "quality gate '$_label' FAILED: measured $_actual, required $_dir $_thr
  Nothing downstream of this point can be trusted. Fix the input or change the
  threshold deliberately in the config — do not comment out the gate."
}

# provenance_line — one line for the run manifest. Call it from your report step.
provenance_line() {
  printf '%s\t%s\t%s\t%s\n' "$(_ts)" "${STEP_NAME}" "seed=$(cfg run.seed 1)" "$*"
}
