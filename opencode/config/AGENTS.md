# OpenCode Staged Configuration

This directory is the staged configuration at `~/.dotfiles/opencode/config/`.
It is not the live `~/.config/opencode` configuration yet: do not deploy it,
create a symlink, or modify `bootstrap.sh` unless explicitly asked. Confirm the
working directory before filesystem operations and never read the filesystem
root `/`.

## Global Hard Rules

- Never reboot, shutdown, or restart a host, VM, or container without explicit
  confirmation in the current conversation. Do not delegate such an action.
- Never run destructive operations such as disk wipes, ZFS destruction, `dd`,
  or network resets without explicit confirmation.
- If completion requires a reboot, stop, summarize completed work and the
  expected post-reboot state, then ask the user to reboot manually.

## Working Here

Read `docs/dev-guide.md` before editing agents, skills, plugins, or scripts.
The shared configuration is portable; its model and provider selections live in
gitignored per-machine local layers. See `docs/model-selection.md` for the
four-provider model table, and `docs/dev-guide.md` for the staged layout and
validation commands.

Use `permission:` for configuration access rules. Do not introduce the
deprecated access-map format.

## Documentation And Web Routing

For current library, framework, SDK, API, CLI, or cloud-service documentation,
use the ctx7 CLI:

```bash
npx ctx7@latest library <name> "<full question>"
npx ctx7@latest docs <library-id> "<full question>"
```

Do not include credentials in lookup queries.

- Fast fact, version, API flag, or provider reference: `@web-fast-context`.
- Multi-source research and synthesis: `@webresearcher`.
- Known-URL extraction, crawling, or JavaScript interaction: `@webscraper`.
- Page-change monitoring: `@webmonitor`.

Use `@graphify` for opted-in project structure questions instead of broad
repository reads. The graphify capability and its skill live in
`skill/graphify/`; project opt-in guidance is in `docs/graphify-project-optin.md`.

## Delegation And Safety

Agents that can delegate declare explicit `permission.task` rules so delegation
continues to work when they run as subagents. `autopilot` remains primary-only
and cannot be delegated to. `git` and `graphify-extractor` are leaf agents;
`graphify` may delegate only to `graphify-extractor`.

Route Jenkins controller actions through `@jenkins`; do not run the `jk` CLI
outside that specialist. Persistent-memory behavior is limited to the routing
rules in `docs/memory-rules.md`.

Background delegation is strictly read-only. Use native `task` delegation for
work that writes files or runs bash. The staged configuration retains native
bash prompts and explicit catastrophic-command denies; bash-approve has only
passed isolated tests and its active deployment is deferred.

After a staged configuration change is eventually deployed, restart OpenCode:
it loads configuration only at startup.
