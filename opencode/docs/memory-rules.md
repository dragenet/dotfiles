# Memory Rules

These rules apply to persistent memory provided by `opencode-mnemosyne`
(Mnemosyne CLI + OpenCode plugin). Memory is local/offline (SQLite FTS5 +
vectors). There is no background auto-capture and no user-profile subsystem.

## Tools

| Tool | Use |
|------|-----|
| `memory_recall` | Search **project** memory |
| `memory_recall_global` | Search **global** (cross-project) memory |
| `memory_store` | Store a **project** memory (`core?: boolean`) |
| `memory_store_global` | Store a **global** memory (`core?: boolean`) |
| `memory_delete` | Delete by numeric document `id` |

Project collection name is the basename of the working directory. Global
collection is shared across projects.

## Recall

At the start of a task, call:

- `memory_recall({ query: "<keywords from the request>" })`
- `memory_recall_global({ query: "<keywords>" })` when preferences or
  cross-project conventions may matter

Use relevant results. Do not ask the user for facts already in memory.

## Store

After confirmed decisions, root causes and fixes, cross-project conventions, or
significant discoveries, store one concise durable fact:

- Project-specific: `memory_store({ content: "..." })`
- Cross-project / user preferences: `memory_store_global({ content: "..." })`

Mark only critical always-relevant facts as core:

- `memory_store({ content: "...", core: true })`
- Use core sparingly

Do not store trivial exchanges, transient debugging output, intermediate steps,
or facts already present.

## Correct

When a memory is wrong, delete it with `memory_delete({ id: <n> })` (id appears
in recall/list output), then store the corrected fact if still needed.

## What this stack does not do

- No automatic session summarization into memory
- No injected user-profile ontology
- No Memory Explorer web UI (former opencode-mem :4747)

Manual store/recall is the only path. Prefer high-confidence durable facts.

## CLI (optional direct use)

Binary: `mnemosyne` (typically `~/.local/bin/mnemosyne`).  
DB default: `~/.local/share/mnemosyne/mnemosyne.db`.  
Optional config: `~/.config/mnemosyne/config.yaml`.

Useful commands: `mnemosyne setup`, `mnemosyne search -f plain "..."`,
`mnemosyne add "..."`, `mnemosyne add -g "..."`, `mnemosyne list -t core -f plain`.
