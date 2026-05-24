---
description: "Fetch a Jira ticket, critically analyze it, run Q&A with the user, then create a plan document with checklists."
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

# Jira Ticket Plan

> **Workflow prompt.** Read `t2p-workflow.instructions.md` for pipeline context and configuration before proceeding.

## Parsing the user's input

The **first whitespace-delimited token** in the user's message is the **complete Jira ticket ID**. Use it verbatim — do NOT split, truncate, or reinterpret it at underscores, hyphens, or other characters.

## Artifact location

Resolve the spec directory from `t2p-config.yaml` → `conventions.spec_directory`. If not configured, search the workspace for a `specs/` directory or ask the user.

The plan file is saved at:

```
<spec_directory>/<ticket-id>/plan.md
```

Where `<ticket-id>` is the Jira ticket ID in lowercase. Create the directory if it doesn't exist.

## Step 1 — Fetch the ticket

Check `t2p-config.yaml` → `mcp_servers.jira`. If Jira is enabled, use the Jira MCP server:

- Get the main ticket using the provided ticket ID. Request fields: `summary,status,description,issuetype,priority,assignee,labels`.

**If Jira MCP is not available or not configured:** Ask the user to paste the ticket details (title, description, acceptance criteria, subtasks). Use the pasted content for all subsequent steps. Note to the user that enabling the Jira MCP server automates this step.

## Step 2 — Fetch subtasks

Search for child issues of this ticket using JQL: `parent = <ticket-id>`. Request fields: `summary,status,description,issuetype,priority,assignee`.

If Jira is unavailable, ask the user to list the subtasks (title + description for each). If there are no subtasks, proceed with the parent ticket as a single work item.

## Step 3 — Fetch linked issues (context)

Search for issues linked to the main ticket using JQL: `issuekey in linkedIssues(<ticket-id>)`. Request fields: `summary,status,description,issuetype`. This helps understand dependencies and related work.

If Jira is unavailable, skip this step.

## Step 4 — Lightweight codebase impact scan

Identify key domain terms from the ticket and subtasks: entity names, service names, endpoint paths, project names, configuration keys.

Search the codebase for these terms using **file search and grep first**. Read small, targeted sections of key files only when a grep match is insufficient to assess impact (e.g., to confirm whether groundwork already exists). The goal is to map the blast radius, not to understand implementation details (that happens in `/t2p-SPEC`).

Produce a short impact summary (keep under 20 lines total):

- **Layers affected:** which of API / Business / Database / Common / ExternalAPI are touched
- **Estimated files:** count of files matching the key terms
- **Key files:** list of paths most likely to change (max 10)
- **Red flags:** anything surprising — missing entities, recent large rewrites, no test coverage for affected areas, naming mismatches

If the ticket is non-code work (infrastructure, documentation, meetings), skip this step and note "No codebase impact."

Include the impact summary in the findings presented to the user in Step 6 so that Q&A questions are grounded in actual codebase state.

## Step 5 — Critical analysis

Before creating any document, carefully analyze the ticket and subtasks for:

### Completeness

- Are acceptance criteria clearly defined? If missing, flag it.
- Does every subtask have a description? Flag empty ones.
- Are there subtasks for testing, documentation, or migration that might be missing?
- Is the Definition of Done clear?

### Consistency

- Do the subtasks actually cover the full scope of the parent ticket description?
- Are there contradictions between the parent description and subtask descriptions?
- Do estimated efforts (if present) seem reasonable relative to each other?

### Ambiguity & Risk

- Are there vague terms that could be interpreted multiple ways?
- Are there implicit assumptions that should be made explicit?
- Are there technical risks or unknowns not addressed?
- Are there dependencies on other teams, services, or deployments not mentioned?
- What could go wrong? What edge cases are not addressed?

### Architecture & Design

- Is the chosen approach (if described) well-reasoned?
- Are there simpler alternatives worth considering?
- Are there existing patterns in the codebase that should be followed or avoided?

## Step 6 — Q&A with the user

**IMPORTANT: Do NOT create the plan document yet.**

Present your findings from steps 1-5 as a compact summary:

1. **Ticket overview** — title, type, status, subtask count
2. **Impact summary** — from Step 4 (layers, key files, red flags)
3. **Issues found** — numbered list of completeness, consistency, ambiguity, and architecture concerns
4. **Assumptions** — what you'll assume if the user doesn't clarify

Then ask focused questions:

- Group related questions (max 3-4 per batch)
- Provide concrete options where possible
- Flag which questions are blocking (must answer) vs. informational (will assume default)

Wait for the user's answers before proceeding.

## Step 7 — Create the plan document

After Q&A is complete, create the plan at `<spec_directory>/<ticket-id>/plan.md`:

```markdown
# Plan: <TICKET-ID> — <Title>

**Ticket:** <ticket-id>
**Type:** <issue type>
**Status:** <status>
**Created:** <date>

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

## Step 8 — Self-reflection

Follow the self-reflection process defined in `t2p-workflow.instructions.md`.
