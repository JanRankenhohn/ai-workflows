# 🎫 ticket-to-pr

A structured AI development workflow for **VS Code + GitHub Copilot** that takes you from a Jira ticket to a pull request — with planning, specification, implementation, testing, and review stages.

```
/t2p-JIRA → /t2p-SPEC → /t2p-IMPLEMENT → /t2p-TEST → /t2p-REVIEW → /t2p-CREATE-PR
```

Each stage runs in its own chat session with developer review between stages.

- 🎯 **Ticket challenge before planning** — the AI challenges your ticket in detail and gains common understanding together with you about the domain and problem to solve.
- 📋 **Spec before code** — the AI scans your codebase and writes a technical spec. You review it. Then it implements exactly what was agreed.
- 🔨 **Step-by-step implementation** — changes are made one logical step at a time with a build check and your approval after each.
- 🔍 **Built-in review** — the AI reviews its own work against the spec and your project's code quality criteria before you create the PR.
- 🧹 **Context isolation** — each stage runs in a fresh chat session. No context window bloat, no confused models.

> **Current integrations:** Jira (issue tracking) and Azure DevOps (pull requests). Support for additional platforms (GitHub, GitLab, Linear, etc.) is planned. The workflow logic itself is stack-agnostic — configure it for your tech stack, project conventions, and review criteria.

## 🔌 Prerequisites — MCP Servers

This workflow uses [MCP (Model Context Protocol)](https://modelcontextprotocol.io/) servers to interact with external services. Install and configure the servers you need, then enable them in `t2p-config.yaml`.

| Config key     | Purpose       | Stage(s)                   | Example server                                                    |
| -------------- | ------------- | -------------------------- | ----------------------------------------------------------------- |
| `jira`         | Fetch tickets | `/t2p-JIRA`, `/t2p-REVIEW` | [mcp-atlassian](https://github.com/sooperset/mcp-atlassian)       |
| `azure_devops` | Create PRs    | `/t2p-CREATE-PR`           | [azure-devops-mcp](https://github.com/microsoft/azure-devops-mcp) |

**Without MCP servers:** The workflow still works — `/t2p-JIRA` will ask you to paste the ticket details, and `/t2p-CREATE-PR` will generate the PR description for you to create manually. The middle stages (`/t2p-SPEC`, `/t2p-IMPLEMENT`, `/t2p-TEST`, `/t2p-REVIEW`) don't require any MCP servers.

## 🚀 Quick Start

1. Run the install script to copy workflow files into your VS Code prompts folder:

   ```bash
   # macOS / Linux
   ./install.sh

   # Windows (PowerShell)
   .\install.ps1
   ```

   Or install to a specific workspace instead:

   ```bash
   ./install.sh --workspace /path/to/project
   .\install.ps1 -Workspace C:\path\to\project
   ```

2. Edit `t2p-config.yaml`:
   - Enable your MCP servers (Jira, Azure DevOps)
   - Set your spec directory path
   - Map your tech stacks to review criteria and optional persona files

3. Run `/t2p-JIRA PROJ-123` in Copilot Chat.

## ⚙️ How It Works

| Stage            | Command          | What it does                                                              |
| ---------------- | ---------------- | ------------------------------------------------------------------------- |
| 🎯 **Plan**      | `/t2p-JIRA`      | Fetch ticket, critical analysis, Q&A, group subtasks into PR-sized chunks |
| 📋 **Specify**   | `/t2p-SPEC`      | Scan codebase, Q&A, create per-subtask technical spec                     |
| 🔨 **Implement** | `/t2p-IMPLEMENT` | Implement from spec step-by-step, pause after each step for review        |
| 🧪 **Test**      | `/t2p-TEST`      | Generate unit tests from the spec's test plan                             |
| 🔍 **Review**    | `/t2p-REVIEW`    | Review implementation against spec + code quality criteria                |
| 🚀 **Ship**      | `/t2p-CREATE-PR` | Create PR with generated description from diff + Jira context             |

See [t2p-workflow.instructions.md](t2p-workflow.instructions.md) for full pipeline documentation and [t2p-config.yaml](t2p-config.yaml) for configuration.

## 🎛️ Customization Layers

The workflow separates generic logic from project-specific configuration:

| Layer                     | What                                                         | Where                                                  |
| ------------------------- | ------------------------------------------------------------ | ------------------------------------------------------ |
| **Generic (this repo)**   | Workflow logic, review criteria categories, prompt structure | `t2p-*.prompt.md`, `*.instructions.md`                 |
| **Domain (your project)** | MCP servers, tech stack, spec directory, project conventions | `t2p-config.yaml`, workspace `copilot-instructions.md` |

You never need to fork or edit the generic files — configure the domain layer instead.

## 📂 Files

```
t2p-*.prompt.md                  6 workflow stages (JIRA, SPEC, IMPLEMENT, TEST, REVIEW, CREATE-PR)
t2p-config.yaml                  User-customizable settings
t2p-workflow.instructions.md     Pipeline documentation, loaded by all prompts
t2p-spec-template.md             Template used by /t2p-SPEC
```

## 🏗️ Design Principles

- **Prompts, not plugins.** Everything is `.prompt.md` and `.instructions.md` files. No build step, no runtime, no lock-in.
- **Configure, don't fork.** Workflow logic lives in prompt files. Your project settings live in a YAML config. Update the workflow without losing your config.
- **Works without MCP servers.** Jira and Azure DevOps integrations are optional — the workflow falls back to manual input. The core stages need nothing but Copilot.

## 🧩 Extending

- **Review criteria:** Create `<stack>-review-criteria.instructions.md` and reference it in `t2p-config.yaml` → `tech_stack` → `review_criteria`. The `/t2p-REVIEW` prompt will load it automatically.
- **Stack persona:** Create an `.agent.md` file defining a domain expert role and reference it in `t2p-config.yaml` → `tech_stack` → `persona`. The `/t2p-SPEC` and `/t2p-IMPLEMENT` prompts will adopt that persona.
