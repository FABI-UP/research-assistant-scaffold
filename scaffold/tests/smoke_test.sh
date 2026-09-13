#!/usr/bin/env sh
# Runs the whole chain twice — once dry, once real — in a throwaway directory.
# It must pass from a clean checkout with nothing installed but a POSIX shell.
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
pass=0; fail=0
ok()   { printf '  PASS  %s\n' "$*"; pass=$((pass+1)); }
no()   { printf '  FAIL  %s\n' "$*"; fail=$((fail+1)); }

cp -R "$ROOT"/src "$ROOT"/configs "$ROOT"/scripts "$WORK"/
cd "$WORK"

printf 'smoke test\n'
printf -- '--- 1. dry run writes nothing ---\n'
DRY_RUN=1 sh scripts/run_pipeline.sh >/dev/null 2>&1 || no "dry run exited non-zero"
if [ -d results ] && find results -type f | grep -q .; then
  no "dry run created files — this is the bug that makes a later real run skip steps"
else
  ok "dry run wrote nothing"
fi

printf -- '--- 2. real run produces declared outputs ---\n'
sh scripts/run_pipeline.sh >/dev/null 2>&1 || no "real run exited non-zero"
[ -f results/.initialised ]                 && ok "00_setup output"   || no "00_setup output missing"
[ -f results/tables/01_example.tsv ]        && ok "01_example output" || no "01_example output missing"
[ -f results/reports/99_run_manifest.tsv ]  && ok "99_report output"  || no "99_report output missing"

printf -- '--- 3. steps are idempotent ---\n'
before="$(cat results/tables/01_example.tsv)"
sh scripts/run_pipeline.sh >/dev/null 2>&1
[ "$before" = "$(cat results/tables/01_example.tsv)" ] && ok "re-run did not change output" || no "re-run changed output"

printf -- '--- 4. a missing input fails loudly ---\n'
rm -f results/.initialised
if sh src/steps/01_example.sh >/dev/null 2>&1; then
  no "01_example succeeded without its input — the gate is not working"
else
  ok "missing input aborted the step"
fi

printf -- '--- 5. config layering ---\n'
mkdir -p proj && printf 'run:\n  seed: 4242\n' > proj/config.yaml
if sh src/steps/00_setup.sh proj/config.yaml 2>&1 | grep -q 'seed=4242'; then
  ok "project config overrides repository defaults"
else
  no "project config did not override defaults"
fi

printf -- '--- 6. the two config readers agree ---\n'
agree=1
for k in run.seed run.threads run.dry_run quality.enabled decisions.default_mode paths.tables; do
  a=$( . src/utils/common.sh; PIPELINE_CONFIG=configs/pipeline.yaml; cfg "$k" )
  b=$( SCAFFOLD_YAML_READER=awk; export SCAFFOLD_YAML_READER; . src/utils/common.sh; PIPELINE_CONFIG=configs/pipeline.yaml; cfg "$k" )
  if [ "$a" != "$b" ]; then printf '    %s: library=[%s] fallback=[%s]\n' "$k" "$a" "$b"; agree=0; fi
done
if [ "$agree" = "1" ]; then ok "library and fallback readers return identical values"; else no "the two config readers disagree"; fi

printf -- '--- 7. quality gate stops the run ---\n'
if ( . src/utils/common.sh; init_step t configs/pipeline.yaml >/dev/null 2>&1; quality_gate demo 1 min 10 ) >/dev/null 2>&1; then
  no "quality gate passed a failing assertion"
else
  ok "quality gate aborted on a failing assertion"
fi

printf -- '--- 8. conventions ---\n'
if sh "$ROOT/scripts/check_conventions.sh" >/dev/null 2>&1; then ok "convention checks pass"; else no "convention checks failed"; fi

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" = "0" ] || exit 1
