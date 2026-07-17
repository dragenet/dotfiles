# Agent Artifact Placement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `.agents/` the sole canonical location for Superpowers and Graphify project artifacts.

**Architecture:** Move existing artifact trees into `.agents/superpowers/` and `.agents/graphify-out/`. Global Graphify instructions invoke `graphify extract <project> --out <project>/.agents` and all read operations pass `--graph <project>/.agents/graphify-out/graph.json`, eliminating root-path aliases.

**Tech Stack:** OpenCode configuration, Graphify CLI, Markdown documentation, Git-aware file moves.

## Global Constraints

- Do not create `.ai/`, `.superpowers/`, `.agents/superpowers/`, or root `graphify-out/` artifact aliases.
- Preserve all existing artifact contents during the move.
- Use `graphify extract` with `--out`; do not use `graphify update` because it cannot select an output directory.
- Update every active configuration, workflow, ignore rule, and documentation reference to the canonical path.

---

### Task 1: Establish Global Placement Rules

**Files:**
- Move: `.agents/superpowers/` to `.agents/superpowers/`
- Modify: `AGENTS.md`, `agents/graphify.md`, `skill/graphify/SKILL.md`, related Graphify references, `opencode.jsonc`, and config documentation

- [ ] Move global Superpowers design and plan artifacts to `.agents/superpowers/`.
- [ ] Add the global canonical placement rule and Graphify CLI invocation policy.
- [ ] Replace global documentation references from `.agents/superpowers/` and root `graphify-out/` with `.agents/...` paths.

### Task 2: Migrate Infra-Flux Artifacts And Policy

**Files:**
- Move: `.ai/`, `.superpowers/`, `.agents/superpowers/`, and `graphify-out/` into `.agents/`
- Modify: `.gitignore`, `opencode.jsonc`, `AGENTS.md`, `.opencode/skills/graphify/`, and affected documentation

- [ ] Move all existing Infra-Flux plans, reports, SDD artifacts, specs, and Graphify data without data loss.
- [ ] Update project instructions, watcher ignores, Git ignores, and repository-layout documentation to the canonical paths.
- [ ] Update Graphify invocations to use the explicit output and graph paths.

### Task 3: Verify The Migration

**Files:**
- Test: both repository configurations and moved artifact trees

- [ ] Confirm all four legacy artifact roots are absent in infra-flux and the global config's legacy `.agents/superpowers/` tree is absent.
- [ ] Confirm canonical directories contain the moved artifacts.
- [ ] Validate JSON, Markdown frontmatter, Graphify command references, and whitespace diffs.
