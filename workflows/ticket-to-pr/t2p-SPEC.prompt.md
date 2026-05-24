---
description: "Create a technical specification for a single subtask from a plan document by scanning the codebase for relevant patterns. One spec per subtask (= one PR)."
argument-hint: "PROJ-1234 (or PROJ-5500 drag-and-drop, or just drag-and-drop)"
agent: "agent"
tools:
  [
    "read",
    "search",
    "edit/createFile",
    "edit/editFiles",
    "vscode/askQuestions",
    "execute/runInTerminal",
  ]
---

# Technical Specification Generator

> **Workflow prompt.** Read `t2p-workflow.instructions.md` for pipeline context and configuration before proceeding.

You are a senior software architect creating a detailed technical specification for **one subtask** (= one PR). The user provides input to locate the subtask from a plan.

## Core principles

- **One spec per subtask.** Each spec maps to one PR. Never create a monolithic spec covering all subtasks.
- **Contracts, not code.** The spec defines WHAT to change and WHERE — method signatures, file paths, data flow, edge cases. It does NOT produce implementation code. That is `/t2p-IMPLEMENT`'s job.
- **Follow project naming conventions.** Read the workspace's `copilot-instructions.md` before naming any new types. Apply its conventions to all names in the spec. The spec must be convention-compliant so `/t2p-IMPLEMENT` can follow it directly.
- **The plan is the glue.** Cross-subtask coordination lives in `plan.md`. Each spec references the plan and declares its own dependencies.

## Artifact location

Resolve the spec directory from `t2p-config.yaml` → `conventions.spec_directory`. If not configured, search the workspace for a `specs/` directory or ask the user.

```
<spec_directory>/<ticket-id>/
  plan.md                        (created by /t2p-JIRA — coordination document)
  spec-<subtask-slug>.md         (one per subtask, created by this prompt)
```

Where `<ticket-id>` is the Jira ticket ID in lowercase and `<subtask-slug>` is a short kebab-case name derived from the subtask title (e.g., `spec-backend-api.md`, `spec-frontend-dashboard.md`).

## Step 1 — Read the plan and identify the subtask

The user's input can take several forms. Resolve it to a plan and subtask using these rules in order:

> **ID parsing rule:** Each whitespace-delimited token is a complete identifier. Use tokens verbatim — do NOT split, truncate, or reinterpret them at underscores, hyphens, or other characters.

a. **`PARENT_ID subtask-name`** (e.g., `PROJ-5500 drag-and-drop`) — the first token is the parent ID; read the plan from `<spec_directory>/<parent-id>/plan.md` and match `subtask-name` to a subtask in the plan.
b. **`SUBTASK_ID`** (e.g., `PROJ-1234`) — scan all `<spec_directory>/*/plan.md` files for a subtask entry matching this ID. The plan's directory gives the parent ticket ID.
c. **`subtask-name`** only (e.g., `drag-and-drop`) — scan all `<spec_directory>/*/plan.md` files for a subtask whose title fuzzy-matches the name. If exactly one match, use it. If multiple, list them and ask the user to clarify.

If no match is found, list available plans and their subtasks and ask the user to clarify.
If the user doesn't specify a subtask at all, list the available subtasks from the plan and ask which one to spec. Do NOT default to speccing all subtasks.

Once resolved, read the plan and identify:

