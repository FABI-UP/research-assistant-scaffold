# 4. The state model

Three files. Each answers one question, and only that question.

## `projects/registry.yaml`

Which projects exist and which is active. Exactly one `active: true`.

```yaml
schema_version: 1
projects:
  - slug: first-question
    title: A short human title
    active: true
    created: 2026-01-01
    current_iteration: "001"
```

## `projects/<slug>/project.yaml`

The standing question and the finish line. Changes rarely.

The two fields that carry the weight are `question` and `success_criterion`. Write the question so
that evidence could answer it. "Improve the analysis" is not a question.

`constraints` is where hard-won project knowledge goes. **Write principles, not inventories.** A
list of the files you currently hold goes stale with the next download; a statement of what
qualifies a file for inclusion stays true as the collection grows. This is the single most common
way a context file rots.

## `projects/<slug>/iterations/<NNN>/iteration.yaml`

Where this attempt stands. `status` is the program counter, and it is the field the assistant reads
to know what to do.

The companion files fill up as the loop turns:

| File | Holds |
|---|---|
| `literature.yaml` | What was actually read, not what was found |
| `experiments.yaml` | Each run, with its configuration and its outcome |
| `metrics.yaml` | The numbers, with an evidence tier on each |
| `findings.md` | What was learned, what was wrong, what to do next |

## Why a `success_criterion` in both

The project-level one is the finish line. The iteration-level one is the thing you commit to
**before** seeing the data: what result would count as which answer. Writing it afterwards is not
the same exercise, and an assistant will happily help you write it afterwards.

## Validate it

```sh
sh scripts/validate_state.sh
```

Checks exactly one active project, that every project's `current_iteration` exists, that `status`
is one of the seven legal values, and that no placeholders remain. Run it whenever a session ends
oddly. Schemas drift silently otherwise, and a drifted schema means an assistant that reads the
state wrongly without saying so.

## What does not go here

Secrets, data, and anything large. The state model records *where the work is*, not the work.

Next: [5. Verification](05_verification.md)
