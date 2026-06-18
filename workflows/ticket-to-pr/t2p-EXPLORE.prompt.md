---
description: "Optional domain exploration session. Build shared understanding of the problem space before planning. Produces CONTEXT.md glossary and optional ADRs."
argument-hint: "ticket-id (or paste ticket details)"
agent: "agent"
tools:
  [
    "jira/*",
    "read",
    "search",
    "edit/createFile",
    "edit/editFiles",
    "vscode/askQuestions",
  ]
---

# Domain Exploration

> **Workflow prompt.** Read `t2p-workflow.instructions.md` for pipeline context and configuration before proceeding.

Interactive grilling session to resolve ambiguity, sharpen terminology, and surface hidden complexity before `/t2p-PLAN`.

## Step 1 — Gather ticket context

If Jira MCP is configured, fetch the main ticket, subtasks, and linked issues. Otherwise ask the user to paste ticket details. Extract key domain terms, entity names, and relationships as starting points.

**JQL quoting:** Always quote issue key values in JQL queries (e.g., `parent = "PROJ-123"`, not `parent = PROJ-123`). Project keys containing underscores or other special characters break unquoted JQL parsing.

## Step 2 — Proactive codebase exploration

Before asking the user anything, search the codebase for domain terms from the ticket — entity names, service names, model names, type definitions. Identify naming conventions and spot contradictions between ticket language and code. Also check for existing `CONTEXT.md` or `docs/adr/` files.

Scan discipline: search/grep freely, read only relevant sections via line ranges, max 5 full file reads.

## Step 3 — Present findings and start grilling

Present a compact summary: domain terms found, how they map to code, and conflicts/gaps. Then begin the interactive grilling session — **one question at a time**, waiting for each answer.

### Grilling behaviors

- **Challenge terminology.** When the user uses a term that conflicts with the existing language in CONTEXT.md, call it out immediately. _"Your glossary defines 'cancellation' as X, but you seem to mean Y — which is it?"_
- **Sharpen fuzzy language.** When the user uses vague or overloaded terms, propose a precise canonical term. _"You're saying 'account' — do you mean the Customer or the User? Those are different things."_
- **Discuss concrete scenarios.** When domain relationships are being discussed, stress-test them with specific scenarios. Invent scenarios that probe edge cases and force the user to be precise about the boundaries between concepts.
- **Cross-reference with code.** When the user states how something works, check whether the code agrees. If you find a contradiction, surface it: _"Your code cancels entire Orders, but you just said partial cancellation is possible — which is right?"_
- **Explore instead of asking.** If a question can be answered by reading the code, read the code.
- **Delivery.** Use the `askQuestions` tool for all grilling questions. Provide selectable options when the answer space is bounded (e.g., enum values, yes/no, pick-from-list). Use freeform when the answer requires explanation.

## Step 4 — Capture artifacts inline

### CONTEXT.md

Update `<spec_directory>/<ticket-id>/CONTEXT.md` as terms are resolved — don't batch. Create the file lazily on first term.

```markdown
# <Context Name>

<One sentence: what this context covers.>

## Language

**<Term>**: <One or two sentence definition.>
_Avoid_: <synonym1>, <synonym2>
```

Rules: be opinionated (pick one term, list others as _Avoid_), keep definitions tight, only domain-specific terms, show relationships, no implementation details. CONTEXT.md is a glossary — not a spec.

### ADRs (sparingly)

Only create an ADR when **all three** hold: (1) hard to reverse, (2) surprising without context, (3) result of a real trade-off. Format: title + 1-3 sentence summary. Save to `<spec_directory>/<ticket-id>/adr/NNNN-<slug>.md`.

## Step 5 — Handoff

Summarize: terms defined, ADRs created, key insights (2-3 bullets), and recommend _"Run `/t2p-PLAN <ticket-id>`"_.

## Step 6 — Self-reflection

Follow the self-reflection process defined in `t2p-workflow.instructions.md`.
