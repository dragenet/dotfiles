# Final Fix 3 Report

## Changes

- Added a future-deployment guard that inspects an existing
  `~/.config/opencode` symlink and moves the current real directory to a
  timestamped backup before creating the dotfiles symlink.
- Documented that this is deployment-only, preserves the live configuration,
  and prevents a nested `~/.config/opencode/config` symlink.
- Added the later `git push --force-with-lease*` permission rule with `ask` so
  last-match-wins preserves approval for lease force-pushes while plain and
  short force-pushes remain denied.

## Verification

- Parsed `opencode.json` as JSON.
- Parsed `agents/git.md` frontmatter as YAML and traced:
  `git push --force-with-lease origin main` to `ask`,
  `git push --force origin main` to `deny`, and
  `git push -f origin main` to `deny`.
- Confirmed the README's timestamped backup command appears before the
  symlink command and includes the existing-symlink guard and nested-link
  explanation.
- Ran `scripts/check-skill-whitelists.sh`: all 120 entries resolve; four
  orphan skills are informational.

## Scope

- Did not modify the live `~/.config/opencode` configuration or
  `bootstrap.sh`.
