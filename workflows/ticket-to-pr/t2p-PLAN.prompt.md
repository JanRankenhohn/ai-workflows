---
description: "Fetch a Jira ticket, critically analyze it, run Q&A with the user, then create a plan document with subtask breakdown."
argument-hint: "ticket-id"
agent: "agent"
tools:
  [
    "jira/*",
    "edit/editFiles",
    "vscode/askQuestions",
    "search",
    "edit/createFile",
    "execute/runInTerminal",
  ]
---

# Ticket Plan

> **Workflow prompt.** Read `t2p-workflow.instructions.md` for pipeline context and configuration before proceeding.

## Step 1 — Fetch ticket data

If Jira MCP is configured (`t2p-config.yaml` → `mcp_servers.jira`), fetch all of the following:

- **Main ticket** (`<ticket-id>`): summary, status, description, issuetype, priority, assignee, labels
- **Subtasks** (JQL `parent = <ticket-id>`): summary, status, description, issuetype, priority, assignee
- **Linked issues** (JQL `issuekey in linkedIssues(<ticket-id>)`): summary, status, description, issuetype

If Jira is unavailable, ask the user to paste ticket details (title, description, acceptance criteria, subtasks). If there are no subtasks, proceed with the parent ticket as a single work item.

## Step 2 — Lightweight codebase impact scan

Identify key domain terms from the ticket and subtasks (entity names, service names, endpoint paths, configuration keys). Search the codebase using **file search and grep first**; read targeted sections only when grep matches are insufficient. The goal is to map the blast radius, not to understand implementation details (that happens in `/t2p-SPEC`).

Produce a short impact summary (max 15 lines) covering: layers affected, key files likely to change (max 10), and red flags (missing entities, no test coverage, naming mismatches).

If the ticket is non-code work, skip this step and note "No codebase impact."

## Step 3 — Critical analysis

Analyze the ticket and subtasks for:

- Missing or vague acceptance criteria / Definition of Done
- Subtasks with empty descriptions or that don't cover the parent's full scope
- Contradictions between parent and subtask descriptions
- Missing subtasks (testing, migration, documentation)
- Ambiguous terms, implicit assumptions, unaddressed edge cases
- Dependencies on other teams/services not mentioned
- Whether the described approach is the simplest viable option
- Existing codebase patterns that should be followed

**CONTEXT.md filter:** Do NOT raise concerns that are already resolved in CONTEXT.md or ADRs. CONTEXT.md decisions override ticket ambiguity — they are the output of the EXPLORE stage. Only flag genuinely unresolved issues.

## Step 4 — Decomposition

Propose a breakdown into subtasks/PRs. Consider:

- **Natural code boundaries** — layers, files, modules that change together
- **Testability in isolation** — can each subtask be verified independently?
- **Risk isolation** — risky changes (migrations, API contracts) in their own PR
- **The `one_subtask_one_pr` convention** from config
- **Minimum viable split** — could this be one PR? If not, what's the minimum set of PRs where each is independently mergeable and testable?

For small stories with no existing subtasks, the primary value is deciding scope boundaries: what's in this PR vs. deferred to a follow-up ticket.

## Step 5 — Q&A with the user

**Do NOT create the plan document yet.**

Present findings from steps 1-4 as a compact summary:

1. **Ticket overview** — title, type, status, subtask count
2. **Impact summary** — layers, key files, red flags
3. **Proposed breakdown** — subtask/PR structure with brief rationale
4. **Issues found** — only genuinely unresolved concerns (not answered by CONTEXT.md)
5. **Assumptions** — what you'll assume if the user doesn't clarify

Then ask focused questions **using the `vscode_askQuestions` tool** (interactive option selection UI — do NOT just write questions as plain text in chat). Max 3-4 per batch, with concrete options (use the `options` array). Focus questions on:

- **Decomposition choices** — single PR vs. split, what to include/defer
- **Sequencing trade-offs** — which subtask first, blocking dependencies
- **Scope decisions** — what's in/out for this ticket vs. follow-up

Do NOT re-ask questions already answered in CONTEXT.md or ADRs. Wait for answers before proceeding.

## Step 6 — Create the plan document

After Q&A is complete, save the plan to the artifact path defined in the workflow instructions:

```markdown
# Plan: <TICKET-ID> — <Title>

**Ticket:** <ticket-id>
**Type:** <issue type>
**Status:** <status>

## Summary

<2-3 sentences describing what this ticket delivers>

## Clarifications from Q&A

<Numbered list of all Q&A decisions — these are binding for subsequent prompts>

## Subtasks

### 1. <Subtask title>

- **Ticket:** <subtask-id> (if exists)
- **Status:** To Do
- **Scope:** <1-2 sentence description>
- **Dependencies:** <other subtasks this depends on>

### 2. <Next subtask>

...

## Implementation Order

<Recommended order to implement subtasks, with rationale for sequencing>

## Open Issues

<Anything unresolved that the developer should decide before starting>
```
