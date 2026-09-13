# Changelog

All notable changes to this kit are recorded here. Dates are ISO-8601.

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
