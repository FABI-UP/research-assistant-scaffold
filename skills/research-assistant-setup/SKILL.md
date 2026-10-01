---
name: research-assistant-setup
description: Set up a durable, resumable AI research assistant inside a research project — a state model the assistant boots from, a step contract, a config layer, verification and governance rules. Use when a researcher wants an AI assistant to work inside their project across many sessions, wants to build an analysis pipeline with an agent, or asks how to structure a project so an assistant can pick up where it left off. Works in any field.
---

# Set up a research assistant

You are helping a researcher turn a folder into a project an AI assistant can work in across
months and machines. Your job in this skill is to **interview, then generate, then verify** — in
that order. Do not skip the interview. A scaffold built on guesses is worse than none, because the
researcher will trust it.

There are two profiles. Decide which before you start:

- **Repository profile** (`scaffold/`) — the work involves analysis code that runs. State model,
  step contract, config layer, pipeline.
- **Library profile** (`scaffold-library/`) — the work is a body of sources and the synthesis built
  on it: a reading collection, an evidence base, a manuscript folder. Naming convention, index,
  intake discipline, notes.

Most researchers need the library profile first, and many need only that. Some projects want both,
side by side. Ask; do not assume the repository profile because it is listed first.

Copy from those directories. Do not invent a structure.

## Before you start

Read `docs/01_concepts.md` so you can answer "why" when asked. Read `docs/08_pitfalls.md` before
you generate anything — several of its entries are mistakes you would otherwise make.

Check where you are running. If you can read and write files in the researcher's project
directory, you can do this yourself. If you cannot, say so, and give them the commands to run.
If they are working in a chat window with no file access at all, the kit cannot be installed.
Point them to `docs/10_prompts.md`, which works without it.

## Step 1 — Interview

Ask these in small groups, not as a wall. Let their answers shape the follow-ups. Ten questions is
usually enough; five is not.

**About the work**

1. What field, and what kind of question does this project ask? (You need enough to write a brief,
   not enough to do the science.)
2. Is this one study, or a programme that will spawn several? (One project, or a family.)
3. What does the work actually consist of — analysis of data you hold, data you will fetch,
   literature synthesis, simulation, writing, or a mix? **This answer chooses the profile.** If
   nothing runs, it is the library profile, and offering a pipeline scaffold will waste their time.

**About the setting**

4. What language will analysis steps be written in?
5. How are dependencies managed — conda, venv, renv, containers, or nothing yet?
6. Where does the work run: this machine, a lab server, an institutional cluster, a mix?
7. If there is a cluster or shared host, which scheduler — SLURM, PBS, SGE, or none? On a shared
   host with no queue, ask what the fair-use budget is.

**If the library profile** — instead of questions 4 to 7

4. What are the items: papers, reports, archival documents, datasets, images, a mix?
5. How should a filename identify an item? Offer `Author_Year_keywords.ext` as a default and let
   them change it. Whatever they choose goes into `library.yaml` as the pattern the checker enforces.
6. How is the material grouped — by theme, by question, by source, chronologically? These become the
   folders under `collection/`.
7. How often should it be revisited for new material? A collection updated when somebody remembers
   is one that stops being current.

**About limits** — do not let these be answered vaguely, and do not fill them in yourself.

8. Which data sources should the assistant be able to query directly?
9. Which can it *not* reach, so that it must report a gap rather than improvise?
10. What must never leave this project? Prompt with the categories in `docs/06_governance.md` —
    unpublished data, collaborators' material, anything under permit or agreement, personal data,
    information whose disclosure is itself a risk. Researchers routinely forget one.

**Then, before you build, ask the question that matters most:**

> What would have to be true for the first iteration to count as answered?

If they cannot say yet, that is fine and worth saying out loud: it means the first iteration is a
`planned` phase, not an `implement` one. Write the question down and leave the criterion open
rather than inventing one.

## Step 2 — Generate

**For the library profile**, copy `scaffold-library/`, fill the placeholders in `AGENTS.md`,
`library.yaml`, `INDEX.md` and `notes/00_index.md`, create the themed folders they named, then run
`sh scripts/check_library.sh` and use its counts to seed `INDEX.md`. Do not write counts from
anywhere else. If they already have material, put it in `intake/` and work through the five intake
steps in `docs/09_library_profile.md` — item by item, identified from the item itself. Do not
rename in bulk from filenames. Then skip to Step 3.

**For the repository profile:**

1. Copy `scaffold/` into the project directory. Keep the layout exactly.
2. Fill every `{{PLACEHOLDER}}` in `AGENTS.md` and `docs/architecture.md` from the answers. Leave
   none. If an answer was "I don't know yet", write that, dated — an honest gap is durable, a
   plausible guess is not.
3. Write `AGENTS.md` in the researcher's own vocabulary. Use the words they used for their
   materials and their steps. This file is read by an assistant that has no other context.
4. Create the first project from `projects/_template/`, register it in `projects/registry.yaml`
   with `active: true`, and set `status: planned`.
5. Start the Decisions section of `docs/architecture.md` with the decisions taken in the interview
   (profile, language, environment, compute, scheduler, the protected list), each dated with its
   reason. Then write the project's first `handover.md` from `projects/_template/handover.md`.
6. If their steps are not shell, port `src/utils/common.sh` to their language, keeping the function
   names and all seven obligations in `docs/03_step_contract.md`. Do not shell out to another
   language's reader — two readers of one config disagree eventually, and silently.
7. Keep the scheduler block they use in `templates/job.scheduler.template`; delete the others.
8. Do **not** write any analysis steps yet. The example steps stay until there is a real workflow
   to replace them with.

## Step 3 — Verify, and show your work

Run these and show the output. Repository profile:

```sh
sh tests/smoke_test.sh
sh scripts/validate_state.sh
sh scripts/check_conventions.sh
```

Library profile:

```sh
sh scripts/check_library.sh
```

They must pass before you hand over. If the smoke test fails, fix it — do not describe it as a
known limitation.

Then tell the researcher, in a short paragraph each:

- What you created, and which decisions of theirs are encoded where.
- What you could not determine and left open, by file and field.
- The one thing to do next: open the assistant in the repository and ask it to run the boot
  sequence.

## If they want to build a pipeline next

That is a separate job and a later session, and it goes in this order:

1. **Write the workflow down in prose first**, as a document in `docs/`. What steps, in what order,
   what each consumes and produces, and why. Version it. This document is what the steps are later
   checked against, and without it there is nothing to detect drift from.
2. **Then implement one step**, end to end, with its gates and a dry run.
3. **Then the rest**, one at a time, running the smoke test as you go.
4. **Then a drift pass**: compare what the code does against what the document says, and tag each
   difference as *fix the code*, *update the document*, or *documented, no code needed*.

Resist doing all of step 2 in one pass. A pipeline generated whole is a pipeline nobody has read.

Two rules to state plainly while doing it, because they are where agent-built pipelines go wrong:

- **Do not substitute tools.** If the workflow names a tool, use it. Propose alternatives; do not
  adopt them.
- **Verify every command against the tool's own documentation**, not against the literature and not
  from memory. A flag that does not exist sits very comfortably next to a correct citation.

## Things to refuse

- Filling in the protected-data list yourself.
- Inventing a success criterion the researcher did not give you.
- Writing analysis steps during setup.
- Reporting a verification pass as complete when it was partial. Always state the scope.
- Writing any count into `INDEX.md` that did not come from a recount you just ran.
- Giving an item metadata you could not read off the item itself.
