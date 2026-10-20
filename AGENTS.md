# Working on this repository

This repository is a **template kit**. It contains no science and must stay that way.

## Ground rules

1. **Nothing domain-specific.** No organism, disease, instrument, institution, cluster, dataset or
   tool name from any real project. If an example needs a subject, invent a neutral one.
2. **Nothing personal or local** in `scaffold/`, `scaffold-library/`, `skills/` or `docs/`: no
   names, emails, usernames, absolute paths, machine names, hostnames, account IDs, grant numbers
   or organisation names. Attribution belongs only in `LICENSE`, `LICENSE-docs` and `CITATION.cff`.
3. **The placeholders are the interface.** Anything a user must supply is written `{{LIKE_THIS}}`
   and listed in `docs/02_setup_guide.md`. Do not hard-code a default where a placeholder belongs.
4. **`AGENTS.md` is canonical.** Vendor-specific instruction files import it with `@AGENTS.md` and
   carry no content of their own.
5. **Keep `scaffold/` runnable.** `scaffold/tests/smoke_test.sh` and `tests/library_test.sh` must
   pass from a clean checkout with no dependencies beyond a POSIX shell, on Linux and on macOS; CI
   runs both. If you add to either profile, extend its test.
6. **Documentation and scaffold move together.** If a path, schema or contract changes in
   `scaffold/`, update `docs/` in the same commit, and `CHANGELOG.md` too.

## Layout

- `scaffold/` — repository profile. Copied wholesale into a new project; self-consistent on its own.
- `scaffold-library/` — library profile. Same, for collections rather than code.
- `skills/` — the setup skill. Reads from `scaffold/`; never duplicates its content.
- `docs/` — prose for humans. Numbered, read in order.
- `tests/` — the library profile's test. The scaffold's own test lives inside it, so it travels.
