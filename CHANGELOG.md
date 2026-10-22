# Changelog

All notable changes to this kit are recorded here. Dates are ISO-8601.

## [Unreleased]

## [0.3.0] — 2026-10-22

### Upgrading from 0.2

- Results made under 0.2 have no provenance rows, so `99_report.sh` refuses them. Re-run the steps
  that make each table with `FORCE=1`.
- The config reader no longer switches to PyYAML when it is installed. A config that only PyYAML
  could read — list items, multi-line scalars, anchors — now stops the step with the line number.
  Rewrite it as nested `key: value` mappings. Tab indentation, which 0.2 silently replaced with
  defaults, also stops the step.
- A project copied from `scaffold/` under 0.2 has no `.gitignore` of its own. Check that `.env`,
  `results/` and `logs/` are ignored there before the next commit.

### Fixed

Fixes from a review of v0.2 against the paper. Each was reproduced first and now has a test.

- `scaffold/.gitignore`: the scaffold now ships its own ignore rules. The only `.gitignore` sat at
  the kit root, so a project copied from `scaffold/` had none, and the first `git add -A` after a
  run staged `.env` and `results/`. `check_conventions.sh` now checks that `.env`, `results/` and
  `logs/` are ignored.
- `scripts/check_conventions.sh`: the placeholder check no longer fails every configured
  repository. It flagged `templates/job.scheduler.template` and `validate_state.sh`, which hold
  placeholders by design, so the smoke test failed as soon as `.scaffold-unconfigured` was deleted.
  It now skips `templates/` and matches only `{{NAME}}` tokens. The leak check no longer skips
  files with spaces in their names.
- `scripts/validate_state.sh`: the success-criterion check passed an iteration at `analyze` whose
  criterion was empty or still the placeholder, because it read the template's comment line as the
  value. It now reads the value only, and fails any placeholder left in `iteration.yaml`. It also
  checks that registered projects exist, that a registry `current_iteration` agrees with
  `project.yaml`, and that every metric in `metrics.yaml` has a valid evidence tier.
- `src/utils/common.sh`, configuration: one reader instead of two. The fallback reader returned
  the default for a key indented with four spaces or a tab, and returned `7"` for `"7" # note`;
  the smoke test that compared the readers passed by comparing the fallback with itself where
  PyYAML was absent. The reader now handles any consistent space indentation and quoted values,
  and stops the step with the line number on anything it does not support. `init_step` checks
  each config file whole, in the step's own shell.
- `src/utils/common.sh`, `quality_gate`: fails closed. An empty or non-numeric measurement used to
  pass a `max` gate, and `quality.enabled: yes` switched gates off. Now a non-number fails the gate
  and only `false` turns gates off.
- Provenance: `end_step` appends a row to `results/reports/provenance.tsv` for every output it
  wrote. `99_report.sh` fails if any table has no row or no longer matches it, and the manifest
  now records config checksums, the system, tool versions from `provenance.tools` and table
  checksums.
- `scripts/run_pipeline.sh`: runs `.sh`, `.py` and `.R` steps and stops on any other extension. It
  used to run only `*.sh`, so a Python step was skipped and the run still reported success. Steps
  now run from the repository root, so a run from a subdirectory no longer writes a second
  `results/` there.
- `projects/_template/iterations/001/`: `literature.yaml`, `experiments.yaml`, `metrics.yaml` and
  `findings.md` now ship. The README and docs referred to them but the template did not have them.
  `registry.yaml` no longer duplicates `current_iteration`.
- `templates/job.scheduler.template`: a shebang on the first line (SLURM rejects a script without
  one), a note that PBS and SGE directives are switched off with a doubled `#`, and no reference to
  a `scripts/make_job.sh` that did not exist.
- `scaffold-library/scripts/check_library.sh`: the index check compared the distinct-items figure
  with the file count, so a deliberate repeat copy failed it; it now reads the files figure. The
  refresh check used `mktime` and `systime`, which macOS awk lacks, so it never ran there; it now
  uses plain arithmetic. The naming pattern accepts multi-part surnames such as `van_der_Merwe`.
