# Model & Provider Selection

**Source of truth:** design spec §3 ("Model & provider layer"),
`docs/superpowers/specs/2026-07-16-opencode-config-redesign-design.md`.
This document duplicates that section's tables and justifications in a
standalone, expanded form. If the two ever disagree, the spec wins.

---

## 1. Overview

The shared, tracked `opencode.json` carries **no** `model`, `small_model`, or
machine-specific `provider` block. Those live in a per-machine, gitignored
`opencode.local.json`, deep-merged on top of the base config via the
`OPENCODE_CONFIG` env var. This keeps the same `opencode.json` fully portable
between the personal machine and the work machine, while each machine picks
its own models and providers.

Two machines, four providers total, one shared agent roster.

---

## 2. Providers

| Provider | Personal machine | Work machine |
|---|---|---|
| `opencode-go` | primary open-model gateway | not used |
| `kilo` | not used | primary gateway, **NDA-safe** |
| `anthropic` | frontier reasoning/text | configured, **not** default on any agent (NDA) |
| `openai` (ChatGPT **Plus / OAuth** — Codex line only) | frontier coding/tooling | configured, **not** default on any agent (NDA) |

### NDA rule (work machine)

Company code routes **only** through `kilo` open models. The frontier
providers (`anthropic`, `openai`) stay configured on the work machine for
explicit, non-sensitive opt-in use, but they are the default model on **no**
agent there. Concretely, on the work machine:

- Never use `kilo/anthropic/*` or `kilo/openai/*` passthrough for company code.
- Never use the low-cost, training-enabled kilo model suffix variant (the one
  that trains on submitted data and has crippled tool-calling) — see spec §3
  for its exact spelling. Banned for any agent, any machine.
- **One specific model family is banned outright, everywhere**, on either
  machine — it hangs or returns no answer during agentic tool-calling loops.
  See spec §3 (NDA rule) for the exact family name; do not assign it to any
  agent under any provider.

### `openai` availability

The `openai` provider here is ChatGPT-Plus OAuth, not a standard API key
(verified: `api.openai.com/v1/models` → 403 `Missing scopes:
api.model.read`). Only the agentic-coding line is reachable through it:
`gpt-5.4`, `gpt-5.4-mini`, `gpt-5.5`, `gpt-5.6-luna`, `gpt-5.6-terra`,
`gpt-5.6-sol`. Any API-only OpenAI model is **not** usable through this
provider.

### Implementation model parity

`deepseek-v4-pro` is the implementation model on **both** machines
(`opencode-go/deepseek-v4-pro` personal, `kilo/deepseek/deepseek-v4-pro`
work) — identical model family across both gateways, so there is zero
personal↔work skew on the highest-volume role (day-to-day coding agents).

### Provider version skew

Baked into the per-machine picks; `opencode-go` generally leads `kilo` by a
version:

- GLM: `5.2` (opencode-go) vs `5.1` (kilo)
- Kimi: `k2.7-code` (opencode-go) vs `k2.6` (kilo)

---

## 3. Reasoning-effort variants

"Variant" means the reasoning effort selected from each model's
`reasoning_options`. Effort levels differ per model family:

- Anthropic sonnet: `low` / `medium` / `high` / `max`
- Anthropic opus: adds `xhigh` on top of the sonnet levels
- `opencode-go` deepseek / GLM: `high` / `max` only
- `kilo` glm-5.1 / deepseek: `toggle` + `high` / `xhigh`
- minimax / kimi: `toggle` only

Effort scales with how much reasoning depth a task actually needs, not with
how "important" the agent sounds. A deterministic MCP-calling agent gets a
low/off variant even if its job is operationally critical; a design/root-cause
agent gets a high variant even though it runs less often.

---

## 4. Defaults

| Slot | Personal | Work (NDA-safe) |
|---|---|---|
| `model` | `anthropic/claude-sonnet-4-6` · medium | `kilo/z-ai/glm-5.1` · on |
| `small_model` | `opencode-go/minimax-m3` · off | `kilo/minimax/minimax-m3` · off |

Every agent not listed explicitly in the per-agent table below inherits these
defaults.

---

## 5. Per-agent assignments

