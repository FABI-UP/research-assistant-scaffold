# Changelog

All notable changes to this kit are recorded here. Dates are ISO-8601.

## [Unreleased]

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
