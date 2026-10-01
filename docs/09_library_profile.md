# 9. The library profile

Most research is not a pipeline. It is a body of sources and the understanding built on it — a
reading collection, a manuscript folder, an evidence base for a review. The same scaffolding
applies, and it reduces to two things: **a naming convention that says what each item is, and an
index that says what the folder contains.**

`scaffold-library/` is the skeleton. It is the same structure as the repository profile with the
code taken out, and it is the profile most researchers need first.

## Layout

```
AGENTS.md          Standing brief. Boot sequence, intake rules, order of authority.
library.yaml       The conventions, in one file the checker reads.
INDEX.md           The ledger: what is held, where, with what verified detail, and how it changed.
notes/             The synthesis. 00_index.md plus one file per theme.
collection/        The items, in themed folders.
intake/            Where new items arrive. Nothing stays here.
_to_delete/        Where things go instead of being deleted.
scripts/check_library.sh
```

## The one rule that matters most

**A total is never carried forward. It is recounted.**

A count copied from the previous session is wrong the moment anything changes, and nothing tells
you when it drifted. `scripts/check_library.sh` recounts from the filesystem and compares against
what `INDEX.md` claims. Run it at the start of a maintenance pass and use its numbers, not the ones
already written down.

The checker also enforces the rest: no loose items in the collection root, nothing left in intake,
every filename matching the convention, every unidentified item logged, and identical copies
surfaced. Each of those is cheap to state and expensive to keep by hand.

## Intake

Five steps per item, in order:

1. **Identify it from the item itself** — its own title page or metadata. Not from the filename,
   which is usually a download ID, and not from a search result.
2. **Rename to the convention.** `Author_Year_keywords.ext` by default; set your own in
   `library.yaml`.
3. **Check for duplicates.** Identical bytes are easy. The same item downloaded twice differs in
   bytes and needs a content comparison. Same author and year is **not** a duplicate — assuming it
   is produces false merges, and several distinct `Wang_2020` papers is the normal case.
4. **File it** under a themed folder.
5. **Log it** in `INDEX.md` with the counts before and after.

An item that cannot be identified keeps the unidentified marker and is logged as such. An honest
marker is worth more than invented metadata, because invented metadata is indistinguishable from
verified metadata six months later.

## Two-pass search

When looking for new material, run two passes: one narrow, on the framing you were given, and one
deliberately wider, on adjacent framings. A single query's framing is the main way a collection
becomes narrow without anyone noticing, and an assistant will follow your framing faithfully.

Log what you could not obtain as a candidate, separately from what is held. A bibliographic entry
that reads like a holding is how a collection comes to overstate itself.

## Order of authority

When sources here disagree:

1. **The filesystem.** Recount.
2. **This collection's own readings and measurements.**
3. **`INDEX.md`** — what is on disk, verified.
4. **`notes/`** — the synthesis, which is downstream of all of it and the first thing to be wrong.

A figure that reaches the synthesis and cannot be reproduced from its source is a correction, and a
correction propagates to every file carrying the number, not only where it was spotted.

## Synthesis

From the full item, not its abstract. Every claim traces to a specific source, and every number to
where that number is stated. Mark disagreements rather than resolving them — a flagged discrepancy
is a finding; a quietly reconciled one is a loss.

Tag claims with the same evidence tiers used elsewhere in this kit: `benchmarked`, `consensus`,
`single_study`, `inferred`. See [verification](05_verification.md).

## Self-maintenance

Set `refresh_interval_days` in `library.yaml` and let the checker tell you when a pass is due.
Effort compounds only if the collection maintains itself; a collection that is updated when someone
remembers is one that quietly stops being current.

## Sync storage

Unlike the repository profile, a library **may** live in cloud-synced storage, and usually should —
it is the material, and it needs to be on every machine. The caution about sync folders applies to
git repositories, not to document collections. Two things to know: sync clients occasionally
produce conflict copies, which the duplicate check will surface; and a file may be absent from one
machine's mirror and present on another, so a count that drops by three is sync lag before it is
loss. Flag it, wait, recount.

Next: [10. Ten prompts](10_prompts.md)