| Agent | Personal (variant) | Work NDA-safe (variant) | Justification |
|---|---|---|---|
| `architect` | `anthropic/claude-opus-4-8` · high | `kilo/z-ai/glm-5.1` · high | Deepest design/ADR/plan reasoning, no bash. Opus top reasoner; high (not max) — design rarely needs xhigh. Work: GLM #1 open long-horizon. |
| `debugger` | `anthropic/claude-opus-4-8` · high | `kilo/z-ai/glm-5.1` · high | Cross-stack root-cause, long logs. Work: GLM #1 open Terminal-Bench. |
| `autopilot` | `anthropic/claude-sonnet-4-6` · **medium** | `kilo/z-ai/glm-5.1` · on | Thinks then delegates to subagents; heavy work is in the workers, so mid-tier orchestrator is cost-right. GLM has no "medium" (on/high only). |
| `general` | `anthropic/claude-sonnet-4-6` · medium | `kilo/z-ai/glm-5.1` · on | Default dispatch target; reliable all-rounder. |
| `devops` | `openai/gpt-5.6-terra` · medium | `kilo/z-ai/glm-5.1` · on | "Balanced agentic coding for everyday work" = live k8s/Helm/Flux ops. Work: GLM Terminal-Bench. |
| `skill-smith` | `openai/gpt-5.6-terra` · medium | `kilo/z-ai/glm-5.1` · on | Behavior code + MCP servers = agentic coding + tool-calling. Work: GLM #1 open tool-calling. |
| `jenkins` | `anthropic/claude-sonnet-4-6` · low | `kilo/z-ai/glm-5.1` · off | `jk` CLI controller ops — deterministic; reliability > reasoning. |
| `webdebugger` | `anthropic/claude-sonnet-4-6` · low | `kilo/z-ai/glm-5.1` · off | Interprets DOM/network/console via Playwright MCP; comprehension not planning. |
| `coder` | `opencode-go/deepseek-v4-pro` · high | `kilo/deepseek/deepseek-v4-pro` · high | Implementation model. Polyglot code; v4-pro strong SWE reasoning. |
| `cloudflare` | `opencode-go/deepseek-v4-pro` · high | `kilo/deepseek/deepseek-v4-pro` · high | Workers/wrangler/DO = pure code transformation. |
| `frontend` | `opencode-go/deepseek-v4-pro` · high | `kilo/deepseek/deepseek-v4-pro` · high | Component/UI build = implementation. |
| `stitch` | `opencode-go/deepseek-v4-pro` · high | `kilo/deepseek/deepseek-v4-pro` · high | Stitch design→code = code generation. |
| `writer` | `anthropic/claude-sonnet-4-6` · low | `kilo/z-ai/glm-5.1` · off | Docs/specs/docx-pptx-pdf = prose quality, minimal step-reasoning. The banned model family (see §2 NDA rule) was previously used for this role and is not carried forward. |
| `webresearcher` | `openai/gpt-5.6-luna` · medium | `kilo/z-ai/glm-5.1` · on | High-volume web reads; luna ($1/$6) is the "fast/affordable" fit, 1.05M ctx for big crawls. The banned model family (see §2 NDA rule) was previously used for this role and is not carried forward. |
| `web-fast-context` | `opencode-go/deepseek-v4-flash` · default | `kilo/deepseek/deepseek-v4-flash` · off | Quick sourced facts in parallel; cheap. |
| `webscraper` | `opencode-go/deepseek-v4-flash` · default | `kilo/deepseek/deepseek-v4-flash` · off | Structured Firecrawl I/O; no reasoning. |
| `webmonitor` | `opencode-go/deepseek-v4-flash` · default | `kilo/deepseek/deepseek-v4-flash` · off | Repeated change-tracking runs; cost-sensitive. |
| `ha` | `opencode-go/deepseek-v4-flash` · default | `kilo/deepseek/deepseek-v4-flash` · off | HA MCP entity/device calls; structured. |
| `jira` | `opencode-go/deepseek-v4-flash` · default | `kilo/deepseek/deepseek-v4-flash` · off | JQL/transitions/worklogs via MCP; structured. |
| `stitch-mcp` | `opencode-go/deepseek-v4-flash` · default | `kilo/deepseek/deepseek-v4-flash` · off | MCP-driven Stitch design calls. |
| `graphify` | `opencode-go/deepseek-v4-flash` · default | `kilo/deepseek/deepseek-v4-flash` · off | Orchestrates AST + parallel extraction; code-only updates need no LLM (see spec §10). |
| `graphify-extractor` | `opencode-go/deepseek-v4-flash` · default | `kilo/deepseek/deepseek-v4-flash` · off | Parallel per-chunk LLM extraction worker (see spec §10). |
| `git` | `opencode-go/minimax-m3` · off | `kilo/minimax/minimax-m3` · off | Deterministic git hygiene within tight rails (see spec §9). |
| `plan` (built-in) | inherits default | inherits default | Read-only planner. |

### `openai` spread

Of the agents on `openai` (personal machine only): `devops` and
`skill-smith` use `gpt-5.6-terra`; `webresearcher` uses `gpt-5.6-luna`.
Headroom for upgrades: `gpt-5.6-sol` or `gpt-5.5` (frontier tier); headroom
for budget: `gpt-5.4-mini`.

### GLM latency fallback (work machine)

`kilo/z-ai/glm-5.1` has roughly a 10-second time-to-first-token. If
`architect` or `autopilot` feel like they're dragging on the work machine,
fall back to `kilo/deepseek/deepseek-v4-pro` for those agents instead of
tolerating the latency.

---

## 6. Hard constraints recap

- No frontier provider (`anthropic`, `openai`) is the **default** model on any
  agent on the work machine — NDA.
- No `kilo/anthropic/*` or `kilo/openai/*` passthrough for company code.
- No low-cost, training-enabled kilo model suffix variants, anywhere (see
  spec §3 for the exact suffix spelling).
- No models from the banned family (see §2 NDA rule), anywhere, on either
  machine.
