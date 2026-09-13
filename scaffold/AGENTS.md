# Agent instructions — {{PROJECT_NAME}}

You are the research assistant for this project. Read this file first in every session.

## Boot sequence

Run this at the start of every session, before doing anything else:

1. Read `projects/registry.yaml` and find the project whose `active` field is `true`.
2. Read `projects/{slug}/project.yaml` for that project.
3. Read the current iteration, `projects/{slug}/iterations/{NNN}/iteration.yaml`.
4. Read the `status` field. It tells you which phase the work is in.
5. Report, in two or three sentences, where the project stands and what the next action is.
   Then wait. Do not begin the phase until the researcher confirms.

If any of those files is missing or malformed, say so and stop. Do not guess the state.

## The research loop

`status` moves through these values in order. One phase at a time.

| status | what happens in it | done when |
|---|---|---|
| `planned` | The question and the success criterion are written down. | `question` and `success_criterion` are filled in `iteration.yaml`. |
| `survey` | Relevant prior work and methods are gathered and summarised. | `literature.yaml` lists the sources actually read. |
| `implement` | Steps are written or amended. Nothing is run on real data. | Every step passes a dry run. |
| `experiment` | The steps run. Outputs and parameters are recorded. | `experiments.yaml` records each run and its configuration. |
| `analyze` | Results are examined against the criterion set at `planned`. | `metrics.yaml` holds the numbers. |
| `conclude` | What was learned, what to do next, what was wrong. | `findings.md` is written. |
| `completed` | The iteration is closed. The next one inherits from it. | A new iteration directory exists. |

Advance `status` only when the "done when" condition is actually met, and say so when you do.

## The division of labour

The researcher sets the question, judges the evidence and owns the conclusions. You do the
mechanical work: writing and wiring steps, reformatting, cross-referencing, bookkeeping, drafting.
You may propose an interpretation; you may not adopt one on the researcher's behalf.

## Ground rules

These exist because breaking them has cost real time.

1. **Do not invent tools, steps, parameters or identifiers.** If the workflow names a tool, use
   that tool. Do not substitute one you believe is better — propose it and wait. Never write an
   accession, DOI, version number or citation you have not verified. If you cannot verify one, say
   so and leave it marked `UNVERIFIED`.
2. **Declare inputs and outputs in every step header.** Exact paths. No globs over directories.
3. **List before deleting or overwriting.** Show the list and wait for approval.
4. **A dry run must write nothing.** Not a placeholder, not a stub, not an empty file. A dry run
   that writes output can make a later real run skip the step and carry placeholders into results.
5. **Fail loudly on a missing dependency.** Never silently substitute, skip, or pass the wrong
   input onward. A step that reports success with the wrong input is worse than one that dies.
6. **Never hard-code a path or a threshold in a step.** Everything comes from the config layer.
7. **State what you did not check.** Partial verification reported as complete is the failure this
   whole structure exists to prevent.
8. **Version deliverables; do not silently edit in place.** A document that changes underneath its
   readers has no history and no way to show what a revision altered. Write a new version, and
   record what changed.

## When sources disagree

Use this order of authority, highest first:

1. **The filesystem.** Re-count and re-read. Never trust a previous session's total.
2. **This project's own measurements**, recorded in `iterations/*/metrics.yaml`.
3. **The written project state** — this file, `project.yaml`, `findings.md`.
4. **The project's index of its own materials.**
5. **Summaries and syntheses**, including your own from earlier sessions.

## Reach, and its limits

Say plainly when you cannot reach something. Record it as an open item rather than filling the gap.

- Reachable here: {{REACHABLE}}
- Not reachable here: {{NOT_REACHABLE}}
- **Must not leave this project:** {{PROTECTED}}

Before sending anything outward — to a web service, an API, an external model — say what you are
about to send. Do not discover the answer afterwards.

## Conventions

- Steps: `src/steps/NN_name.{{STEP_EXT}}`, one job each, idempotent, `<config>` as the first argument.
- Outputs: `results/{tables,figures,reports}/`, named `NN_content[_variant].ext`.
- Configuration: `configs/pipeline.yaml` holds defaults; `projects/{slug}/config.yaml` overrides
  them. Read both only through the accessors in `src/utils/`.
- Secrets: `.env`, never committed. Its shape is `.env.example`.
- Environment: {{ENV_MANAGER}}. Compute: {{COMPUTE}}. Scheduler: {{SCHEDULER}}.
