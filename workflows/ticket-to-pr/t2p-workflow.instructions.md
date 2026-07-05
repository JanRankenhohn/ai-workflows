---
description: "Ticket-to-PR development workflow. Defines the pipeline stages, artifacts, conventions, and configuration. Read this when executing any workflow prompt (/t2p-EXPLORE, /t2p-PLAN, /t2p-SPEC, /t2p-IMPLEMENT, /t2p-TEST, /t2p-REVIEW, /t2p-CREATE-PR)."
---

# Ticket-to-PR Workflow

A structured, multi-stage AI development pipeline that takes you from a Jira ticket to a review-ready pull request in Azure DevOps. Each stage runs in its own chat session for clean context isolation, with the developer reviewing output between every stage.

## Pipeline

```
[/t2p-EXPLORE <ticket-id>] (optional)
  → Interactive domain exploration: grilling session, codebase cross-referencing,
    produces CONTEXT.md glossary and optional ADRs
  ↓ (developer reviews domain artifacts — skip if domain is well-understood)

/t2p-PLAN <ticket-id>
  → Analyzes ticket, Q&A to refine it, groups subtasks into PR-sized chunks, outputs plan
  ↓ (developer answers Q&A, reviews plan)

/t2p-SPEC <ticket-id> <subtask-name>
  → Scans codebase, Q&A, creates per-subtask spec at <spec_directory>/<ticket-id>/spec-<subtask>.md
  ↓ (developer reviews spec — repeat for each subtask)

/t2p-IMPLEMENT <ticket-id> <subtask-name>
  → Implements from the subtask's spec — shows each Implementation Order step as a todo,
    pauses after each step with a summary of changes. User reviews and says "continue".
    Appends Implementation Notes to the spec if decisions/deviations occurred.
  ↓ (developer reviews implementation)

/t2p-TEST <ticket-id> <subtask-name>
  → Generates tests from the subtask spec's Test Plan
  ↓ (developer reviews tests)

/t2p-REVIEW <ticket-id> <subtask-name>
  → Reviews implementation against subtask spec + code quality (with different model)
  ↓ (developer addresses findings, updates spec)

/t2p-CREATE-PR <ticket-id> <subtask-name>
  → Creates PR in Azure DevOps from current branch with generated description
  ↓ (developer reviews PR, merges)
```

## Configuration

**Read `t2p-config.yaml` and apply its settings before executing any workflow prompt.** It contains user-customizable settings that affect prompt behavior:

- **MCP servers** — which integrations are available (Jira, Azure DevOps). Each entry has `enabled` (true/false) and `name` (the MCP server name as configured in your VS Code `mcp.json`). Skip tools for servers marked as not enabled.
- **Tech stack** — maps each stack to its review criteria file and optional persona. `/t2p-REVIEW` loads the matching review criteria based on file types in the diff. `/t2p-SPEC` and `/t2p-IMPLEMENT` load the persona to adopt a stack-specific expert role.
- **Branch naming** — your branch naming convention, used by `/t2p-CREATE-PR`.
- **Project conventions** — cross-workspace conventions that apply everywhere.

> Add your own `<stack>-review-criteria.instructions.md` and reference it in the config for additional stacks (Go, Python, etc.).

## Prompts

| Prompt           | Purpose                                                 | Input                                            |
| ---------------- | ------------------------------------------------------- | ------------------------------------------------ |
| `/t2p-EXPLORE`   | Optional domain exploration, grilling, CONTEXT.md       | Parent ticket ID (or paste ticket details)       |
| `/t2p-PLAN`      | Fetch ticket, analyze, Q&A, group subtasks, create plan | Parent ticket ID                                 |
| `/t2p-SPEC`      | Scan codebase, Q&A, create per-subtask spec             | Subtask ID, parent + name, or just name          |
| `/t2p-IMPLEMENT` | Implement from subtask spec                             | Subtask ID, parent + name, or just name (+ step) |
| `/t2p-TEST`      | Generate tests from subtask spec's Test Plan            | Subtask ID, parent + name, or just name          |
| `/t2p-REVIEW`    | Review implementation vs subtask spec + quality         | Subtask ID, parent + name, or just name          |
| `/t2p-CREATE-PR` | Create Azure DevOps PR with generated description       | Subtask ID, parent + name, or just name          |

## Artifacts

