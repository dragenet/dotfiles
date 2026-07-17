# AGENTS.md

Dotfiles monorepo — one directory per tool, each symlinked into place by
`bootstrap.sh` (see `README.md` for the table and manual commands). No
build/lint/test system; this is config files plus one idempotent bootstrap
shell script.

Collaboration conventions (learning-in-progress project, explain *why* before
*how*, read official docs before discussing options) are in `CLAUDE.md` at
root and per-tool (`nvim/CLAUDE.md`, `tmux/CLAUDE.md`) — apply the same
approach here even though this file is named for OpenCode.

## `opencode/` is a work-in-progress redesign — read before touching

`opencode/` is **not** the active OpenCode config yet. The real, live config
is `~/.config/opencode` (a separate, real directory — not a symlink from this
repo). `opencode/` is a staging area for rebuilding it; it is not wired into
`bootstrap.sh` and not symlinked anywhere.

**Before making any change under `opencode/`, read `opencode/HANDOFF.md` in
full.** It is a self-contained handoff: goal,
full discovery findings, open decisions, and next steps for a
`superpowers:brainstorming` session that got as far as one clarifying question
the user dismissed (deferred, not answered) — resume from there, don't
re-discover what it already documents.

Things worth knowing that are easy to get wrong from file inspection alone:

- **`opencode/` is the staged configuration** based on a colleague's repo
  (`github.com/jabbas/opencode-config`, see `opencode/VENDORED_FROM.md`
  for exact commit/date). Its `AGENTS.md`, `docs/dev-guide.md`, and
  `opencode.json` describe *his* setup (Kilo-only models, git submodules for
  `superpowers/`/`anthropics-skills/`/etc., `plugins/` + `skills/` symlink
  dirs) — **none of those submodule or symlink dirs exist in this tree**
  (`.gitmodules` is present but nothing is initialized). Don't assume paths
  those docs mention actually resolve here.
- `opencode/AGENTS.md` is the staged global instruction set; it is not active
  until the staged configuration is deployed.
- The currently-live `~/.config/opencode` has only two custom global agents:
  `agents/git.md` (locked-down git-hygiene subagent, no push/rebase/force) and
  `agents/web-fast-context.md` (fast read-only web/docs-lookup subagent,
  `webfetch`/`websearch` only — genuinely good, worth reusing/adapting into
  the new roster rather than reinventing). Check the live directory directly
  rather than trusting HANDOFF.md's checklist on this point — HANDOFF.md
  states this agent's migration (from `infra-flux`) as "not yet done", but it
  is already present there; the checklist has drifted since that doc was
  written.
- `git -C ~/.dotfiles status` currently shows `opencode/` as uncommitted, plus
  **unrelated, pre-existing** nvim changes (`nvim/lazy-lock.json`,
  `nvim/lua/plugins/comment.lua`, `nvim/lua/plugins/sops.lua`). Those nvim
  changes are not part of any opencode work — don't touch or commit them
  unless separately asked to.
- `bootstrap.sh`'s `create_symlinks()` only links `nvim`, `tmux`, and
  `ghostty` (`yabai` is linked separately in `install_yabai()`); there is no
  opencode step. Don't add one until the redesign in HANDOFF.md is actually
  finalized and approved (its own step 6 covers this).
