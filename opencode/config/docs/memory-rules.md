# Memory Rules

These rules apply only to persistent memory provided by `opencode-mnemosyne`.

## Recall

At the start of a task, use `memory_recall` and `memory_recall_global` with
keywords from the request. Use relevant results and do not ask for information
already present in memory.

## Routing

- User preferences and personal facts: `memory_store_global` with `core=true`.
- Cross-project conventions: `memory_store_global`.
- Project-specific context: `memory_store`.
- Critical project facts: `memory_store` with `core=true`.

## Store And Correct

Store concise, durable facts after confirmed decisions, root causes and fixes,
cross-project conventions, or significant discoveries. Do not store trivial
exchanges, transient debugging output, intermediate steps, or facts already in
memory.

When a memory is stale or wrong, remove it with `memory_delete` before storing
the corrected fact.
