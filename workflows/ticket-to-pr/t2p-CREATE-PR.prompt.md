---
description: "Create a pull request in Azure DevOps from the current branch, generating a description from the diff and Jira context."
argument-hint: "PROJ-1234 (or PROJ-5500 drag-and-drop, or just drag-and-drop)"
agent: "agent"
tools: ["jira/*", "ado/*", "execute/runInTerminal", "read", "search"]
---

# Create Pull Request

> **Workflow prompt.** Read `t2p-workflow.instructions.md` for pipeline context and configuration before proceeding.

You are creating a pull request in Azure DevOps for the current feature branch. The user provides input to locate the spec and Jira ticket context.

Artifacts live in the spec directory configured in `t2p-config.yaml` → `conventions.spec_directory`:

- `<spec_directory>/<ticket-id>/plan.md` — coordination document with Q&A clarifications and implementation order across subtasks
- `<spec_directory>/<ticket-id>/spec-<subtask-slug>.md` — the subtask-specific spec

## Step 1 — Resolve the spec and Jira ticket

1. **Locate the subtask spec.** The user's input can take several forms. Resolve it to a spec file using these rules in order:

   > **ID parsing rule:** Each whitespace-delimited token is a complete identifier. Use tokens verbatim — do NOT split, truncate, or reinterpret them at underscores, hyphens, or other characters.

   a. **`PARENT_ID subtask-name`** (e.g., `PROJ-5500 drag-and-drop`) — the first token is the parent ID; list files in `<spec_directory>/<parent-id>/` and match `subtask-name` to a `spec-*.md` file.
   b. **`SUBTASK_ID`** (e.g., `PROJ-1234`) — scan all `<spec_directory>/*/plan.md` files for a subtask entry matching this ID. The plan's directory gives the parent ticket ID; the subtask's title in the plan gives the spec slug to match.
   c. **`subtask-name`** only (e.g., `drag-and-drop`) — scan all `<spec_directory>/*/` directories for a `spec-*<name>*.md` file. If exactly one match, use it. If multiple matches, list them and ask the user to clarify.

   If no match is found, list available specs across all `<spec_directory>/` directories and ask the user to clarify.

2. **Read the spec** — extract the summary, changes required, edge cases, and any implementation notes.

3. **Read the plan** — extract Q&A clarifications and the subtask's ticket ID if not already known.

4. **Fetch the Jira ticket** using `jira_get_issue` with fields: `summary,status,description,issuetype,parent`.
   - If the ticket is a subtask, also fetch the parent story for broader context.
   - Extract the ticket URL for the PR description.
   - If Jira fetch fails, continue without ticket context and note this to the user.

## Step 2 — Gather git context

Run these commands in the terminal:

```
git rev-parse --abbrev-ref HEAD
git remote get-url origin
git fetch origin main
git diff origin/main...HEAD --stat
git diff origin/main...HEAD
git log origin/main..HEAD --oneline
```

From this, determine:

- **Source branch name** (current branch)
- **Repository name** (from the remote URL — extract the repo name from the Azure DevOps URL path)
- **Project name** (from the remote URL — extract the project name from the Azure DevOps URL path)
- **Diff summary** — what files changed and what the changes do
- **Commit messages** — for additional context on what was done

Ensure the current branch has been pushed. If commits exist that haven't been pushed, ask the user whether to push first.

## Step 3 — Generate the PR description

> **Skill checkpoint — pull request description:** Check available skills for one that handles PR description generation, PR title conventions, or PR templates. If found, read and follow that skill instead of the template below. Default: use the template structure below.

Write the PR description following this template structure:

```markdown
# {Title: short imperative summary, e.g. "Add batch export for manufacturing steps"}

{TICKET_URL}

## Changes

{2-3 sentences of context: what problem this solves and why the change is needed}

### {Feature / Flow A}

- …

### {Feature / Flow B}

- …

## Notes for reviewers

- …

## Test notes

- …
```

Content guidelines:

- **Title:** Short imperative summary derived from the Jira ticket summary and the actual changes.
- **Ticket URL:** The Jira ticket URL (constructed from the Jira base URL and ticket key).
- **Changes section:** Start with 2-3 sentences of context. Group by feature or user-facing flow, not by file or layer. Keep bullets concise — state WHAT changed. Only explain WHY when non-obvious. If the same logic applies to multiple places, say "same logic" — don't repeat the description. Do not document intermediate implementation decisions the reviewer has no context for — the reviewer only sees the end result. Do not document trivial details obvious from the diff (config values, DI registrations, key formats).
- **Notes for reviewers:** Only include things a reviewer must act on — areas needing extra scrutiny, known limitations, follow-up tickets. Include implementation decisions visible in the code that might surprise a reviewer. Skip informational trivia. Omit the section entirely if there's nothing noteworthy.
- **Test notes:** Document test paths for local testing. Show compact flow-like descriptions, only for non-trivial test cases. Omit the section entirely if tests are straightforward.

Use the spec's Implementation Notes (if any) for reviewer-relevant decisions. Use the diff and commit log for the actual changes list.

## Step 4 — Present the PR for approval

Present the following to the user before creating the PR:

```
**Repository:** {project}/{repo}
**Source:** {branch} → **Target:** main
**Title:** {PR title}
**Draft:** No

--- PR Description ---
{generated description}
-----------------------
```

Ask the user to review and confirm, or request changes. The user may:

- Adjust the title or description
- Request draft mode
- Change the target branch
- Add or remove sections

Iterate until the user approves.

## Step 5 — Create the PR

> **Skill checkpoint — create pull request:** Check available skills for one that handles PR creation, git push workflows, or platform-specific PR tooling. If found, read and follow that skill. Default: use Azure DevOps MCP or manual creation as described below.

Check `t2p-config.yaml` → `mcp_servers.azure_devops`.

**If Azure DevOps MCP is available:** Push the branch if needed, then create the PR using the `ado/*` MCP tools. Provide:

- **Repository**: repository name from the remote URL
- **Project**: project name from the remote URL
- **Source branch**: `refs/heads/{branch}`
- **Target branch**: `refs/heads/main` (or user-specified target)
- **Title**: the approved PR title
- **Description**: the approved PR description (max 4000 chars — if longer, truncate the least important sections)
- **Draft**: as specified by the user (default: false)

After creation, report the PR URL and ID to the user.

**If Azure DevOps MCP is not available:** Push the branch if needed, then present the PR description in a copyable format and instruct the user to create the PR manually in their platform's UI. Include the source branch, target branch, title, and description.

## Step 6 — Self-reflection

Follow the self-reflection process defined in `t2p-workflow.instructions.md`.
