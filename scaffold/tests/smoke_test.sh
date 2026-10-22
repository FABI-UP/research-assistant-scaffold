#!/usr/bin/env sh
# Runs the whole chain — dry, then real — in a throwaway directory, then checks the
# gates, the config reader, provenance, the state validator and the conventions.
# It must pass from a clean checkout with nothing installed but a POSIX shell.
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
WORK2="$(mktemp -d)"
trap 'rm -rf "$WORK" "$WORK2"' EXIT
pass=0; fail=0
ok()   { printf '  PASS  %s\n' "$*"; pass=$((pass+1)); }
no()   { printf '  FAIL  %s\n' "$*"; fail=$((fail+1)); }
# Fills every placeholder in a file. Portable: BSD and GNU sed disagree about -i.
fill() { for _f in "$@"; do sed 's/{{[A-Z_]*}}/filled/g' "$_f" > "$_f.tmp" && mv "$_f.tmp" "$_f"; done; }

cp -R "$ROOT"/src "$ROOT"/configs "$ROOT"/scripts "$ROOT"/projects "$WORK"/
cd "$WORK"
REPO_ROOT="$WORK"; export REPO_ROOT

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
sh scripts/run_pipeline.sh >/dev/null 2>&1 || no "re-run exited non-zero"
[ "$before" = "$(cat results/tables/01_example.tsv)" ] && ok "re-run did not change output" || no "re-run changed output"

printf -- '--- 4. provenance guard ---\n'
if grep -q '01_example.tsv' results/reports/provenance.tsv 2>/dev/null; then
  ok "end_step recorded provenance for the table it wrote"
else
  no "no provenance row for results/tables/01_example.tsv"
fi
printf 'edited by hand\n' >> results/tables/01_example.tsv
if sh src/steps/99_report.sh >/dev/null 2>&1; then no "report accepted a table edited after its step ran"
else ok "report refused a table edited after its step ran"; fi
FORCE=1 sh src/steps/01_example.sh >/dev/null 2>&1
printf 'x\n' > results/tables/02_stray.tsv
if sh src/steps/99_report.sh >/dev/null 2>&1; then no "report accepted a table no step recorded"
else ok "report refused a table no step recorded"; fi
rm -f results/tables/02_stray.tsv
sh src/steps/99_report.sh >/dev/null 2>&1 && ok "report passes once every table has provenance" \
  || no "report failed with every table recorded"

printf -- '--- 5. a missing input fails loudly ---\n'
rm -f results/.initialised
if sh src/steps/01_example.sh >/dev/null 2>&1; then
  no "01_example succeeded without its input — the gate is not working"
else
  ok "missing input aborted the step"
fi

printf -- '--- 6. config layering and the config reader ---\n'
mkdir -p proj
printf 'run:\n  seed: 4242\n' > proj/c2.yaml
printf 'run:\n    seed: 4343\n' > proj/c4.yaml
printf 'run:\n  seed: "77" # a comment\n' > proj/cq.yaml
printf 'run:\n\tseed: 9\n' > proj/ctab.yaml
printf 'run:\n  seed: [1, 2\n  - 3\n' > proj/cbad.yaml
sh src/steps/00_setup.sh proj/c2.yaml 2>&1 | grep -q 'seed=4242 ' \
  && ok "project config overrides repository defaults" || no "project config did not override defaults"
sh src/steps/00_setup.sh proj/c4.yaml 2>&1 | grep -q 'seed=4343 ' \
  && ok "four-space indentation is read, not silently defaulted" || no "four-space indentation fell back to a default"
sh src/steps/00_setup.sh proj/cq.yaml 2>&1 | grep -q 'seed=77 ' \
  && ok "a quoted value with a trailing comment is read exactly" || no "a quoted value with a comment was misread"
if sh src/steps/00_setup.sh proj/ctab.yaml >/dev/null 2>&1; then no "a tab-indented config was accepted"
else ok "a tab-indented config stops the step"; fi
if sh src/steps/00_setup.sh proj/cbad.yaml >/dev/null 2>&1; then no "unsupported YAML was accepted"
else ok "unsupported YAML stops the step instead of falling back to defaults"; fi

printf -- '--- 7. quality gates fail closed ---\n'
gate() { ( . src/utils/common.sh; init_step t "$1" >/dev/null 2>&1; quality_gate demo "$2" "$3" "$4" ) >/dev/null 2>&1; }
if gate configs/pipeline.yaml 1 min 10; then no "quality gate passed a failing assertion"
else ok "quality gate aborted on a failing assertion"; fi
if gate configs/pipeline.yaml "" max 0.05; then no "quality gate passed an empty measurement"
else ok "quality gate aborted on an empty measurement"; fi
printf 'quality:\n  enabled: maybe\n' > proj/cq2.yaml
if gate proj/cq2.yaml 1 min 10; then no "an unrecognised quality.enabled switched the gate off"
else ok "only an explicit false switches the gate off"; fi

