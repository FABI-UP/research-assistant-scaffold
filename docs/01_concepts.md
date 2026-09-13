# 1. Concepts

## The problem this solves

A language model has no memory between sessions. An agentic assistant — one that reads and writes
files in your project, runs code, and keeps notes — does have memory, but only the memory you
give it, and only in the form of files it can find. Everything in this kit follows from that.

A project that an assistant can resume is one where the answer to *"where were we?"* is written
down somewhere the assistant will reliably look. A project that it cannot resume is one where that
answer lived in a conversation that has ended.

## Two layers, kept apart

**The scaffold** is domain-agnostic: how state is recorded, how a step is shaped, how configuration
reaches the code, how outputs are named, what gets verified. It is the same for a chemist, an
economist and an ecologist.

**The specialisation** is your science: which steps exist, which tools they call, which parameters
matter, what a good result looks like.

Keeping them apart is the whole trick. The scaffold is the expensive part to get right and the part
you only want to get right once. Build it separately, and every subsequent project inherits it.

## Two profiles

The kit ships two skeletons. **`scaffold/`** is for work that runs: state model, step contract,
configuration, pipeline. **`scaffold-library/`** is for work that accumulates: a collection of
sources, an index, and the synthesis built on them — see
[9. The library profile](09_library_profile.md).

They are the same idea in two shapes. Outside a code repository the scaffolding reduces to a naming
convention that encodes what each file is and an index that says what the folder contains. Most
researchers need the second first, and many need only that.

## The state model

Three nested files, each answering one question.

```
projects/registry.yaml              Which projects exist, and which one is active?
  projects/<slug>/project.yaml      What is this project asking, and when is it done?
    iterations/<NNN>/iteration.yaml Where is this attempt, right now?
```

`status` in the iteration file is the program counter. The assistant reads it and knows what to do
without being told. This is the difference between an assistant that starts every session by
asking you to re-explain the project and one that opens by telling *you* where things stand.

## The loop

`planned → survey → implement → experiment → analyze → conclude → completed`

An iteration walks these once. The next iteration inherits what the last one concluded. This is the
ordinary shape of scientific work, written down so that a program can follow it, with a termination
condition so it does not run forever.

## Researcher-led, agent-implemented

You set the question, judge the evidence, and own the conclusions. The assistant does the
mechanical work. This is not modesty about what assistants can do; it is where the failure modes
are. An assistant is an efficient finder of whatever pattern it is pointed at, which is a different
and more dangerous failure than making things up — the output looks like a result.

The practical consequence runs through this kit: **decide what would count as an answer before the
assistant sees the data.** That is why `iteration.yaml` has a `success_criterion` field above the
work rather than below it.

## Proportionality

The more a tool can do per unit of your attention, the more structure its safe use requires. A tool
that compresses a fortnight into an afternoon compresses the propagation of a mistake by the same
factor. Higher capability is a reason to raise your standards, not to relax them. Every convention
in this kit is a small tax paid against that.

## Where the rules come from

The numbered rules referenced in `docs/` map to the paper this kit accompanies. You do not need the
paper to use the kit; the kit is self-contained.

Next: [2. Setup guide](02_setup_guide.md)
