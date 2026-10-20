# 8. Pitfalls

Every entry here cost somebody real time. They are ordered by how quietly they fail, worst first —
because the dangerous failures are not the ones that crash.

## Dry-run poisoning

A step runs under `--dry-run` and writes a summary file anyway, with placeholder contents. A real
run afterwards sees the file, treats the step as complete, **skips it**, and carries the
placeholders into the final report as though they were results.

Silent, and exactly the class of error the report exists to prevent. `emit` refuses to write under
a dry run for this reason. If you write your own step helpers, put this in first.

## The soft gate

A step checks for a tool, does not find it, records `SKIPPED_NO_TOOL`, and passes its input onward
unchanged. The pipeline completes. The downstream step receives the wrong thing and produces a
number that is wrong rather than absent.

Hard gates die loudly and are recoverable. Soft gates produce wrong answers that look like results.
`require_tool` is always fatal, on purpose.

## The stub that copies its input

A placeholder implementation that copies the input to the output path while the real
transformation is written later. Nothing fails. Everything downstream is subtly wrong, and the
evidence that it is wrong has been destroyed.

If a step is not implemented, it must exit non-zero. An unimplemented step that succeeds is worse
than no step.

## Two readers of one configuration

The same configuration file parsed in two places — a library in one path, a hand-rolled fallback in
the other — will diverge, and the divergence will be silent. A YAML library returns typed objects,
so `true` comes back as the string `True` and an absent value as `None`; a text-scanning fallback
returns `true` and an empty string. Every comparison downstream then behaves differently depending
on what happens to be installed.

Building this kit reproduced the bug within an hour of writing the second reader. Normalising at
the boundary and testing that the readers agreed was not enough: the test passed on machines
without the YAML library, where it compared the fallback with itself, and the fallback still read
four-space indentation as a missing key and returned the default. The kit now has one reader. It
reads a small, stated subset of YAML and stops with a line number on anything else. If you only
ever have one reader, keep it that way.

## Host-difference blindness

Code developed in a container or on a modern Linux runs under an older shell on the cluster or on
macOS, where a construct silently behaves differently. No amount of testing where you wrote it will
surface this. The fix is a static check, not more testing: keep to POSIX shell in anything that
runs on more than one machine, and check it. `scripts/check_conventions.sh` does that check; the
scaffold's own utilities are POSIX for the same reason.

## Valid POSIX that one shell misreads

The static check has a blind spot: code that is valid POSIX but that one real shell parses wrongly.
`scaffold-library/scripts/check_library.sh` had a `case` statement inside `$( … )`. It passed on
Linux, where `sh` is dash, and failed to parse on macOS, where `sh` is bash 3.2, which took the
pattern's closing `)` as the end of the substitution. It is not a bashism, so
`check_conventions.sh` had nothing to flag, and the library checker had never run on macOS.

Testing where you wrote it does not catch this; running it on the other platform does. Run every
check at least once on each kind of machine it is meant for. The kit's CI now runs every test on
Linux and macOS for this reason. Inside `$( … )`, write `case`
patterns with the leading parenthesis, `(pattern)`, which every POSIX shell accepts.

## `set -e` and `&&`

`cmd && { ...; }` looks like a conditional and mostly behaves like one: `set -e` ignores a failure
anywhere in an `&&` list except the last command, so the line itself does not stop the script. The
trap is the list's exit status. When `cmd` is false the list returns non-zero, and if that line is
the last command in a function or a script, that status becomes the function's or the script's —
and the caller, under `set -e`, exits. Use an explicit `if`, which returns zero when its condition
is false. This kit's smoke test caught this in its own example steps on the first run.

## Version-controlling inside a sync folder

Cloud-sync clients hold locks and rewrite files underneath git. Commits fail with errors that do
not name the cause. Sync clients also rename large multi-part downloads in ways that defeat naive
ignore patterns — a `.gitignore` entry for `*.fastq.gz` does not match `reads.fastq-004.gz`, and
the first `git add` then tries to hash gigabytes.

Keep the repository on a real local disk. A reading pile or document library may live in sync
storage; a git repository should not.

## A check defeated by its own template

`validate_state.sh` was meant to fail an iteration past `survey` with an empty success criterion.
It read everything between `success_criterion:` and the next key, and the template has a comment
there. The comment was never empty, so neither was the criterion, and the check passed an
iteration at `analyze` whose criterion was still the placeholder. A quality gate had the same
shape of fault: an empty measurement became zero, and zero is under any maximum.

A check is only as good as its failing case. Test each one against the input it exists to stop,
not only against input it should accept. The smoke test now does.

## Ignore rules that do not travel

The kit's `.gitignore` sat at the top of the kit, outside `scaffold/`, so copying the scaffold into
a new project brought no ignore rules with it. The first `git add -A` after a run staged `.env` and
`results/`. Anything a copied template depends on has to live inside what is copied.

## The convenient default that is somebody else's

A fallback value for an account, path or environment name, taken from whoever set it up first. It
works silently for them and leaks a colleague's identifier for everyone else. Require the variable
to be set; fail if it is not.

## Inventories in the context file

A durable brief that lists what the project currently holds is wrong by the next intake. One that
states the criteria for inclusion stays right as the collection grows. Write principles, not
inventories.

## Copying a single study's number as a law

A parameter from one paper, applied as though it were established. It over-fits your method to
someone else's dataset. Tag every recorded parameter with an evidence tier
(see [verification](05_verification.md)).

## Replacing the conventional figure

An assistant asked to improve a visualisation will produce something more informative and less
familiar. Reviewers read the conventional form fluently and the novel one slowly, and the novel one
invites argument about the display rather than the result.

Produce the conventional figure first and always. Anything better is an addition, not a
replacement.

## Verification reported as complete when it was partial

A pass that covered the shell steps but validated the others by syntax only, reported as "verified".
The gap is invisible afterwards. State the scope of every verification pass, including what it did
not cover. An assistant will not volunteer this unless required to.

## Deleting before listing

Cleanup that removes more than intended, discovered later. Require the list first, approve it, then
delete. If deletion is not available or not reversible, move to a `_to_delete/` folder instead and
let a human empty it.

## The same idea implemented three times

The failure that motivates the whole kit. Four projects, four copies of the same helper, each
diverging slightly; one project cloned from another and never re-identified, still carrying the
first one's vocabulary in its instruction file; the same environment variable spelled two ways
across repositories that talk to the same machine.

None of these break anything on the day. They make every later change cost four times what it
should, and they make a fix in one place fail to arrive in the others. One template, copied
deliberately and updated centrally, is what this kit is for.

Next: [9. The library profile](09_library_profile.md)
