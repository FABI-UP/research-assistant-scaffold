# 6. Governance: reach, secrets and what may leave

An assistant that can read your project directory can, in principle, transmit anything in it. This
is not a reason not to use one. It is a reason to decide once, in writing, what may leave — rather
than discovering the answer afterwards.

## Decide once, write it down

In `AGENTS.md`, three lists:

- **Reachable** — sources the assistant can query directly.
- **Not reachable** — sources it cannot, and must therefore report as a gap rather than fill from
  memory. This list is what stops a plausible invention appearing where an absence belongs.
- **Protected** — what must never leave the project, whatever is asked.

Then require the assistant to say what it is about to send outward, before it sends it.

## What usually belongs in "protected"

The categories are field-specific and easy to overlook until they matter:

- Unpublished data, and collaborators' material held under an expectation of confidence.
- Anything supplied under an agreement, permit, licence or transfer arrangement.
- Personal or identifiable data, under whatever regime governs it where you work.
- Information whose disclosure creates a risk in itself — locations of vulnerable sites,
  populations or individuals.
- Material whose ownership or credit sits with a community, network or partner rather than with you.

## Secrets

`.env`, gitignored, never committed. `.env.example` records its *shape* so the next person knows
what the project needs without learning any values.

Two failure modes worth naming, because both have happened:

- **A default that is somebody else's.** A fallback value pointing at a collaborator's account or
  path will work silently and leak on the first commit. Require the variable to be set; do not
  provide a convenient default.
- **A secret written into a log.** Logs get committed, pasted into issues, and handed to
  assistants. Never echo the environment.

If a credential has ever been committed, rotating it is the fix. Removing it from the current
checkout is not.

## Cost and capacity are governance too

Long-context work and large jobs cost money and compute, and the limit is not the same for
everybody. On a shared machine, the budget is a constraint the assistant must be told about — it
will not infer that other people are using the host. Put it in `AGENTS.md`.

## Disclosure

Record where and how the assistant contributed, in the form your institution, funder and target
journal expect. Written into the instruction file, this happens by default. Remembered case by
case, it does not.

Next: [7. Adapting it](07_adapting.md)
