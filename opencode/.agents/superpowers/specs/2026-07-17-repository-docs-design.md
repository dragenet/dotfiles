# Versioned Repository Documentation Skill — Design

## Goal

Provide an agent-invocable repository-documentation capability that retrieves an explicit Git revision into `$HOME/.agents/repositories`, builds a Graphify index inside that immutable snapshot, and answers later documentation questions from the saved graph.

## Assumptions

- “Either path” means both the staged configuration (`~/.dotfiles/opencode`) and the active configuration (`~/.config/opencode`) must grant narrowly scoped external-directory access to `$HOME/.agents/repositories/**`.
- A documentation snapshot is immutable: updating a branch creates a new snapshot rather than changing a previous one.
- Supported repository URLs are public HTTPS or SSH Git remote URLs using SSH-agent authentication. Private HTTPS that requires a credential helper fails closed and requires an accepted SSH remote or a future explicitly reviewed helper integration; credentials are never written to configuration, manifests, or chat output, and global Git configuration remains disabled.
- The caller supplies `--ref`; falling back to a remote default branch would not meet the requested-version requirement.
- Graphify output is the documentation source of truth. The feature will not execute repository code, install dependencies, initialize submodules, use hooks, or enable watch mode.

## Alternatives Considered

1. Extend the existing `/graphify <github-url>` flow. Rejected: its documented clone location is `~/.graphify/repos`, branches are mutable, and it does not preserve versioned documentation snapshots.
2. Add shell snippets directly to the Graphify skill. Rejected: ingestion/version safety and query navigation are a separate concern; a dedicated skill and agent create an auditable boundary.
3. Create one mutable checkout per repository. Rejected: a later branch refresh could silently change the documentation being cited.

## Chosen Architecture

Add a `repository-docs` specialist agent and a `repository-docs` skill. It exposes `add`, `query`, and `list` workflows. `add` validates a remote and explicit ref, resolves it to a full commit, checks out a detached, non-recursive snapshot at a deterministic path, records non-secret provenance, then invokes Graphify against that snapshot. `query` reads only that snapshot’s existing graph, preserving its role as a documentation interface.

Snapshot layout:

```text
$HOME/.agents/repositories/<sanitized-host>/<sanitized-owner>/<sanitized-repository>/<40-hex-commit>/
├── .agents/
│   ├── repository-docs-manifest.json
│   └── graphify-out/
│       ├── graph.json
│       ├── GRAPH_REPORT.md
│       └── graph.html
└── <detached repository checkout>
```

The implementation must avoid shell interpolation by passing validated values as arguments, reject unsafe refs/URLs and abbreviated commit IDs, resolve annotated tag peeled commits, and refuse to overwrite a populated snapshot. A graph manifest must retain requested ref, resolved commit, sanitized remote identity, and retrieval timestamp, without exposing credentials.

## Permission Model

Keep global `bash` approval behavior. Add only `$HOME/.agents/repositories/**` to `external_directory` allow rules in both configuration copies and explicitly allow it for the repository-docs and Graphify agents. Restrict the repository-docs agent’s subprocess work to validated Git inspection/clone/fetch/detached-checkout/fsck commands and Graphify extract/query operations; do not add a blanket shell allow. Amend Graphify’s opt-in policy to recognize this directory as a managed, explicit documentation corpus.

## Acceptance Criteria

- A caller can ingest a public fixture repository at a supplied branch, tag, or full commit and receive a detached snapshot under `$HOME/.agents/repositories` keyed by its resolved 40-character commit.
- The snapshot has a valid provenance manifest and Graphify graph at `.agents/graphify-out/graph.json`.
- A later query operates on the existing graph, not a broad file read or re-index.
- Unsafe/missing refs, abbreviated SHAs, credentials in remote URLs, submodules, hooks, mutable snapshot changes, and broad external-directory or shell permissions are explicitly prohibited.
- Staged configuration checks and a real smoke ingestion/query pass without modifying unrelated files.
