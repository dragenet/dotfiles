# Repository Documentation Skill — Orchestrator Audit

## Outcome

Implemented a staged `repository-docs` capability for versioned Git repository documentation. It adds a dedicated `/repository-docs` route, immutable snapshot workflow rooted at `$HOME/.agents/repositories`, Graphify indexing/query guidance, staged/live managed-directory permissions, and a disposable smoke harness.

The work is **not security-signoff complete** because the user explicitly instructed the orchestrator to skip the final independent-review findings before their remediation was executed. The implementation should not be deployed or used for untrusted repository ingestion until those findings are addressed.

## Work Performed

- Research specialist: mapped staged/live conventions, Graphify behavior, permissions, and safe snapshot design.
- Implementation specialists: created `agents/repository-docs.md`, `skill/repository-docs/SKILL.md`, Graphify `--preinstalled` mode, command routing, permission rules, checker assertions, and `scripts/test-repository-docs.sh`.
- Git specialist: merged the reviewed feature branch into local `master` at `b53097e` without push, force operations, reset, clean, or changes to unrelated nvim files.
- Test specialists: added staged/live parity checks and a disposable fixture test. Reported successful latest completed validation before the skipped findings: JSON/parity/syntax checks, whitelist checker (122 resolved entries and 5 informational orphans), and smoke harness (39/39).

## Assumptions

- “Either path” was interpreted as staged `~/.dotfiles/opencode` and active `~/.config/opencode`; both now contain scoped access policy for `$HOME/.agents/repositories/**`.
- Snapshots are immutable and keyed by resolved full commit; an existing destination is a conflict, not a refresh target.
- Public HTTPS and SSH-agent authentication are supported. HTTPS requiring a configured Git credential helper is intentionally fail-closed to avoid executing arbitrary helper configuration; use SSH or a future explicitly reviewed helper integration.
- No deployment, symlink, bootstrap change, restart, or push was requested or performed.

## Independent Review Status

Numerous earlier review findings were remediated: mutable snapshot reuse, raw Git environment/config/filter/hook/submodule paths, SSH configuration execution, Graphify package installation, Graphify import shadowing, command routing, unsafe Git auto-allows, and test/parity gaps.

The final reviewer reported these unresolved findings, which the user asked to skip:

1. **Critical:** Graphify `--preinstalled` execution can inherit `PYTHONPATH`; its Python entrypoint should be invoked with isolated `-I` execution and covered by a regression check.
2. **Important:** `jq *` is autoallowed for `repository-docs`, permitting shell-redirection writes. Remove this allow in staged/live agent and JSONC rules and assert its absence.
3. **Important:** The smoke harness does not prove that Graphify preflight precedes reservation of its actual final fixture destination. Reorder it and assert unavailable preflight leaves that exact destination absent.

The final remediation task was cancelled before making changes in response to the user instruction. No success claim should be inferred for these three issues.

## Safety / STOPs

- No hard-stop operation was needed.
- No reboot, restart, deployment, destructive cleanup, force-push, or ordinary push occurred.
- User-directed exception: final review findings were skipped at the user’s instruction.

## Recommended Follow-up

Implement and independently re-review the three unresolved findings above, rerun `bash opencode/scripts/check-skill-whitelists.sh` and `bash opencode/scripts/test-repository-docs.sh`, then manually restart OpenCode only when the staged/live configuration is ready to load.