- `CLAUDE.md` and `GEMINI.md` import `AGENTS.md` with `@AGENTS.md` rather than linking to it, so
  the boot sequence is loaded rather than left for the assistant to find.
- The setup skill finds the kit before using it, deletes `.scaffold-unconfigured`, and reads its
  `references/` files, which it never mentioned before.
- `tests/library_test.sh` and `.github/workflows/checks.yml`: the library profile has a test, and CI
  runs every test on Linux and macOS.
- Rule titles 5 and 6 in `README.md` and `docs/10_prompts.md` follow the current draft of the paper.
- `docs/08_pitfalls.md`: the `set -e` and `&&` entry is corrected, and two new entries cover a check
  defeated by its own template and ignore rules that do not travel with a copied template.
- `AGENTS.md`: the rule against personal identifiers now applies to the profiles, skill and docs,
  with attribution kept to `LICENSE`, `LICENSE-docs` and `CITATION.cff`.

### Also since 0.2.0

- `README.md` status and the example commit message in `docs/02_setup_guide.md` name v0.3.
- `docs/10_prompts.md`: points to PromptLab (Sharpton et al. 2026) as the task-level counterpart
  of the project-level prompts here.
- `scaffold-library/scripts/check_library.sh`: a case pattern inside a command substitution failed
  to parse in the old bash that macOS ships as `/bin/sh`, so the library checker had never run on
  macOS. Fixed with the POSIX leading-parenthesis form.
- Paper title in `README.md` and `CITATION.cff` updated to the current draft.
- `README.md`: a table mapping each of the paper's ten rules to where it lives in the kit; status
  corrected to v0.2; a third way in, for assistants with no file access.
- `docs/10_prompts.md`: ten prompts, one per rule, plus three follow-ups. They work without the kit.
- `GEMINI.md` pointers at the root and in both profiles; a `CLAUDE.md` pointer added to
  `scaffold-library/`, which had none.
- `handover.md` in the project template and `HANDOVER.md` in the library profile, read in the boot
  sequence and rewritten at the end of a session. Documented in `docs/04_state_model.md`.
- `scaffold/AGENTS.md`: new sections on writing up and on ending a session; decisions now go to the
  Decisions section of `docs/architecture.md`, dated, with the reason and the rejected alternative.
- The setup skill records the interview's decisions and writes the first `handover.md`; the review
  checklist checks both. It points chat-only users to `docs/10_prompts.md`.
- `docs/01_concepts.md` no longer refers to numbered rules in `docs/` that did not exist.
- `docs/02_setup_guide.md`: a broken line joined; the example commit message names v0.2.

## [0.2.0] — 2026-09-13

First public release.

- `scaffold/` — state model, step contract, config layer, shared utilities, scheduler-neutral job
  template, test fixture skeleton.
- `skills/research-assistant-setup/` — an interview-and-generate skill.
- `docs/` — concepts, setup guide, step contract, state model, verification, governance, adapting,
  pitfalls.
- Vendor-neutral agent instruction file (`AGENTS.md`) with vendor files as pointers.
- `scripts/check_conventions.sh` — declared-I/O headers, POSIX-shell portability, no leaked emails,
  home paths or credentials in tracked files, `.env` never tracked.
- `quality_gate` in the utility layer, with `quality.enabled` in the config.
- `validate_state.sh` now fails an iteration that is past `survey` with an empty success criterion.
- Both YAML readers normalise booleans and nulls identically, and the smoke test verifies they agree.
- `scaffold-library/` — the library profile: `library.yaml`, `INDEX.md` ledger, `notes/`, intake and
  `_to_delete/` conventions, and `scripts/check_library.sh`, which recounts the collection from the
  filesystem and checks naming, loose files, intake, unidentified items, duplicates, the index
  totals and whether a refresh is due.
- `docs/09_library_profile.md`, and a profile branch in the setup skill.
