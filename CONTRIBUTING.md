# Contributing

Thanks for your interest in contributing to ai-workflows!

## Adding a New Workflow

Each workflow lives in its own folder under `workflows/`. Follow these steps:

### 1. Create the workflow folder

```
workflows/<workflow-name>/
├── README.md                    ← Workflow-specific documentation
├── <prefix>-*.prompt.md         ← Prompt files (one per stage)
├── <prefix>-config.yaml         ← User-customizable settings
└── <prefix>-*.instructions.md   ← Shared instructions loaded by prompts
```

Choose a short, unique **prefix** for your workflow's files (e.g., `t2p-` for ticket-to-pr). This avoids name collisions when users install multiple workflows into the same prompts folder.

### 2. Write prompt files

All stage prompts use `.prompt.md` with YAML frontmatter:

```yaml
---
description: "Short description shown in the command palette."
argument-hint: "What the user should type after the command"
agent: "agent"
tools: ["read", "search", "edit"]
---
```

Guidelines:

- Each prompt should be a self-contained stage — users run them in separate chat sessions.
- Reference your workflow's `*-config.yaml` and `*.instructions.md` for shared settings.
- Use `<spec_directory>` or similar config-driven paths — never hardcode user-specific paths.
- End each prompt with an optional self-reflection step for continuous improvement.
- Use **skill checkpoints** at action boundaries where a user's skill could take over (see below).

### 3. Use skill checkpoints

Workflow stages should define **skill checkpoints** at moments where an available skill can replace default behavior (building, testing, committing, creating PRs, etc.). This lets users' existing skills plug into the workflow automatically.

Add a checkpoint as a blockquote inside the relevant step:

```markdown
> **Skill checkpoint — <action>:** Check available skills for one that handles
> <what the action does>. If found, read and follow that skill. Default: <fallback>.
```

Guidelines:

- Place checkpoints at **action boundaries** — moments where the workflow does something concrete (build, test, commit, push, create PR).
- Keep the action description broad enough to match skills by semantic relevance, not by exact name.
- Always provide a **default fallback** so the workflow works without any skills installed.
- Don't over-checkpoint — only add them where a user would realistically have a skill (not for reading files or scanning code).

### 3. Write instructions files

Instructions use `.instructions.md` with YAML frontmatter:

```yaml
---
description: "When this instruction should be loaded — VS Code matches this against prompt context."
---
```

Use instructions for shared context that multiple prompts reference (pipeline overview, conventions, configuration docs).

### 4. Add a config file

Create `<prefix>-config.yaml` with user-customizable settings. Document each setting with comments. Common settings:

- MCP server toggles
- Tech stack mappings
- Path conventions
- Naming conventions

### 5. Write the workflow README

Each workflow needs a `README.md` explaining:

- What the workflow does (one paragraph)
- The stage pipeline (visual flow)
- Quick start instructions
- How to configure it
- File listing
- How to extend it

### 6. Update the root README

Add your workflow to the table in the root [README.md](README.md):

```markdown
| [my-workflow](workflows/my-workflow/) | Description | [README](workflows/my-workflow/README.md) |
```

## Conventions

- **Prefix all files** with your workflow's prefix to avoid collisions across workflows.
- **Keep prompts standalone** — each prompt should work in a fresh chat session.
- **Separate generic from domain** — workflow logic goes in prompt/instruction files; project-specific settings go in the config YAML.
- **No hardcoded paths** — use config-driven paths for artifacts.
- **VS Code compatibility** — prompt files must be at the top level of the user's prompts folder to be discovered. Workflows are organized in this repo for clarity but are installed flat.

## Shared Documentation

The `docs/` folder is for cross-workflow documentation, design decisions, and architecture notes that apply to the repository as a whole.
