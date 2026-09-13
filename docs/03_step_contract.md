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

require_input "$(cfg paths.tables)/03_something.tsv"
require_tool  some_tool

out="$(cfg paths.tables)/04_result.tsv"
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
   this for free; `FORCE=1` overrides it.

## The utilities

`src/utils/common.sh`, POSIX shell, no dependencies.

| Function | Does |
|---|---|
| `init_step NAME CONFIG` | Sets up logging, resolves config layering, detects dry-run mode |
| `cfg KEY [DEFAULT]` | Reads a dotted key; project config wins over repository defaults |
| `require_input PATH...` | Fatal if missing in a real run; reports and continues in a dry run |
| `require_tool NAME...` | Fatal if not on `PATH`. Always fatal |
| `emit PATH` | Declares an output and makes its directory; returns non-zero under dry run |
| `skip_if_done PATH` | Idempotency check |
| `quality_gate LABEL ACTUAL min\|max THRESHOLD` | Asserts a measured value before an expensive or irreversible step; fatal on failure |
| `log` / `warn` / `die` | Timestamped, step-tagged, to stderr |
| `provenance_line` | One manifest row |

### Quality gates

Put one before anything expensive or irreversible:

```sh
quality_gate "input completeness" "$measured" min 0.95
```

Stopping here costs an hour. Not stopping can cost the whole downstream analysis, and — worse —
produce something that looks like a result. If a gate fails, fix the input or change the threshold
deliberately in the config. Do not comment out the gate.

### Enforced, not just written

`scripts/check_conventions.sh` turns four of these conventions into checks: every step declares
exact `INPUTS`, `OUTPUTS` and `PURPOSE` with no directory globs; POSIX shell scripts contain no
bashisms; no tracked file carries an email address, a home path or a credential-shaped string; and
`.env` is never tracked. Run it before every commit. `tests/smoke_test.sh` runs it too.

If your steps are in Python or R, write the same seven obligations as a module in that language and
keep the function names. The contract is the point, not the shell.

## Naming outputs

`NN_content[_variant].ext` in `results/{tables,figures,reports}/`. The number ties an output to the
step that made it, which is the first question anyone asks of a file six months later.

Next: [4. The state model](04_state_model.md)
