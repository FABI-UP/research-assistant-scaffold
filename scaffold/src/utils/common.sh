#!/usr/bin/env sh
# Shared step utilities. POSIX sh — no bashisms, so it behaves the same on an old
# macOS /bin/sh, a Linux container and a login node. Source this at the top of every step.
#
# Contract for every step:
#   init_step  NN_name  <config.yaml>     # once, first
#   require_input  <path> [<path>...]     # predecessor outputs, checked before work
#   require_tool   <name> [<name>...]     # hard gate; dies loudly, never skips
#   emit  <path>                          # declare an output; refuses to write under DRY_RUN
#   end_step                              # once, last; records provenance for every output written
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
# One reader, on purpose. Two readers of one file disagree eventually, and the
# disagreement is silent (docs/08_pitfalls.md). This one reads a restricted subset
# of YAML: nested mappings of scalars, indented with spaces (any consistent width),
# `key: value`, quoted or plain values, comments. Anything else — tabs, list items,
# multi-line scalars, anchors, inconsistent indentation — is refused with the line
# number, because a line it misread would quietly fall back to a default.
# Booleans are normalised to true/false, and null or ~ to empty.
_YAML_PROG='
function fail(msg) { printf "%s:%d: %s\n", FILENAME, NR, msg > "/dev/stderr"; exit 2 }
BEGIN { d = 0; ind[0] = 0; parent = 0 }
{
  line = $0
  sub(/\r$/, "", line)
  if (line ~ /^[ ]*#/ || line ~ /^[ ]*$/) next
  if (line ~ /^[ ]*\t/) fail("tab in indentation; YAML allows spaces only")
  match(line, /^ */); ws = RLENGTH
  body = substr(line, ws + 1)
  if (body ~ /^-( |$)/) fail("list item; the config reader handles mappings of scalars only")
  if (body !~ /^[A-Za-z0-9_-]+:( |$)/) fail("not a `key: value` line")
  if (ws > ind[d]) {
    if (!parent) fail("indented under a key that already has a value")
    d++; ind[d] = ws
  } else {
    while (d > 0 && ind[d] > ws) d--
    if (ind[d] != ws) fail("indentation does not match any enclosing level")
  }
  k = body; sub(/:.*/, "", k)
  v = body; sub(/^[^:]*:[ ]*/, "", v)
  quoted = 0
  q = substr(v, 1, 1)
  if (q == "\"" || q == sq) {
    j = index(substr(v, 2), q)
    if (j == 0) fail("unterminated quoted value")
    rest = substr(v, j + 2); v = substr(v, 2, j - 1); quoted = 1
    sub(/^ +/, "", rest)
    if (rest != "" && substr(rest, 1, 1) != "#") fail("text after a quoted value")
  } else {
    if (v ~ /^#/) v = ""
    sub(/[ ]+#.*$/, "", v); sub(/[ ]+$/, "", v)
    if (v ~ /^[>|][-+0-9]*$/) fail("multi-line scalar; put the value on one line")
    if (v ~ /^[&*!]/) fail("anchors, aliases and tags are not supported")
  }
  path[d] = k
  full = path[0]
  for (i = 1; i <= d; i++) full = full "." path[i]
  parent = (v == "" && !quoted)
  if (want != "" && full == want && !parent) {
    if (!quoted) {
      lv = tolower(v)
      if (lv == "true" || lv == "yes" || lv == "on") v = "true"
      else if (lv == "false" || lv == "no" || lv == "off") v = "false"
      else if (lv == "null" || v == "~") v = ""
    }
    print v; exit 0
  }
}'

# _yaml <file> [dotted.key] — print the value, or with no key, check the whole file.
_yaml() { awk -v want="${2:-}" -v sq="'" "$_YAML_PROG" "$1"; }

# cfg <dotted.key> [default]
# Project config wins over repository defaults.
cfg() {
  _k="$1"; _default="${2:-}"
  _v=""
  if [ -n "${STEP_CONFIG:-}" ] && [ -f "$STEP_CONFIG" ]; then
    _v="$(_yaml "$STEP_CONFIG" "$_k")" || die "cannot read $STEP_CONFIG (see above)"
  fi
  if [ -z "$_v" ] && [ -n "${PIPELINE_CONFIG:-}" ] && [ -f "$PIPELINE_CONFIG" ]; then
    _v="$(_yaml "$PIPELINE_CONFIG" "$_k")" || die "cannot read $PIPELINE_CONFIG (see above)"
  fi
  if [ -z "$_v" ]; then _v="$_default"; fi
  printf '%s' "$_v"
}

# --- lifecycle ---------------------------------------------------------------
init_step() {
  STEP_NAME="$1"
  STEP_CONFIG="${2:-}"
  STEP_START="$(_ts)"
  if [ -n "$STEP_CONFIG" ]; then
    [ -f "$STEP_CONFIG" ] || die "config not found: $STEP_CONFIG"
    case "$STEP_CONFIG" in /*) ;; *) STEP_CONFIG="$(pwd)/$STEP_CONFIG" ;; esac
  fi
  : "${REPO_ROOT:=$(cd "$(dirname "$0")/../.." && pwd)}"
  export REPO_ROOT
  # Every path in the config is relative to the repository root, wherever the step
  # was started from. Otherwise a run from a subdirectory writes a second results/ there.
  cd "$REPO_ROOT" || die "cannot enter the repository root: $REPO_ROOT"
  : "${PIPELINE_CONFIG:=$REPO_ROOT/configs/pipeline.yaml}"
  export PIPELINE_CONFIG
  # Check each config file whole, here, in the step's own shell. A config read later
  # inside $( ) could only fail its subshell, and the step would carry on with defaults.
  for _c in "$PIPELINE_CONFIG" "$STEP_CONFIG"; do
    if [ -n "$_c" ] && [ -f "$_c" ]; then
      _yaml "$_c" >/dev/null || die "$_c uses YAML the config reader does not support (see above).
  Simplify it. Do not let it fall back to defaults."
    fi
  done
  if [ "$(cfg run.dry_run false)" = "true" ]; then DRY_RUN=1; fi
  if [ "$DRY_RUN" = "1" ]; then log "start (DRY RUN — writes nothing)"; else log "start"; fi
  log "seed=$(cfg run.seed 1) threads=$(cfg run.threads 1)"
}

end_step() {
  if [ -n "$STEP_OUTPUTS" ]; then
    log "outputs:"
    _prov="$(cfg paths.reports results/reports)/provenance.tsv"
    printf '%s\n' "$STEP_OUTPUTS" | while IFS= read -r o; do
      if [ -z "$o" ]; then continue; fi
      log "  $o"
      if [ "$DRY_RUN" != "1" ] && [ -f "$o" ]; then
        mkdir -p "$(dirname "$_prov")"
        if [ ! -f "$_prov" ]; then
          printf 'time\tstep\toutput\tchecksum\tseed\tconfig\n' > "$_prov"
        fi
        provenance_line "$o" >> "$_prov"
      fi
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

_isnum() {
  printf '%s' "$1" | grep -Eq '^[+-]?([0-9]+\.?[0-9]*|\.[0-9]+)([eE][+-]?[0-9]+)?$'
}

# quality_gate LABEL ACTUAL min|max THRESHOLD
# Assert a measured value before an expensive or irreversible step runs. Stopping
# here costs an hour; not stopping can cost the whole downstream analysis and,
# worse, produce a result that looks fine.
quality_gate() {
  _label="$1"; _actual="$2"; _dir="$3"; _thr="$4"
  case "$_dir" in
    min|max) ;;
    *) die "quality gate '$_label': direction must be min or max, not '$_dir'" ;;
  esac
  # Fails closed: only an explicit false turns the gates off.
  _enabled="$(cfg quality.enabled true)"
  if [ "$_enabled" = "false" ]; then
    log "quality gate '$_label' skipped (quality.enabled is false)"
    return 0
  fi
  if [ "$_enabled" != "true" ]; then
    warn "quality.enabled is '$_enabled', which is neither true nor false; the gate stays on"
  fi
  _isnum "$_actual" || die "quality gate '$_label': measured value '$_actual' is not a number.
  A measurement that failed is a failed gate, not a pass."
  _isnum "$_thr" || die "quality gate '$_label': threshold '$_thr' is not a number"
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

# --- provenance --------------------------------------------------------------
# checksum <path> — portable content fingerprint (POSIX cksum: CRC and size).
checksum() { cksum < "$1" | awk '{ print $1 "-" $2 }'; }

# provenance_line <output> — one row of results/reports/provenance.tsv.
# end_step calls it for every output a step wrote; the report step refuses to
# finish if a table has no row, or no longer matches its row.
provenance_line() {
  _pc="${STEP_CONFIG#"$REPO_ROOT"/}"
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$(_ts)" "$STEP_NAME" "$1" "$(checksum "$1")" \
    "$(cfg run.seed 1)" "${_pc:-<defaults only>}"
}
