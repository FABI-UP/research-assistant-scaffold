#!/usr/bin/env sh
# Run every step in order. DRY_RUN=1 to check wiring without writing anything.
set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${1:-}"
[ -n "$CONFIG" ] && [ ! -f "$CONFIG" ] && { echo "no such config: $CONFIG" >&2; exit 1; }
export REPO_ROOT
for step in "$REPO_ROOT"/src/steps/*.sh; do
  echo "==> $(basename "$step")"
  sh "$step" "$CONFIG"
done
echo "==> pipeline complete"
