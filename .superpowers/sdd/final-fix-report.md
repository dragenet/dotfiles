# Final Fix Wave Report

## Scope

Applied the resolved final-review changes only under the staged OpenCode config
and this report. The live `~/.config/opencode`, `bootstrap.sh`, `infra-flux`,
and `agents/graphify-extractor.md` were not changed.

## Changes

- Set the global Bash default to `allow` while preserving explicit destructive
  command denials.
- Added last-match git guards for amend, forced checkout/switch, pull rebase,
  and branch/tag deletion variants.
- Marked the handoff as historical, corrected vendor and deployment wording,
  and updated current permission terminology.
- Updated the redesign spec and plan for intentional broad Bash and
  graphify-extractor worker execution permissions; `claude-bash-approve`
  remains isolated-tested and deferred.

## Verification

- `opencode.json` JSON parsing: passed.
- All staged `agents/*.md` YAML frontmatter: passed.
- `scripts/check-skill-whitelists.sh`: passed all 120 entries (four existing
  informational orphan skills).
- Required last-match examples: passed for checkout `-f`, switch
  `--discard-changes`, pull `--rebase`, commit `--amend`, branch `-D`, and push
  `--force`.
- No legacy active `tools:` keys, no stale current-document claims, and
  `git diff --check`: passed.
