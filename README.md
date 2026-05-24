# 🤖 ai-workflows

**Structured AI development workflows for VS Code + GitHub Copilot.**

Drop-in prompt files that guide Copilot through multi-stage development — invokable, reliable workflows that are customizable to your domain and tech stack. No extensions, no dependencies, just prompts.

## 🧩 The Problem

AI coding agents are powerful but undirected. Without structure, you get inconsistent results, forgotten edge cases, and PRs that need heavy rework. You end up spending more time steering the AI than writing code yourself.

These workflows fix that by giving the AI a **repeatable engineering process** — with developer review at every step. They automate what AI is best at (scanning codebases, generating boilerplate, catching inconsistencies) while keeping the human in control of every decision that matters.

## 📦 Workflows

Each workflow is a self-contained set of prompt files (`.prompt.md`), a shared instruction file (`.instructions.md`), and a config YAML — customizable to your domain, tech stack, and tooling.

| Workflow                                       | Stages | Description                                                                                                                                   |
| ---------------------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------- |
| 🎫 **[ticket-to-pr](workflows/ticket-to-pr/)** | 6      | From Jira ticket to a clean PR — plan, spec, implement, test, review, and ship. One command per stage, full developer control between stages. |

## 🚀 Quick Start

```bash
git clone https://github.com/<your-org>/ai-workflows.git
cd ai-workflows

# Install to VS Code (picks the right path for your OS)
./install.sh        # macOS / Linux
.\install.ps1       # Windows
```

Configure the workflow of your choice, e.g. in `t2p-config.yaml` - See the workflows ReadMe for full setup docs.

## ❓ And what about Skills, instructions etc.?

Everyone loves Skills. But each AI artifact serves a different purpose:

| Artifact                              | What it does                                                                                            | Scope                   |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------- | ----------------------- |
| **Instructions** (`.instructions.md`) | Persistent rules loaded into every chat — coding conventions, naming patterns, architecture constraints | Always-on context       |
| **Skills** (`SKILL.md`)               | Single-action capabilities — "run tests", "format code", "search logs"                                  | One-shot tasks          |
| **Agents** (`.agent.md`)              | Specialized personas with restricted tools — "C# expert", "security reviewer"                           | Role + tool scoping     |
| **Prompts** (`.prompt.md`)            | Reusable user-facing commands — `/fix-bug`, `/add-endpoint`                                             | Single-step actions     |
| **Workflows** (this repo)             | Multi-stage orchestration — prompt chains with artifacts, Q&A, and review gates between stages          | Multi-session processes |

**Workflows don't replace other artifacts — they compose them.** A workflow prompt can load an agent persona, reference your project's instructions, and invoke skills as part of its steps. The workflow adds what the other artifacts can't provide on their own:

- 🔗 **Stage sequencing** — output from one stage becomes input for the next (plan → spec → code → tests → review → PR)
- 📄 **Persistent artifacts** — specs and plans are saved to disk so context survives across chat sessions
- ✋ **Review gates** — the developer reviews and approves between every stage
- ⚙️ **Configuration** — one YAML file adapts the entire pipeline to your stack, MCP servers, and conventions

Use instructions for your project rules, skills for your toolbox, agents for expert roles — and workflows to tie them all together into a repeatable development process.

### Already using skills? They work automatically.

Workflow stages define **skill checkpoints** — moments where the workflow pauses to check if you have a relevant skill available. If you do, the workflow uses your skill instead of its default behavior. No configuration needed — skills are matched by their description, not by name.

| Without workflows | With workflows |
|---|---|
| You manually remember to invoke `verify` after coding | `/t2p-IMPLEMENT` invokes your `verify` skill after every step |
| You run `commit` before pushing | `/t2p-CREATE-PR` picks up your `commit` skill automatically |
| You have a `pr-title-convention` skill but invoke it ad hoc | `/t2p-CREATE-PR` discovers and applies it when generating the PR |

**Your existing skills become more valuable** when orchestrated by a workflow. You don't change anything — install the workflow, and your skills are used at the right moments.

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on adding or improving workflows.

## 📄 License

MIT