| Artifact    | Location                                         | Lifecycle                                                                                     |
| ----------- | ------------------------------------------------ | --------------------------------------------------------------------------------------------- |
| CONTEXT.md  | `<spec_directory>/<ticket-id>/CONTEXT.md`        | Optional. Domain glossary from `/t2p-EXPLORE`. Consumed by PLAN and SPEC.                    |
| ADRs        | `<spec_directory>/<ticket-id>/adr/`              | Optional. Decision records from `/t2p-EXPLORE`. Not checked into the repo.                   |
| Plan        | `<spec_directory>/<ticket-id>/plan.md`           | Persisted. Coordination document across subtasks. Not checked into the repo.                  |
| Spec        | `<spec_directory>/<ticket-id>/spec-<subtask>.md` | One per subtask (= one per PR). Persisted until developer deletes. Not checked into the repo. |
| Code        | Workspace                                        | Normal git lifecycle                                                                          |
| Tests       | Workspace                                        | Normal git lifecycle                                                                          |

## Files in this workflow

| File                   | Purpose                                                          |
| ---------------------- | ---------------------------------------------------------------- |
| `t2p-config.yaml`      | User-customizable settings: MCP servers, tech stack, conventions |
| `t2p-spec-template.md` | Template used by `/t2p-SPEC` when generating spec documents      |

## Key conventions

- **Ticket ID parsing:** The first whitespace-delimited token after the prompt name is always a complete identifier (ticket ID, branch name, or subtask name). Use it verbatim — do NOT split, truncate, or reinterpret it at underscores, hyphens, or other internal characters.
- **JQL quoting:** Always quote issue key values in JQL queries (e.g., `parent = "DEV_VULCAN-5807"`, not `parent = DEV_VULCAN-5807`). Project keys containing underscores or other special characters break unquoted JQL parsing.
- Each pipeline stage runs in its **own chat session** for context isolation.
- The developer reviews output between every stage — nothing is fully automatic.
- `/implement` does **not** write tests. `/test` does **not** implement features.
- `/review` may propose spec updates — developer decides whether to apply them.
- Build verification happens **once per Implementation Order step**, not per file change.
- `/implement` **pauses after each step** with a summary — the developer reviews and says "continue."
- `/implement` records decisions/deviations as **Implementation Notes** appended to the spec (only when noteworthy).
- **Plan tracks subtask status only** — the plan owns cross-subtask coordination (sequencing, dependencies, high-level status). Detailed implementation checklists belong in the subtask spec, not duplicated in the plan. `/implement` updates the plan's subtask status to "In Progress"; the developer updates it to "Done" after merge.
- **Domain context (CONTEXT.md)** — At the start of every stage that resolves a ticket ID, check `<spec_directory>/<ticket-id>/CONTEXT.md`. If it exists (produced by `/t2p-EXPLORE`), read it and treat its terms as **binding vocabulary** throughout the session. Flag any language that conflicts with the glossary. Also read ADRs from `<spec_directory>/<ticket-id>/adr/` if the directory exists.
- **Self-reflection** — every prompt ends with a self-reflection step. Follow the process defined below.

## Skill integration

Workflow stages define **skill checkpoints** — moments during execution where an available skill can take over a specific action (building, testing, committing, creating a PR, etc.). Skills are never hardcoded into the workflow — they are discovered dynamically from the skills available in your current session context.

**How it works:**

1. When a stage reaches a skill checkpoint, it scans the skills available in your context (workspace skills, user-level skills, built-in skills).
2. If a skill's description is relevant to the checkpoint's action, read the skill's full content and follow it instead of the stage's default behavior.
3. If no matching skill is found, use the stage's built-in default (e.g., run the workspace's build command).
4. If multiple skills match, pick the most specific one (e.g., a "verify .NET build" skill wins over a generic "verify build" skill for a .NET workspace).

Skills are matched by semantic relevance of their description — not by name or file path convention. A skill named "ci-readiness-check" will match a "verify build" checkpoint if its description says it runs formatting and tests.

## Self-reflection

Every workflow stage ends with a self-reflection step. After completing all other steps, briefly review your own execution:

1. Did any step produce poor results, require user correction, or feel unnecessary?
2. Did the user provide guidance that should have been in this prompt from the start?
3. Were there missing rules or ambiguities in this prompt that caused errors?

If you have concrete improvement suggestions, present them at the end:

- **Prompt file:** which `.prompt.md` or `.instructions.md`
- **Issue observed:** what went wrong this session
- **Proposed change:** specific text to add, modify, or remove
- **Caveat:** why this might not generalize

Do NOT apply changes to prompt files. The user decides whether to update prompts.
If nothing noteworthy happened, skip this section silently.
