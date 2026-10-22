# Research Assistant Scaffold

A domain-agnostic starter kit for working with an agentic, file-aware AI assistant inside a
research project — across many sessions, machines and projects.

This is the practical companion to the paper *Ten simple rules for developing and using an AI
research assistant* (in preparation). The paper gives the reasoning; this repository gives the files.

**It contains no science.** There is no pipeline here, no domain, no organism, no cluster. What is
here is the scaffolding that made a pipeline possible: a state model the assistant can resume from,
a contract that every analysis step obeys, a configuration layer, a verification discipline, and a
set of pitfalls that cost real time to discover. You bring the science.

## What you get

| Path | What it is |
|---|---|
| `scaffold/` | **Repository profile** — for work that runs. State model, step contract, config layer, pipeline runner. Empty of science, complete in structure. |
| `scaffold-library/` | **Library profile** — for work that accumulates. Naming convention, index, intake discipline, notes, and a checker that recounts the collection from the filesystem. |
| `skills/research-assistant-setup/` | An agent skill. Point your assistant at it and it interviews you about your field, language, environment and compute, then generates your scaffold from `scaffold/` and writes your instruction file. |
| `docs/` | The human guide. Concepts, setup, the step contract, the state model, verification, governance, adapting to your own setting, the pitfalls, and ten prompts. |
| `docs/10_prompts.md` | One prompt per rule. They work in any assistant, including a chat window with no file access, and are the quickest way to try the rules before adopting the kit. |

The scaffold checks itself. `tests/smoke_test.sh` runs with nothing installed but a POSIX shell: a
dry run must write nothing, steps must be idempotent, a missing input must be fatal, config the
reader cannot read must stop the step rather than fall back to defaults, a quality gate must stop
a failing or missing measurement, a table without provenance must stop the report, and the state
validator must catch an iteration past `survey` with no success criterion.
`scripts/check_conventions.sh` adds five static checks, including that no tracked file carries an
email address, a home path or a credential, and that `.env` and `results/` are ignored. The
library profile has its own test, `tests/library_test.sh`, and CI runs everything on Linux and
macOS.

## Three ways in

**With an AI assistant (recommended).** Clone this kit, then make the skill available to your
assistant: open the assistant in the kit's folder, or link `skills/research-assistant-setup/` into
your assistant's skills directory. The skill reads the scaffold from the kit, so keep the clone.
Then ask your assistant to set up a research assistant for your project. It will ask you about ten
questions and build the scaffold around your answers. See `skills/research-assistant-setup/SKILL.md`.

**By hand.** Copy the profile you need into a new folder, work through `docs/02_setup_guide.md`
(or `docs/09_library_profile.md`), and fill in the placeholders. It takes an afternoon.

**Without file access.** If your assistant is a chat window that cannot read or write your files,
start with `docs/10_prompts.md`. You keep the context file, give it to the assistant at the start of
each session, and save the updated version it gives back at the end.

Not sure which profile? If something runs, you want `scaffold/`. If the work is reading, gathering
and writing, you want `scaffold-library/`. Projects that do both use both, side by side.

## How the kit maps to the paper

| Rule | Where it lives in the kit |
|---|---|
| 1. Give the assistant a well-ordered workspace it can navigate | The fixed layout of `scaffold/`; the naming convention in `scaffold-library/library.yaml`, enforced by `check_library.sh` |
| 2. Invest in durable context and memory | The boot sequence in `AGENTS.md`, imported by `CLAUDE.md` and `GEMINI.md`; `registry.yaml`, `project.yaml` and `iteration.yaml`; `handover.md` for work that moves between sessions, machines or assistants |
| 3. Build a living knowledge base, not one-off answers | `docs/architecture.md` and its Decisions section; `findings.md` in each iteration; `notes/` in the library profile |
| 4. Delegate the tedious, own the science | The division of labour in `AGENTS.md`; the setup skill's list of things to refuse |
| 5. Let one supervisor assistant span the whole research lifecycle | The loop from `planned` to `completed` in `iteration.yaml`; Writing up in `AGENTS.md` |
| 6. Systematically verify against primary sources | `docs/05_verification.md`; a `success_criterion` written before the data are seen, enforced by `validate_state.sh`; `UNVERIFIED` marking; the smoke test and quality gates |
| 7. Track provenance and tier your sources by authority | A provenance row for every output, written by `end_step`; `src/steps/99_report.sh`, which writes the run manifest and fails if any table lacks provenance; evidence tiers in `metrics.yaml`, enforced by `validate_state.sh`; the order of authority in `AGENTS.md` |
| 8. Know the assistant's reach and make it flag its limits | The reachable, not reachable and protected lists in `AGENTS.md`; `docs/06_governance.md`; `check_conventions.sh` |
| 9. Version the AI-assisted workflow itself | git, with a `.gitignore` shipped in the scaffold; `CHANGELOG.md`; ground rule 8 in `AGENTS.md`; the drift pass in `docs/05_verification.md` |
| 10. Encode what works into a reusable, shared template | The kit itself, and `skills/research-assistant-setup/` |

Each rule also has a prompt in `docs/10_prompts.md`. Rule titles follow the current draft of the paper.

## What this is not

- Not a pipeline. The example steps do nothing but demonstrate the contract.
- Not tied to one AI vendor. The canonical instruction file is `AGENTS.md`. `CLAUDE.md` and
  `GEMINI.md` import it with `@AGENTS.md`, so the assistant loads it at the start of a session
  rather than having to follow a link, and any other filename an assistant looks for can be added
  the same way.
- Not tied to one language, scheduler or environment manager. Those are parameters.
- Not a promise that an assistant will do your science. The division of labour this kit assumes is
  researcher-led and agent-implemented.

## Requirements

Git, a shell, and an AI coding assistant that can read and write files in a directory. Everything
else — Python, R, conda, a cluster — depends on what you choose during setup.

## Status

v0.2, under review by collaborators before the first archived release. Expect the layout to move.
See `CHANGELOG.md`.

## How this was built

This kit was drafted with an agentic AI assistant, which is the way of working it describes. That
seems worth stating plainly rather than leaving to be inferred.

The conventions in it are not invented. They come from an audit of five research-assistant
repositories built over about a year, together with a set of earlier design documents. A convention
is in the scaffold if it was invariant across those repositories, and in the pitfalls if it was a
failure that actually occurred in one of them. Where the repositories had diverged from each other,
which was often, that divergence is the reason a shared template exists at all.

The kit also checks itself. The smoke test runs with nothing installed, five static convention
checks run over the tracked files, and the library profile recounts a collection from the filesystem
rather than trusting a previous total. While the kit was being built those checks found a real bug in
it, where two configuration readers disagreed about a boolean value and a quality gate silently
skipped itself. A later review found more of the same kind, including a success-criterion check that
its own template comment defeated. They are written up in `docs/08_pitfalls.md` and `CHANGELOG.md`,
which seemed more useful than quietly fixing them.

## Citing

See `CITATION.cff`. If you use this in published work, please cite the paper as well.

## Licence

Dual, by directory:

- **MIT** for the code and templates — `scaffold/`, `scaffold-library/`, `skills/`. See `LICENSE`.
- **CC BY 4.0** for the prose — `docs/` and this README. See `LICENSE-docs`.

Reuse the scaffold freely; credit the writing.
