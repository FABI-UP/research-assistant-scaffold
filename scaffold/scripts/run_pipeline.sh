#!/usr/bin/env sh
# Run every step in order. DRY_RUN=1 to check wiring without writing anything.
# Runs from the repository root, wherever it is called from. A step whose extension
# the runner does not know stops the run; it is never skipped.
set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${1:-}"
if [ -n "$CONFIG" ]; then
  [ -f "$CONFIG" ] || { echo "no such config: $CONFIG" >&2; exit 1; }
  CONFIG="$(cd "$(dirname "$CONFIG")" && pwd)/$(basename "$CONFIG")"
fi
export REPO_ROOT
cd "$REPO_ROOT"
found=0
for step in src/steps/[0-9][0-9]_*; do
  if [ ! -f "$step" ]; then continue; fi
  found=1
  echo "==> $(basename "$step")"
  case "$step" in
    *.sh) sh "$step" "$CONFIG" ;;
    *.py) python3 "$step" "$CONFIG" ;;
    *.R)  Rscript "$step" "$CONFIG" ;;
    *)    echo "do not know how to run $step — add its extension to scripts/run_pipeline.sh" >&2
          exit 1 ;;
  esac
done
if [ "$found" = "0" ]; then echo "no steps found in src/steps/" >&2; exit 1; fi
echo "==> pipeline complete"