printf -- '--- 8. the runner ---\n'
rm -rf results
mkdir -p elsewhere
(cd elsewhere && sh ../scripts/run_pipeline.sh >/dev/null 2>&1) || no "run from a subdirectory exited non-zero"
if [ -d elsewhere/results ]; then no "a run from a subdirectory wrote results/ there"
elif [ -f results/tables/01_example.tsv ]; then ok "a run from any directory writes to the repository root"
else no "a run from a subdirectory produced no output"; fi
printf 'echo hi\n' > src/steps/50_unknown.xyz
if sh scripts/run_pipeline.sh >/dev/null 2>&1; then no "the runner skipped a step it cannot run"
else ok "the runner stops on a step it does not know how to run"; fi
rm -f src/steps/50_unknown.xyz

printf -- '--- 9. the state validator ---\n'
d=projects/demo; it=$d/iterations/001/iteration.yaml
mkdir -p "$d/iterations/001"
printf 'schema_version: 1\nslug: demo\ntitle: Demo\ncreated: 2026-01-01\nquestion: >-\n  Q\nsuccess_criterion: >-\n  C\ncurrent_iteration: "001"\n' > "$d/project.yaml"
printf 'schema_version: 1\nprojects:\n  - slug: demo\n    title: Demo\n    active: true\n' > projects/registry.yaml
tmpl=projects/_template/iterations/001/iteration.yaml
sed 's/^status: planned/status: analyze/' "$tmpl" > "$it"
if sh scripts/validate_state.sh >/dev/null 2>&1; then no "an iteration with unfilled placeholders passed"
else ok "an iteration with unfilled placeholders fails"; fi
sed -e 's/^status: planned/status: analyze/' -e '/ITERATION_CRITERION/d' -e 's/{{[A-Z_]*}}/filled/g' "$tmpl" > "$it"
if sh scripts/validate_state.sh >/dev/null 2>&1; then no "status past survey with an empty success_criterion passed"
else ok "status past survey with an empty success_criterion fails"; fi
sed -e 's/^status: planned/status: analyze/' -e 's/{{[A-Z_]*}}/filled/g' "$tmpl" > "$it"
sh scripts/validate_state.sh >/dev/null 2>&1 && ok "a complete state passes" || no "a complete state failed"
printf '    current_iteration: "002"\n' >> projects/registry.yaml
if sh scripts/validate_state.sh >/dev/null 2>&1; then no "registry and project.yaml disagreeing about the iteration passed"
else ok "registry and project.yaml disagreeing about the iteration fails"; fi
printf 'schema_version: 1\nprojects:\n  - slug: demo\n    title: Demo\n    active: true\n' > projects/registry.yaml
printf 'metrics:\n  - name: a\n    value: 1\n    tier: inferred\n  - name: b\n    value: 2\n' > "$d/iterations/001/metrics.yaml"
if sh scripts/validate_state.sh >/dev/null 2>&1; then no "a metric without an evidence tier passed"
else ok "a metric without an evidence tier fails"; fi

printf -- '--- 10. conventions ---\n'
if sh "$ROOT/scripts/check_conventions.sh" >/dev/null 2>&1; then ok "convention checks pass"; else no "convention checks failed"; fi
# The same checks on a configured copy: placeholders filled, marker deleted.
for x in AGENTS.md CLAUDE.md GEMINI.md .gitignore .env.example docs src configs scripts templates tests; do
  if [ -e "$ROOT/$x" ]; then cp -R "$ROOT/$x" "$WORK2/"; fi
done
mkdir -p "$WORK2/projects" && cp -R "$ROOT/projects/_template" "$ROOT/projects/registry.yaml" "$WORK2/projects/"
fill "$WORK2/AGENTS.md" "$WORK2/docs/architecture.md"
if sh "$WORK2/scripts/check_conventions.sh" >/dev/null 2>&1; then ok "a configured copy passes the convention checks"
else no "a configured copy fails the convention checks"; fi
printf 'note: {{%s}}\n' FORGOTTEN > "$WORK2/docs/extra.md"
if sh "$WORK2/scripts/check_conventions.sh" >/dev/null 2>&1; then no "a leftover placeholder passed in a configured copy"
else ok "a leftover placeholder fails in a configured copy"; fi

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" = "0" ] || exit 1
