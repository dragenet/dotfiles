# Global Infra-Flux Agent Reconciliation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace infra-flux's duplicated specialist agents with global generic agents enabled by kube1-specific skills, while completing the staged global roster's model and reasoning-variant mappings.

**Architecture:** The staged global configuration remains portable: global agent files define role prompts and permissions, while the personal and work local-layer examples define each agent's provider model and provider-compatible reasoning variant. Infra-flux retains only project knowledge, project safety boundaries, and permission overlays that expose its skills to the appropriate global agents.

**Tech Stack:** OpenCode JSONC configuration, Markdown agent and skill definitions, shell validation scripts.

## Global Constraints

- Do not deploy the staged `~/.dotfiles/opencode/` tree, modify `~/.config/opencode`, or change `bootstrap.sh`.
- Use `permission:` configuration, never deprecated `tools:` maps.
- Preserve infra-flux secret, live-cluster, provider-cost, destructive-operation, and history-rewrite confirmation boundaries.
- Keep generic Superpowers orchestration out of kube1 project skills.
- Use provider-compatible variants: personal and work variant names differ for the same role.

---

### Task 1: Complete the Global Agent Roster

**Files:**
- Create: `agents/reviewer.md`
- Modify: `opencode.local.personal.example.jsonc`
- Modify: `opencode.local.work.example.jsonc`
- Modify: `docs/model-selection.md`

**Interfaces:**
- Consumes: the current model-selection table's role-to-provider mapping.
- Produces: a read-only global `reviewer` agent and explicit per-machine model/variant assignments for every custom global agent.

- [ ] **Step 1: Add the reviewer role**

Create `agents/reviewer.md` as a hidden-capable subagent with `read`, `glob`, `grep`, and `list` access, `edit: deny`, explicit non-destructive Bash allow rules, and no live/provider/secret/history-rewrite actions without confirmation. Require findings-first output with file and line references.

- [ ] **Step 2: Add personal and work reviewer model mappings**

Add `reviewer` to both local example files. Assign `anthropic/claude-opus-4-8` with `high` reasoning on personal and `kilo/z-ai/glm-5.1` with `high` reasoning on work.

- [ ] **Step 3: Add variants for every mapped agent**


- [ ] **Step 4: Update the source-of-truth roster table**

Add `reviewer` to `docs/model-selection.md`, and change every table row so the model and variant mapping is represented in the local example JSON files rather than implied only by prose.

### Task 2: Reduce Infra-Flux to Project Policy and Skills

**Files:**
- Delete: `.opencode/agents/adr-writer.md`
- Delete: `.opencode/agents/ansible-implementor.md`
- Delete: `.opencode/agents/ansible-reviewer.md`
- Delete: `.opencode/agents/docs-writer.md`
- Delete: `.opencode/agents/k8s-implementor.md`
- Delete: `.opencode/agents/k8s-reviewer.md`
- Delete: `.opencode/agents/report-writer.md`
- Delete: `.opencode/agents/task-planner.md`
- Delete: `.opencode/agents/web-fast-context.md`
- Delete: `.opencode/skills/kube1-orchestration/SKILL.md`
- Move: `.opencode/skills/kube1-workflow/SKILL.md` to `.opencode/skills/kube1-safety/SKILL.md`
- Modify: `.opencode/skills/kube1-architecture/SKILL.md`
- Modify: `.opencode/skills/kube1-validation/SKILL.md`
- Modify: `opencode.jsonc`
- Modify: `AGENTS.md`
- Modify: `docs/contributing/working-with-agents.md`

**Interfaces:**
- Consumes: global `devops`, `architect`, `writer`, `reviewer`, `graphify`, `web-fast-context`, and `git` roles.
- Produces: project-local safety/architecture/validation skills and project agent permission overlays for their use.

- [ ] **Step 1: Replace workflow duplication with a safety skill**

Rename `kube1-workflow` to `kube1-safety` and retain only kube1-specific safety rules. Remove planning, orchestration, review, report, and generic documentation-process rules that Superpowers and global roles already supply.

- [ ] **Step 2: Remove local domain agents and orchestration skill**

Delete the nine local agent definitions and `kube1-orchestration`. The project no longer pins models, repeats generic role prompts, or maintains a duplicate web context agent.

- [ ] **Step 3: Add project configuration overlays**

Remove project model/default-agent settings so the global local layer controls model selection. Retain the project secret and live-operation permission policy. Add `agent` permission skill overlays for `devops`, `architect`, `writer`, and `reviewer` that allow the relevant kube1 skills without redefining their global prompts.

- [ ] **Step 4: Rewrite project routing documentation**

Update `AGENTS.md` and `docs/contributing/working-with-agents.md` to route infrastructure to `@devops`, architecture to `@architect`, documentation to `@writer`, and read-only review to `@reviewer`. Retain graphify-first discovery, template-versus-kube1 ownership, and explicit live-action approval.

### Task 3: Validate and Compare

**Files:**
- Modify: `docs/model-selection.md`

**Interfaces:**
- Consumes: the completed global roster and infra-flux project layer.
- Produces: validated configuration and a full agent/model/variant comparison in the final handoff.

- [ ] **Step 1: Validate JSON and agent frontmatter**

Run JSON parsing for all three JSONC-compatible JSON files after removing comments where necessary, run `bash scripts/check-skill-whitelists.sh` from the staged global configuration, and parse each custom agent frontmatter block with Ruby's standard YAML parser.

- [ ] **Step 2: Verify deleted-role references are gone**

Search infra-flux configuration and contributor docs for removed local agent names and `kube1-orchestration`. Confirm remaining references point to global agent names and retained skills.

- [ ] **Step 3: Inspect final diffs and roster coverage**

Inspect both worktrees' diffs and verify every global custom agent, including `reviewer`, has a personal model/variant pair and a work model/variant pair.

## Review Checklist

- Global `reviewer` is read-only and uses a high reasoning variant in both local model templates.
- Existing agent assignments retain the variants documented as provider-compatible in `docs/model-selection.md`.
- Infra-flux contains no local role agents and no duplicate orchestration skill.
- Infra-flux safety, architecture, validation, and graphify knowledge remain locally available.
- No live config, bootstrap, or unrelated working-tree changes are modified.
