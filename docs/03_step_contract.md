# 3. The step contract

Every analysis step obeys the same shape. The uniformity is what lets an assistant write a new step
without being re-taught, and lets a reader audit one without reading all of them.

## The shape

```sh
#!/usr/bin/env sh
# INPUTS:  results/tables/03_something.tsv      <- exact paths, no globs over directories
# OUTPUTS: results/tables/04_result.tsv
# PURPOSE: one line
. "$(dirname "$0")/../utils/common.sh"
init_step "04_name" "${1:-}"

require_input "$(cfg paths.tables results/tables)/03_something.tsv"
require_tool  some_tool

out="$(cfg paths.tables results/tables)/04_result.tsv"     # always give cfg a default
if skip_if_done "$out"; then end_step; exit 0; fi

if emit "$out"; then
    ... the actual work ...
fi
end_step
exit 0
```

## The seven obligations

1. **One job.** If a step does two things, it is two steps. You cannot re-run half a step.
2. **Declared I/O in the header.** Exact paths. A glob over a directory hides what a step consumed
   and makes the dependency graph unknowable.
3. **Everything from config.** No path, threshold, or parameter written into the body. If it might
   ever differ between projects, it is configuration.
4. **Check predecessors.** `require_input` before doing work. Fail rather than improvise.
5. **Hard gates only.** `require_tool` dies. There is no soft version on purpose: a step that
   detects a missing tool, records `SKIPPED`, and passes its input onward produces a *wrong answer*
   that looks like a result. A crash is recoverable; a plausible wrong number may not be.
6. **A dry run writes nothing.** Not a stub, not a placeholder, not an empty file. `emit` enforces
   this. See [pitfalls](08_pitfalls.md#dry-run-poisoning) for why this one matters more than it looks.
7. **Idempotent.** Running twice gives the same result as running once. `skip_if_done` gives you
   this for free; `FORCE=1` overrides it. The report step is the one exception: it describes the
   latest run, so it is regenerated every time.

Give `cfg` a default for every path. Without one, a missing key becomes an empty string and
`"$(cfg paths.tables)/04_result.tsv"` becomes `/04_result.tsv`, at the root of the filesystem.

## The utilities

`src/utils/common.sh`, POSIX shell, no dependencies.

| Function | Does |
|---|---|
| `init_step NAME CONFIG` | Sets up logging, moves to the repository root, checks every config file can be read, detects dry-run mode |
| `cfg KEY [DEFAULT]` | Reads a dotted key; project config wins over repository defaults |
| `require_input PATH...` | Fatal if missing in a real run; reports and continues in a dry run |
| `require_tool NAME...` | Fatal if not on `PATH`. Always fatal |
| `emit PATH` | Declares an output and makes its directory; returns non-zero under dry run |
| `skip_if_done PATH` | Idempotency check |
| `quality_gate LABEL ACTUAL min\|max THRESHOLD` | Asserts a measured value before an expensive or irreversible step; fatal on failure, and fatal on a measurement that is not a number |
| `end_step` | Logs the outputs and appends a provenance row for each one written |
| `log` / `warn` / `die` | Timestamped, step-tagged, to stderr |
| `provenance_line PATH` | One row of `results/reports/provenance.tsv`: time, step, output, checksum, seed, config |

### Quality gates

Put one before anything expensive or irreversible:

```sh
quality_gate "input completeness" "$measured" min 0.95
```

Stopping here costs an hour. Not stopping can cost the whole downstream analysis, and — worse —
produce something that looks like a result. If a gate fails, fix the input or change the threshold
deliberately in the config. Do not comment out the gate.

Gates fail closed. An empty or non-numeric measurement fails the gate, because a measurement that
did not happen is not a pass. Only `quality.enabled: false` turns gates off; any other value
leaves them on, with a warning.

### Configuration

There is one config reader, in `common.sh`, and it reads a deliberately small part of YAML: nested
mappings of scalars, indented with spaces. Anything else — tabs, lists, multi-line values, anchors —
stops the step with the file and line number. That is on purpose: a reader that guesses, or skips
what it cannot read, hands the step a default without saying so.

### Enforced, not just written

`scripts/check_conventions.sh` turns five conventions into checks: every step declares exact
`INPUTS`, `OUTPUTS` and `PURPOSE` with no directory globs; POSIX shell scripts contain no bashisms;
no tracked file carries an email address, a home path or a credential-shaped string; `.env`,
`results/` and `logs/` are ignored and `.env` is never tracked; and, once the repository is
configured, no placeholders are left. Run it before every commit. `tests/smoke_test.sh` runs it too.

If your steps are in Python or R, write the same seven obligations as a module in that language and
keep the function names, including the provenance row `end_step` writes. The contract is the point,
not the shell. `scripts/run_pipeline.sh` runs `.sh`, `.py` and `.R` steps and stops on any other
extension rather than skipping it.

## Naming outputs

`NN_content[_variant].ext` in `results/{tables,figures,reports}/`. The number ties an output to the
step that made it, which is the first question anyone asks of a file six months later.

Next: [4. The state model](04_state_model.md)
