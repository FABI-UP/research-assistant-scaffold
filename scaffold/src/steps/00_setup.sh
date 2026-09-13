#!/usr/bin/env sh
# INPUTS:  (none)
# OUTPUTS: results/.initialised
# PURPOSE: Create the output tree and prove the contract works. No science here.
. "$(dirname "$0")/../utils/common.sh"
init_step "00_setup" "${1:-}"

for d in "$(cfg paths.tables results/tables)" "$(cfg paths.figures results/figures)" \
         "$(cfg paths.reports results/reports)" "$(cfg paths.logs logs)"; do
  if [ "$DRY_RUN" = "1" ]; then log "DRY RUN: would create $d"; else mkdir -p "$d"; fi
done

out="$(cfg paths.results results)/.initialised"
if ! skip_if_done "$out"; then
  if emit "$out"; then printf 'initialised %s\n' "$(_ts)" > "$out"; fi
fi
end_step

exit 0
