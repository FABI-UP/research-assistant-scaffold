# Architecture — {{PROJECT_NAME}}

> Keep this file honest. If it describes a layout the code no longer has, it is worse than nothing:
> the assistant will believe it. Update it in the same commit as the change.

## Layout

```
AGENTS.md              Standing brief for the assistant. Canonical.
CLAUDE.md, GEMINI.md   Pointers to AGENTS.md, for vendor tooling.
configs/pipeline.yaml  Repository-wide defaults.
projects/
  registry.yaml        Which projects exist; exactly one active.
  <slug>/
    project.yaml       The standing question and the finish line.
    handover.md        The note the last session left for the next.
    config.yaml        Project overrides of the defaults.
    iterations/<NNN>/
      iteration.yaml   status = the program counter.
      literature.yaml  What was read.
      experiments.yaml What was run.
      metrics.yaml     What was measured, with evidence tiers.
      findings.md      What was learned.
src/
  steps/NN_name.{{STEP_EXT}}   One job each. See docs of the kit for the contract.
  utils/                        Shared helpers. The only place config is parsed.
scripts/
  run_pipeline.sh      Runs every step in order. DRY_RUN=1 to check wiring.
  validate_state.sh    Checks the state files are well-formed and consistent.
  check_conventions.sh Static checks: declared I/O, shell portability, no leaked identifiers.
templates/             Job submission template for {{SCHEDULER}}.
tests/smoke_test.sh    Must pass from a clean checkout.
results/               Generated. Not committed.
logs/                  Generated. Not committed.
```

## Settings for this project

| | |
|---|---|
| Step language | {{STEP_EXT}} |
| Environment | {{ENV_MANAGER}} |
| Compute | {{COMPUTE}} |
| Scheduler | {{SCHEDULER}} |

## Decisions

Record here anything a future reader would otherwise have to reconstruct: why a tool was chosen
over an obvious alternative, why a threshold is what it is, what was tried and abandoned. One line
each, dated. This section is usually the most valuable file in the repository after two years.

Format: `YYYY-MM-DD: the decision; the reason; the alternative rejected.`
