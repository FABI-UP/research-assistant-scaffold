# Interview notes — how to read the answers

## "It's just one study"

Often it is not. Ask whether the same kind of analysis will be run on a second dataset within the
year. If yes, set it up as a family from the start: one repository, several projects under
`projects/`. Retrofitting the split later means moving state files and rewriting paths.

## "We don't have a cluster"

A supported configuration, not a missing one. Delete the scheduler directives and run steps
directly. Do not leave a scheduler template half-filled — a future reader will assume it works.

## "Everything is on Google Drive / OneDrive / Dropbox"

Common, and fine for a document or literature collection. Not fine for the git repository: sync
clients hold locks on the files git needs to move, and the failures do not name the cause. Put the
repository on a real local disk and let the data stay in sync storage.

## "The assistant can just search the web"

Pin this down. Which sources, with what access? Something reachable through a browser the assistant
does not have is *not reachable*, and belongs on that list. The purpose of the list is to make the
assistant report a gap rather than produce a plausible substitute.

## "Nothing here is sensitive"

Usually said quickly and usually not quite right. Walk the categories in `docs/06_governance.md`
out loud. Unpublished data and collaborators' material catch almost everyone.

## "Can you just build the whole pipeline now?"

No, and say why: a pipeline generated in one pass is a pipeline nobody has read, and its errors are
the quiet kind. Offer the order in the skill instead. If they push, build one step end to end and
let them see the shape.

## Reading hesitation

If someone cannot state a success criterion, the honest output is an iteration at `status: planned`
with the question written and the criterion blank. That is a correct result, not a failed
interview. Do not fill the gap to make the file look finished.
