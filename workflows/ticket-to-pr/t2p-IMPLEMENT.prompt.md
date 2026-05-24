---
description: "Implement changes from a subtask's spec document, following the Implementation Order step by step."
argument-hint: "PROJ-1234 (or PROJ-5500 drag-and-drop, or just drag-and-drop)"
agent: "agent"
tools: ["read", "search", "edit", "execute/runInTerminal"]
---

# Implement from Spec

> **Workflow prompt.** Read `t2p-workflow.instructions.md` for pipeline context and configuration before proceeding.

You are implementing code changes defined in a subtask's spec document. The user provides input to locate the spec, and optionally a specific step or change number to focus on.

Artifacts live in the spec directory configured in `t2p-config.yaml` → `conventions.spec_directory`:

- `<spec_directory>/<ticket-id>/plan.md` — coordination document with Q&A clarifications and implementation order across subtasks
- `<spec_directory>/<ticket-id>/spec-<subtask-slug>.md` — the subtask-specific spec to implement

## Rules

1. **Follow the spec's Implementation Order exactly.** Do not reorder or skip steps.
2. **Do NOT write tests.** Tests are handled separately via the `/t2p-TEST` prompt. If you encounter test-related items in the spec, skip them.
3. **Follow project conventions — they override spec details.** The workspace's `copilot-instructions.md` defines naming, architecture, and dependency patterns. When the spec uses names that conflict with conventions, apply the convention and note the deviation from the spec. When existing code in a touched file violates conventions, do not propagate the violation — follow the convention. `copilot-instructions.md` is authoritative for naming and architecture; the spec is authoritative for structure and scope.
4. **Build once per Implementation Order step**, not after every individual file change. Complete all changes for a step, then verify.
   > **Skill checkpoint — verify build:** Check available skills for one that handles build verification, formatting checks, or CI readiness. If found, read and follow that skill. Default: run the workspace's build command. If it doesn't compile, fix it before moving to the next step.
5. **Stay in scope.** Only implement what the spec describes. Do not refactor surrounding code, add extra features, or "improve" things outside the spec.
6. **Update the spec checklist after all steps are complete.** Once all Implementation Order steps are done, check off the applicable items in the subtask spec's "Checklist" section: `Implementation matches this spec`, `Edge cases from table above are handled`, and `No breaking changes to existing API contracts`. Leave test- and review-related items unchecked — those are handled by `/t2p-TEST` and `/t2p-REVIEW`.
7. **Update the plan's subtask status.** At the start of implementation, update the subtask's `**Status:**` in `plan.md` from "To Do" to "In Progress". The developer updates it to "Done" after merge — do not mark it Done yourself.
8. **Respect cross-subtask contracts.** If the spec's "Dependencies & Shared Contracts" section lists interfaces or models from prior subtasks, verify they exist before building on them. If they don't exist, flag the gap rather than implementing them (they belong to a different subtask/PR).
9. **Show progress as todos.** Create a todo list from the spec's Implementation Order steps at the start. Mark each step in-progress before starting it and completed immediately after the build succeeds. This gives the user live visibility into progress.
10. **Pause after each step.** After completing an Implementation Order step and verifying it compiles, **stop and present a compact summary to the user** before continuing. Format:

    **Context line:** One sentence situating this step within the overall feature (e.g., "Adds the data layer for X so that the business layer in Step 3 can consume it.").

    **Changes table** — one row per logical change (group trivial related edits):

    | File           | What                                          | Why                                                     |
    | -------------- | --------------------------------------------- | ------------------------------------------------------- |
    | `Path/File.cs` | Added `FooRepository` with `GetByFilter`      | Spec §2: needed for filtered queries from `FooBusiness` |
    | `Path/DI.cs`   | Registered `IFooRepository` → `FooRepository` | Convention: scoped registration in factory class        |

    **Decisions / Deviations** (omit section entirely if none):
    - Bullet per decision or deviation, with reason.

    Keep the entire summary **short** — no prose beyond the context line and table. The goal is fast human review, not documentation.

    **End your response after this summary.** Do NOT proceed to the next step in the same response. The user must explicitly reply before you continue. Implementing multiple steps in a single response is a violation of this rule. If the user provides feedback, address it before moving on.

11. **Record implementation notes for decisions.** If you made decisions not covered by the spec, deviated from the spec, or encountered something noteworthy during implementation, append a `## Implementation Notes` section to the spec after all steps are complete (or after the final step the user chose to implement). Only add this section if there are actual notes — do not create it for routine implementations. Format as a bullet list with the step number prefix, e.g., `- **Step 2:** Used X instead of Y because…`.

## Workflow

1. **Locate the subtask spec.** The user's input can take several forms. Resolve it to a spec file using these rules in order:

   > **ID parsing rule:** Each whitespace-delimited token is a complete identifier. Use tokens verbatim — do NOT split, truncate, or reinterpret them at underscores, hyphens, or other characters.

   a. **`PARENT_ID subtask-name`** (e.g., `PROJ-5500 drag-and-drop`) — the first token is the parent ID; list files in `<spec_directory>/<parent-id>/` and match `subtask-name` to a `spec-*.md` file.
   b. **`SUBTASK_ID`** (e.g., `PROJ-1234`) — scan all `<spec_directory>/*/plan.md` files for a subtask entry matching this ID. The plan's directory gives the parent ticket ID; the subtask's title in the plan gives the spec slug to match.
   c. **`subtask-name`** only (e.g., `drag-and-drop`) — scan all `<spec_directory>/*/` directories for a `spec-*<name>*.md` file. If exactly one match, use it. If multiple matches, list them and ask the user to clarify.

   Any remaining text after the spec identifier (e.g., `step 3`) is treated as a specific step/change number to focus on.
   If no match is found, list available specs across all `<spec_directory>/` directories and ask the user to clarify.

2. **Load persona (if configured).** Check `t2p-config.yaml` → `tech_stack` for a `persona` entry matching the workspace's primary stack (determine from the spec's file types or the workspace's `copilot-instructions.md`). If a persona file is referenced, read it and adopt its role, expertise, and behavioral guidelines for this session. If no persona is configured, proceed as a general-purpose senior developer.
3. **Read the plan** from `<spec_directory>/<ticket-id>/plan.md` — note Q&A clarifications and the subtask's position in the overall implementation order. Check "Dependencies & Shared Contracts" in the spec to understand what prior subtasks should have already delivered.
4. **Read the subtask spec** — focus on "Changes Required" and "Implementation Order."
5. **Create todos from Implementation Order.** Map each step in the spec's Implementation Order to a todo item. This gives the user a progress overview from the start.
6. If the user specified a step or change number, implement only that step. Otherwise, implement all steps in order.
7. For each step in the Implementation Order:
   a. Mark the step's todo as in-progress.
   b. Read the relevant existing files before modifying them.
   c. Implement the changes as specified (signatures, patterns, rationale).
   d. Verify the build using the skill checkpoint from Rule 4. Fix any errors before proceeding.
   e. Mark the step's todo as completed.
   f. **Present a step summary** — context line, changes table (file / what / why), decisions/deviations if any. Keep it compact per Rule 10.
   g. **End your response.** Do NOT start the next step in the same response — the user must reply first.
8. After all steps are complete (or after the user's chosen step):
   - Briefly confirm what was implemented across all steps.
   - Flag anything from the spec that couldn't be done (with reason).
   - If any decisions or deviations were noted during steps, append a `## Implementation Notes` section to the spec.
9. **Self-reflection.** Follow the self-reflection process defined in `t2p-workflow.instructions.md`.
