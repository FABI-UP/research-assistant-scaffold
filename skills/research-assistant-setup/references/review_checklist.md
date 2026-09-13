# Review checklist — before handing over

Structure

- [ ] No `{{PLACEHOLDER}}` remains anywhere. `grep -rn '{{' .` returns nothing.
- [ ] `AGENTS.md` uses the researcher's own vocabulary, not the template's.
- [ ] Exactly one project has `active: true`.
- [ ] The active project's `current_iteration` directory exists and holds `iteration.yaml`.
- [ ] `status` is one of the seven legal values.

Behaviour

- [ ] `sh tests/smoke_test.sh` passes, all checks.
- [ ] `sh scripts/validate_state.sh` passes.
- [ ] A dry run of the pipeline creates no files at all.
- [ ] A step with a missing input fails, and says which input.

Limits

- [ ] The reachable / not-reachable / protected lists are filled from the researcher's answers, not
      from assumption, and none is empty without them having said so.
- [ ] `.env` is gitignored; `.env.example` records the shape and no values.
- [ ] No credential, absolute path, username or hostname appears in any committed file.

Library profile only

- [ ] `sh scripts/check_library.sh` passes, or every failure it reports is written into the
      `INDEX.md` update log as a flagged gap rather than quietly fixed.
- [ ] Every count in `INDEX.md` came from that run, not from anywhere else.
- [ ] No item is in `intake/`; nothing is loose in the collection root.
- [ ] Items that could not be identified carry the marker and are listed in `INDEX.md`.
- [ ] Candidates that are not held are listed separately from holdings.

Honesty

- [ ] Everything left undetermined is recorded, by file and field, and reported.
- [ ] The scope of what was verified is stated, including what was not checked.
- [ ] No analysis step has been written.
