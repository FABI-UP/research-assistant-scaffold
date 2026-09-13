# 5. Verification and provenance

## Why routine, not vigilance

Checking things when you happen to think of it does not scale with a tool that produces more than
you can read. Verification has to be a pass that runs, with a defined scope, whose result is
recorded — including what it did *not* cover.

## Three things to verify, not one

**Claims.** Citations, figures, identifiers. Check against the primary source, not against a
summary and not against the assistant's memory. Never accept an accession, DOI or version number
that has not been looked up. Mark anything unverifiable as `UNVERIFIED` rather than dropping it
silently.

**Commands.** This is the one people miss. A tool invocation sitting next to a correct citation can
still be a plausible hallucination — a flag that does not exist, a script that is actually a web
application, an option that means something else. Check commands against the tool's own
documentation, not against the literature, and not against what the assistant believes.

**Drift.** What the code does versus what the workflow document says it does. These separate
quietly. A periodic pass that diffs one against the other catches it before it reaches a result.
Tag each difference as *update the document*, *fix the code*, or *documented, no code needed*.

## Provenance

Every result records what produced it: inputs, parameters, seed, software versions, the commit, and
whether the tree was dirty. `src/steps/99_report.sh` writes a starting version. The test is simple —
could someone re-run this in a year and know whether they got the same thing?

## Tiering

Not all evidence deserves equal weight, and an assistant will not make that distinction unless you
force it to. Tag every recorded parameter:

| Tier | Means |
|---|---|
| `benchmarked` | Measured on data like yours |
| `consensus` | Agreed across several independent sources |
| `single_study` | One paper said so |
| `inferred` | Reasoning, not measurement |

A `single_study` number copied as if it were a law is how a method gets over-fitted to someone
else's dataset. Separately, mark whether each parameter is *tunable* (the assistant may optimise it
from your data and record the choice) or a *judgement* (a human decides). `configs/pipeline.yaml`
carries `decisions.default_mode: ask` for exactly this.

## Guarding against finding what you pointed at

The failure specific to a capable assistant is not invention — it is efficiency at confirming
whatever it was aimed at. The countermeasure is procedural:

1. State what each competing explanation predicts, in `iteration.yaml`, before the data are seen.
2. Where possible, let the assistant do the grouping or the fitting blind to the labels.
3. Only then check which prediction the outcome matches.

Reversing that order produces a result that will survive every check in this document and still be
worthless.

Next: [6. Governance](06_governance.md)
