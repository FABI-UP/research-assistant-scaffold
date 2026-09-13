#!/usr/bin/env sh
# INPUTS:  results/.initialised
# OUTPUTS: results/tables/01_example.tsv
# PURPOSE: Show the shape of a real step. Replace the marked block with your work.
. "$(dirname "$0")/../utils/common.sh"
init_step "01_example" "${1:-}"

require_input "$(cfg paths.results results)/.initialised"
# require_tool your_tool          # uncomment for each external tool this step needs

out="$(cfg paths.tables results/tables)/01_example.tsv"
if skip_if_done "$out"; then end_step; exit 0; fi

if emit "$out"; then
  # ---- replace everything between these markers ---------------------------
  printf 'metric\tvalue\tevidence_tier\n' >  "$out"
  printf 'placeholder\t0\tinferred\n'     >> "$out"
  # -------------------------------------------------------------------------
  log "wrote $(wc -l < "$out") lines"
fi
end_step

exit 0
