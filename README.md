# Research Assistant Scaffold

A domain-agnostic starter kit for working with an agentic, file-aware AI assistant inside a
research project — across many sessions, machines and projects.

This is the practical companion to the paper *Ten simple rules for working with an AI research
assistant across your projects*. The paper gives the reasoning; this repository gives the files.

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
| `docs/` | The human guide. Concepts, setup, the step contract, the state model, verification, governance, adapting to your own setting, and the pitfalls. |

The scaffold checks itself. `tests/smoke_test.sh` runs ten checks with nothing installed — a dry
run must write nothing, steps must be idempotent, a missing input must be fatal, the two config
readers must agree, a quality gate must stop a failing run. `scripts/check_conventions.sh` adds
four static checks, including that no tracked file carries an email address, a home path or a
credential.

## Two ways in

**With an AI assistant (recommended).** Install the skill, then ask your assistant to set up a
research assistant for your project. It will ask you about ten questions and build the scaffold
around your answers. See `skills/research-assistant-setup/SKILL.md`.

**By hand.** Copy the profile you need into a new folder, work through `docs/02_setup_guide.md`
(or `docs/09_library_profile.md`), and fill in the placeholders. It takes an afternoon.

Not sure which profile? If something runs, you want `scaffold/`. If the work is reading, gathering
and writing, you want `scaffold-library/`. Projects that do both use both, side by side.

## What this is not

- Not a pipeline. The example steps do nothing but demonstrate the contract.
- Not tied to one AI vendor. The canonical instruction file is `AGENTS.md`; vendor-specific files
  are one-line pointers to it.
- Not tied to one language, scheduler or environment manager. Those are parameters.
- Not a promise that an assistant will do your science. The division of labour this kit assumes is
  researcher-led and agent-implemented.

## Requirements

Git, a shell, and an AI coding assistant that can read and write files in a directory. Everything
else — Python, R, conda, a cluster — depends on what you choose during setup.

## Status

v0.1. Expect the layout to move. See `CHANGELOG.md`.

## How this was built

This kit was drafted with an agentic AI assistant, which is the way of working it describes. That
seems worth stating plainly rather than leaving to be inferred.

The conventions in it are not invented. They come from an audit of five research-assistant
repositories built over about a year, together with a set of earlier design documents. A convention
is in the scaffold if it was invariant across those repositories, and in the pitfalls if it was a
failure that actually occurred in one of them. Where the repositories had diverged from each other,
which was often, that divergence is the reason a shared template exists at all.

The kit also checks itself. Ten smoke-test checks run with nothing installed, four static convention
checks run over the tracked files, and the library profile recounts a collection from the filesystem
rather than trusting a previous total. While the kit was being built those checks found a real bug in
it, where two configuration readers disagreed about a boolean value and a quality gate silently
skipped itself. It is written up in `docs/08_pitfalls.md`, which seemed more useful than quietly
fixing it.

## Citing

See `CITATION.cff`. If you use this in published work, please cite the paper as well.

## Licence

Dual, by directory:

- **MIT** for the code and templates — `scaffold/`, `scaffold-library/`, `skills/`. See `LICENSE`.
- **CC BY 4.0** for the prose — `docs/` and this README. See `LICENSE-docs`.

Reuse the scaffold freely; credit the writing.