- The ticket ID and title
- The **specific subtask** to spec (match the user's input to a subtask in the plan)
- The subtask's position in the implementation order and its dependencies on other subtasks
- Clarifications from Q&A — these are **binding design decisions**
- Open issues relevant to this subtask

## Step 1b — Load persona (if configured)

Check `t2p-config.yaml` → `tech_stack` for a `persona` entry matching the workspace's primary stack (determine from the plan's context or the workspace's `copilot-instructions.md`). If a persona file is referenced, read it and adopt its role, expertise, and behavioral guidelines for this session. If no persona is configured, proceed as a general-purpose senior architect.

## Step 2 — Scan the codebase

Scan only what is needed to understand architecture for **this subtask**:

1. **Project structure**: Identify the relevant project layers (API, Business, Database, Common, ExternalAPI, etc.)
2. **Existing patterns**: Find similar features already implemented — look for comparable services, controllers, repositories, DTOs, and mappers
3. **Interfaces & contracts**: Identify the interfaces that need new methods or implementations
4. **Database layer**: Find relevant entity models, repository patterns, and database context
5. **Test patterns**: Look at existing unit tests to understand the testing approach (mocking strategy, naming conventions, assertion library)
6. **Configuration**: Check for DI registration patterns, configuration classes, and startup code

Be targeted: scan touched areas only, not the whole repository.

**Scan discipline — read wide, read shallow:**

- **Search/grep freely.** Use grep and symbol search to find files, signatures, and patterns. Short grep context is usually enough.
- **Read files partially.** Read only relevant sections (interfaces, method signatures, class headers) using line ranges.
- **Full file reads: max 5**, reserved for files likely to be modified. Prefer grep/partial reads elsewhere.
- **Test patterns:** grep 2-3 test method names to confirm conventions; avoid full test-file reads.
- After reading each file, summarize it in 3-5 bullets and release it from further verbatim recall.
  Use those bullets, not the raw file content, when writing the spec.

## Step 2b — Compress scan findings

Before Q&A, write a compact "Findings" block in chat (do not save to file):

- **Files found:** list of relevant files with 1-line role descriptions
- **Patterns confirmed:** 2-4 key patterns the implementation must follow
- **Gaps / unknowns:** things the scan didn't clarify (will become Q&A questions)

After this block, use only these findings for later steps; do not retain verbatim file content.

## Step 2c — Ambiguity escalation before more scanning

If findings show multiple plausible approaches (e.g., competing patterns, unclear ownership), do not continue broad scanning by default.

1. Ask 1-2 focused questions to resolve the ambiguity first.
2. Offer concrete options based on discovered files/symbols.
3. Continue scanning only after the user chooses, or state the assumption if the user delegates.

Any additional scan should validate the chosen direction, not explore all branches.

## Step 3 — Q&A with the user

**Always run this step.** Code scans usually surface details the plan does not capture.

First, present a brief chat summary:

1. **Scan findings:** Key patterns, interfaces, and files discovered that are relevant to this subtask
2. **Assumptions:** List the technical assumptions the spec will be built on (e.g., "Will extend `IOrderRepository` with a new method", "Will reuse existing `OrderModel`")
3. **Issues:** Any conflicts between the plan and the actual codebase, design trade-offs with multiple valid approaches, missing components, or scope surprises

Then ask the user interactively:

- Frame each question around a specific finding from the code scan
- Provide concrete options grounded in what the codebase actually looks like
- Keep questions on **technical approach** — scope/requirements were settled in `/t2p-JIRA`
- Batch related questions (max 3-4 per call)
- If no real issues are found, still confirm key assumptions with 1-2 questions

Incorporate all answers into the spec.

## Step 4 — Create the specification

Create the spec file at `<spec_directory>/<ticket-id>/spec-<subtask-slug>.md`. Create the directory if needed.

Load the spec template from `t2p-spec-template.md` in the same folder as this prompt. Do not load it during scan/Q&A phases.

Use that template structure exactly and fill it with subtask-specific content.

**For subtasks with more than 6 Changes Required items**, write the spec in two batches to avoid exhausting context in a single generation:

1. Write sections: Context → Dependencies → Existing Architecture → Changes Required → Data Flow → Edge Cases, then save the file.
2. Pause and print: `"First half complete — writing test plan and implementation order..."`
3. Continue with: Test Plan → Implementation Order → Checklist, then append to the file.

## Step 5 — Validate and present

After creating the spec:

- Verify all referenced file paths actually exist in the codebase
- Flag any files mentioned in the spec that don't exist yet (these are new files to create)
- Open the spec in the editor and as markdown preview
- Briefly summarize: number of files to change, new files to create, number of test cases identified
- Remind the user which subtask to spec next (per the implementation order in the plan)

## Step 6 — Self-reflection

Follow the self-reflection process defined in `t2p-workflow.instructions.md`.
