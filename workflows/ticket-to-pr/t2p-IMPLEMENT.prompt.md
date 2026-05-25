---
description: "Implement changes from a subtask's spec document, following the Implementation Order step by step."
argument-hint: "PROJ-1234 (or PROJ-5500 drag-and-drop, or just drag-and-drop)"
agent: "agent"
tools: ["read", "search", "edit", "execute/runInTerminal"]
---

# Implement from Spec

> **Workflow prompt.** Read `t2p-workflow.instructions.md` for pipeline context and configuration before proceeding.

You are implementing code changes defined in a subtask's spec document. The user provides input to locate the spec, and optionally a specific step or change number to focus on.

## Rules

1. **Follow the spec's Implementation Order exactly.** Do not reorder or skip steps.
2. **Do NOT write tests.** Tests are handled by `/t2p-TEST`. Skip test-related items in the spec.
3. **Project conventions override spec details.** The workspace's `copilot-instructions.md` is authoritative for naming and architecture; the spec is authoritative for structure and scope. When they conflict, follow conventions and note the deviation.
4. **Build once per Implementation Order step**, not after every file change.
   > **Skill checkpoint — verify build:** Check available skills for build verification / CI readiness. If found, follow that skill. Default: run the workspace's build command. Fix errors before moving on.
5. **Stay in scope.** Only implement what the spec describes. Do not refactor, add features, or "improve" things outside the spec.
6. **Update the spec checklist after all steps are complete.** Check off: `Implementation matches this spec`, `Edge cases from table above are handled`, `No breaking changes to existing API contracts`. Leave test- and review-related items unchecked.
7. **Update the plan's subtask status.** Set status to "In Progress" at the start. The developer marks "Done" after merge.
8. **Respect cross-subtask contracts.** Verify that interfaces/models from prior subtasks exist before building on them. Flag gaps rather than implementing them.
9. **Show progress as todos.** Create a todo list from the Implementation Order steps. Mark each in-progress/completed as you go.
10. **Pause after each step.** After completing a step and verifying it compiles, present a compact summary, then **stop — do not proceed until the user replies.**

    - **Context line:** One sentence situating this step in the overall feature.
    - **Changes table** (file / what / why) — one row per logical change.
    - **Decisions / Deviations** — bullet list, omit if none.
    - **Optional: Flow Diagram** data or usage flow - if any meaningful non-trivial flow can be shown.

    If the user provides feedback, address it before moving on.

11. **Record implementation notes.** If you made decisions or deviations not covered by the spec, append a `## Implementation Notes` section to the spec after the final step. Only add if there are actual notes. Format: `- **Step 2:** Used X instead of Y because…`.

## Workflow

1. **Locate the subtask spec.** Resolve the user's input to a spec file:
   a. **`PARENT_ID subtask-name`** — match `subtask-name` to a `spec-*.md` in `<spec_directory>/<parent-id>/`.
   b. **`SUBTASK_ID`** — scan `plan.md` files for this ID; derive the spec slug from the subtask title.
   c. **`subtask-name` only** — scan all spec directories for `spec-*<name>*.md`. If ambiguous, ask.

   Remaining text after the identifier (e.g., `step 3`) targets a specific step.

2. **Load persona.** If `t2p-config.yaml` → `tech_stack` has a `persona` for this workspace's stack, read and adopt it. Otherwise proceed as a senior developer.
3. **Read the plan** — note Q&A clarifications, subtask position, and cross-subtask dependencies.
4. **Read the subtask spec** — focus on "Changes Required" and "Implementation Order."
5. **Create todos** from the Implementation Order steps.
6. If the user specified a step number, implement only that step. Otherwise, implement all steps in order.
7. For each step: read relevant files, implement changes, verify build (Rule 4), then follow Rules 9 and 10.
8. After all steps are complete (or the user's chosen step):
   - Confirm what was implemented. Flag anything that couldn't be done.
   - Apply Rule 6 (spec checklist) and Rule 11 (implementation notes) if applicable.
