# 2. Setup guide

An afternoon, by hand. Less if you let the skill do it — see
[`skills/research-assistant-setup/SKILL.md`](../skills/research-assistant-setup/SKILL.md).

## Before you start: five decisions

Write your answers down; the rest of the setup is mechanical once you have them.

| Placeholder | Question | Common answers |
|---|---|---|
| `{{PROJECT_NAME}}` | What is this assistant for? | A field or a programme, not a single study |
| `{{STEP_EXT}}` | What language will analysis steps be written in? | `sh`, `py`, `R` |
| `{{ENV_MANAGER}}` | How are dependencies pinned? | conda, venv, renv, containers, none |
| `{{COMPUTE}}` | Where does the work run? | this laptop, a lab server, a cluster, a mix |
| `{{SCHEDULER}}` | How are jobs submitted? | none, SLURM, PBS, SGE |

Three more, which people usually get wrong by leaving them vague:

| Placeholder | Question |
|---|---|
| `{{REACHABLE}}` | Which data sources can the assistant actually query itself? |
| `{{NOT_REACHABLE}}` | Which can it not — so it must report a gap instead of guessing? |
| `{{PROTECTED}}` | What must never leave this project? |

## Steps

**1. Make the repository.** Somewhere on a real local disk. Not inside a cloud-sync folder — sync
clients hold locks on files that git needs to move, and the failures are confusing.

```sh
git init my-research-assistant && cd my-research-assistant
cp -R /path/to/this-kit/scaffold/. .
git add -A && git commit -m "Scaffold from research-assistant-scaffold v0.2"
```

**2. Fill in the instruction file.** Delete `.scaffold-unconfigured` when you are done — that
marker is what tells the convention checker this is still an unfilled template, and while it exists
the placeholder check is skipped. Open `AGENTS.md` and replace every `{{PLACEHOLDER}}` with your
answers from above. This file is the assistant's standing brief; everything else is detail.

Read what you have written as if you were a capable new colleague who knows nothing about the
project. If a sentence would not be enough for them, it is not enough for the assistant.

**3. Check it runs.**

```sh
sh tests/smoke_test.sh
sh scripts/check_conventions.sh
```

Ten checks and four convention checks, no dependencies. Do this before you write a line of science. If it fails now, you will
not know later whether the failure is yours or the scaffold's.

**4. Open your first project.**

```sh
cp -R projects/_template projects/my-first-question
```

Edit `projects/my-first-question/project.yaml` and
`projects/my-first-question/iterations/001/iteration.yaml`, then add the project to
`projects/registry.yaml` with `active: true`. Then:

```sh
sh scripts/validate_state.sh
```

It refuses to pass while placeholders remain, which is the point.

**5. Write the success criterion before anything else.** In `iteration.yaml`, state what result
would count as which answer. Do this before the assistant sees any data.

**6. Start the assistant.** Open your assistant in the repository and say: *read AGENTS.md and run
the boot sequence.* It should tell you where the project stands and stop. If it starts working
instead, the instruction file is not firm enough.

**7. Add your first real step.** Copy `src/steps/01_example.sh`, keep the header and the gates,
replace the marked block. Run it dry, then for real.

## Then what

- Write findings into `findings.md` as you go, not at the end.
- Record each decision in the Decisions section of `docs/architecture.md`, with its reason.
- End each session by having the assistant rewrite `handover.md` for the project.
- When you notice yourself explaining the same thing twice, write it into `AGENTS.md`.
- Commit the state files with the code. They are the record of how the work went.

Next: [3. The step contract](03_step_contract.md)
