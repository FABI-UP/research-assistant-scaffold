# 7. Adapting it to your setting

The scaffold ships neutral. Five things are meant to change.

## Language

Steps are shell in the kit because shell needs nothing installed. If your work is in Python or R,
port `src/utils/common.sh` to a module in that language, keeping the function names and the seven
obligations from [the step contract](03_step_contract.md). Orchestration usually stays in shell
even when steps do not, because it has to run before anything is installed.

Mixed languages are fine, and common. Keep one utility module per language rather than one that
shells out to another — two readers of the same configuration will disagree eventually, and the
disagreement will be silent.

## Environment

conda, venv, renv, containers, or nothing. Whichever you choose, pin it and commit the manifest.
The question a future reader asks is not "what did you use" but "what exact versions", and only a
committed lockfile answers that.

## Compute and scheduler

`templates/job.scheduler.template` carries directive blocks for SLURM, PBS and SGE. Keep yours,
delete the rest. If you have no scheduler, delete all three and run it as a script — "no scheduler"
is a supported configuration, not a missing one.

On a shared host with no queue, the budget is social rather than enforced. Write the number into
`AGENTS.md`.

## Orchestration

Three steps do not need a workflow engine; the included runner is enough. At perhaps a dozen steps
with branching, a real engine earns its place. Introduce it as a layer *above* the step contract,
not instead of it — steps that remain independently runnable stay debuggable.

## The instruction file

`AGENTS.md` is canonical. Vendor-specific filenames should be one-line pointers to it, so that the
same project works with whichever assistant you or a collaborator happen to use, and so that
changing tools does not mean rewriting your standing brief.

## What not to change

The state model, the loop, and the step contract. Not because they are perfect, but because their
value is that they are the same everywhere. A scaffold customised per project is a bespoke setup,
which is the thing this kit exists to stop you building again.

Next: [8. Pitfalls](08_pitfalls.md)
