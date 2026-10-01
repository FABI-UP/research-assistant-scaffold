# 10. Ten prompts

One prompt for each of the ten rules in the paper this kit accompanies. They are the quickest way to
try the rules, and they work with any assistant, including one you use through a chat window with no
access to your files.

In a chat window, you keep the context file. Give it to the assistant at the start of each session,
and save the updated version it gives back at the end. Everything else below works unchanged.

Treat each prompt as a starting point. Change the wording to fit your project; keep what it asks for.

| Rule | Prompt | In this kit |
|---|---|---|
| 1. Give the assistant a well-ordered workspace it can navigate | "Look through this folder and propose a structure and a file-naming convention for it. List every file you would move or rename, and change nothing until I have approved the list." | The layout of `scaffold/`; `library.yaml` and `check_library.sh` |
| 2. Invest in durable context and memory | "Write a context file for this project that you will read at the start of every session. Give the research question, where the work stands, the next step and the rules we work by. State criteria and principles rather than lists of files, which go out of date." | `AGENTS.md`; the state model; `handover.md` |
| 3. Build a living knowledge base, not one-off answers | "Record the decisions we took today in the project's decision log, each dated and with its reason and the alternative we rejected. Update any project document they affect." | Decisions in `docs/architecture.md`; `findings.md`; `notes/` |
| 4. Delegate the tedious, own the science | "Write and run the code for this step. Show me the outputs and the interpretations they could support, but do not choose between them. That judgement is mine." | The division of labour in `AGENTS.md` |
| 5. Let one assistant span the whole research lifecycle | "Tell me where this project stands in the research cycle of plan, survey, implement, run, analyse, conclude and write up. What did the previous stage establish, and what must this one deliver?" | `status` in `iteration.yaml`; Writing up in `AGENTS.md` |
| 6. Systematically verify against authoritative sources | "Check every citation, identifier, number and command in this document against its primary source or the tool's own documentation. Report what you checked and what you could not, and mark the second group UNVERIFIED." | [5. Verification](05_verification.md); the smoke test |
| 7. Track provenance and tier your sources by authority | "For each result and parameter, record where it came from and how well it is supported: measured on our data, agreed across several sources, from a single study, or a default. Flag anything that rests on a single study or a default." | `99_report.sh`; evidence tiers in `metrics.yaml` |
| 8. Know the assistant's reach and make it flag its limits | "List the sources you can reach from here and those you cannot. If you need something you cannot reach, record it as an open item rather than filling the gap. Before you send anything outside this project, tell me what and where." | Reach and limits in `AGENTS.md`; [6. Governance](06_governance.md) |
| 9. Version the AI-assisted workflow itself | "Save this as a new version rather than editing it in place, and record what changed and why." | git; `CHANGELOG.md`; ground rule 8 in `AGENTS.md` |
| 10. Encode what works into a reusable, shared template | "Separate what is generic in this project from what is specific to it, and write the generic part up as a template a colleague could start from. Remove names, paths, credentials and unpublished data." | This kit; `skills/research-assistant-setup/` |

## Three follow-ups worth keeping to hand

| When | Prompt | Rule |
|---|---|---|
| At the end of a session | "Before we stop, update the context file with what changed today, what is still running and the next step, written for a new session on another machine." | 2, 3 |
| Before looking for a pattern | "Before you see the metadata, write down the pattern each hypothesis predicts. Group the data blind to the metadata, and only then compare." | 6 |
| Every so often | "Compare what the code does with what the workflow document says it does. Tag each difference as fix the code, update the document, or documented with no code change needed." | 9 |

Rule titles follow the current draft of the paper.
