# Memory Rules

These rules apply to persistent memory provided by `opencode-mem`, exposed as
a single `memory` tool with `mode` and `scope` parameters.

## Recall

At the start of a task, call `memory({ mode: "search", query: "<keywords from
the request>" })`. Use relevant results and do not ask for information already
present in memory. For cross-project facts, repeat the search with
`scope: "all-projects"`.

Call `memory({ mode: "profile" })` when a task depends on durable user
preferences or working style, since auto-capture maintains that profile
separately from regular memories.

## Routing

- Project-specific context: `memory({ mode: "add", content: "..." })` (default
  `scope: "project"`).
- Cross-project conventions or user preferences: `memory({ mode: "add",
  content: "...", scope: "all-projects" })`.

There is no separate "core" tier. If a fact must always surface early in a
session, note that in the content itself; `chatMessage.injectOn: "first"`
(configured in `opencode-mem.jsonc`) already re-injects the most relevant
recent memories at the start of a session.

## Store And Correct

Store concise, durable facts after confirmed decisions, root causes and fixes,
cross-project conventions, or significant discoveries. Do not store trivial
exchanges, transient debugging output, intermediate steps, or facts already in
memory.

`opencode-mem` also runs auto-capture in the background (an AI call that
summarizes technical work into memory automatically); manual `memory({ mode:
"add" })` calls remain the mechanism for explicit, high-confidence, or
user-requested facts that should not wait for auto-capture's own judgment.

When a memory is stale or wrong, use `memory({ mode: "list" })` to find it and
correct it going forward with a new `add` call describing the current state;
older superseded entries naturally rank lower in future searches.

## Web UI

A local web interface for browsing and managing memories is available at
`http://127.0.0.1:4747` (configurable via `webServerPort` in
`opencode-mem.jsonc`).
