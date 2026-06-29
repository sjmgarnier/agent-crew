# Agent Crew

A multi-agent system for [OpenCode](https://opencode.ai) that separates thinking, planning, and execution into specialized roles — the way a construction project separates the owner, architect, and foreman.

## Table of Contents

- [What is this?](#what-is-this)
  - [The mental model](#the-mental-model)
  - [The three phases](#the-three-phases)
  - [The crew](#the-crew)
- [Getting started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Install](#install)
  - [Uninstall](#uninstall)
- [Configuration](#configuration)
  - [Model overrides](#model-overrides)
  - [Permission adjustments](#permission-adjustments)
  - [Disabling an agent](#disabling-an-agent)
  - [Troubleshooting](#troubleshooting)
- [License](#license)

---

## What is this?

Agent Crew is a set of eight specialized agents for OpenCode. Instead of one general-purpose agent doing everything, the crew splits the work into three phases — thinking, planning, execution — with purpose-built agents for each role and cost-optimized models for each task type.

**You remain in control throughout.** No phase starts without you. No agent chains into another automatically. You decide when to move from thinking to planning to building.

### The mental model

Think of yourself as the owner of a construction project:

```
                         You (owner)
                             ▲
                             │
          ┌──────────────────┼──────────────────┐
          ▼                  ▼                  ▼
     [Surveyor]         [Architect]          [Foreman]
          ▲                  ▲                  ▲
          │                  │                  │
          ▼                  ▼                  ▼
    [Groundskeeper]    [Groundskeeper]    [Groundskeeper]
     [Librarian]        [Inspector]          [Builder]
     [Examiner]                             [Inspector]
```

- **You** decide when to call the architect, when to tell the foreman to start, when to escalate a problem back to the architect.
- **Primary agents** (Surveyor, Architect, Foreman) run in separate OpenCode tabs. You switch between them.
- **Subagents** (Librarian, Examiner, Groundskeeper, Builder, Inspector) are spawned automatically by the primary agents as needed.

### The three phases

**Phase 1 — Survey (thinking)**
Switch to the **Surveyor** tab. Describe your problem or idea. The Surveyor asks clarifying questions, researches via Librarian subagents, evaluates options via the Examiner, and generates a `brief.md` when you're ready to move on.

**Phase 2 — Architect (planning)**
Switch to the **Architect** tab. It reads the brief and creates a complete plan using [OpenSpec](https://github.com/openspec/openspec):
- `proposal.md` — what and why
- `design.md` — how
- `specs/` — requirements with test scenarios
- `tasks.md` — implementation checklist

The Architect can optionally call the Inspector to validate the plan before you hand off.

**Phase 3 — Build (execution)**
Switch to the **Foreman** tab. It works through the task list, spawning Builder subagents for each task and calling the Inspector after tasks flagged for review. When something needs a decision, it escalates to you. When something needs a design change, it escalates to you and you decide whether to go back to the Architect.

### The crew

| Agent | Type | Model | Role |
|---|---|---|---|
| **Surveyor** | primary | Qwen3.7 Plus | Socratic thinking, research, brief generation |
| **Architect** | primary | Kimi K2.7 Code | Spec creation, design, architecture |
| **Foreman** | primary | Qwen3.7 Plus | Task orchestration, builder management |
| Librarian | subagent | DeepSeek V4 Flash | Codebase and external research |
| Examiner | subagent | DeepSeek V4 Flash | Analyzes research findings, identifies gaps, recommends next question |
| Groundskeeper | subagent | DeepSeek V4 Flash | Preflight checks — environment health and role-specific prerequisites |
| Builder | subagent | Kimi K2.7 Code | Task execution |
| Inspector | subagent | DeepSeek V4 Pro | Quality gate — called by Architect (pre-handoff) and Foreman (post-task) |

Models are chosen from the [OpenCode Go](https://opencode.ai/docs/go) subscription. See [Model overrides](#model-overrides) if you use a different provider.

---

## Getting started

### Prerequisites

- [OpenCode](https://opencode.ai) installed
- [OpenSpec](https://github.com/openspec/openspec) installed and initialized in each project (`openspec init` in the project root — required for the Architect's planning phase)
- A compatible model provider (default agents assume an [OpenCode Go](https://opencode.ai/docs/go) subscription — see [Model overrides](#model-overrides) to use another)

### Install

**Global** (available in all projects):

```bash
curl -fsSL https://raw.githubusercontent.com/sjmgarnier/agent-crew/main/install.sh | bash
```

**Project-local** (only available in the current project):

```bash
curl -fsSL https://raw.githubusercontent.com/sjmgarnier/agent-crew/main/install.sh | bash -s -- --local
```

> **Security note:** piping curl directly to bash executes unverified code. If you prefer, use the manual method below — it fetches through git's transport integrity instead.

**Manual** (safer):

```bash
git clone https://github.com/sjmgarnier/agent-crew.git
cp agent-crew/agents/*.md ~/.config/opencode/agents/
```

Restart OpenCode after installing. The crew agents appear in the agent switcher (Tab).

### Uninstall

```bash
# Remove global install
curl -fsSL https://raw.githubusercontent.com/sjmgarnier/agent-crew/main/install.sh | bash -s -- --uninstall

# Remove project-local install
curl -fsSL https://raw.githubusercontent.com/sjmgarnier/agent-crew/main/install.sh | bash -s -- --uninstall --local
```

---

## Configuration

### Model overrides

The agents use OpenCode Go models by default. To use a different provider or model, edit the `model:` field in each agent's frontmatter:

```yaml
# In agents/surveyor.md
---
model: anthropic/claude-sonnet-4-20250514
...
---
```

You can mix providers across agents — for example, use a cheap open model for the Librarian and a stronger model for the Architect.

### Permission adjustments

Each agent's permissions are defined in its frontmatter. Common adjustments:

| Goal | Change |
|---|---|
| Let the Foreman spawn any subagent | `"*": deny` → `"*": allow` in the `task` block |
| Let the Surveyor edit files directly | `edit: ask` → `edit: allow` |

### Disabling an agent

To disable a subagent, add `disable: true` to its frontmatter. OpenCode removes the agent from the registry — any primary agent that tries to spawn it will receive an error. Whether that surfaces as an escalation to you depends on the calling agent's error handling.

### Troubleshooting

**The Foreman escalates a decision you can't answer.**
This usually means a design gap. Switch to the Architect tab, describe the issue, let it update the specs or design, then switch back to the Foreman.

**A Builder task fails repeatedly.**
The task description is likely too vague or too large. Switch to the Foreman tab and ask it to rewrite the task into smaller, more explicit steps.

**The Inspector flags everything.**
The spec is too vague. Switch to the Architect tab and ask it to sharpen the relevant spec scenarios.

**Install fails.**
Verify OpenCode is installed (`opencode --version`) and that your internet connection can reach `raw.githubusercontent.com`. Run the install script with `bash -x` to see which step fails.

---

## License

MIT
