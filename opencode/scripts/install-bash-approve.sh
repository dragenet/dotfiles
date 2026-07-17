#!/usr/bin/env bash
#
# install-bash-approve.sh
#
# One-time, per-machine setup for the claude-bash-approve deterministic bash
# classifier (vendored as the claude-bash-approve/ git submodule).
#
# What this does:
#   1. Builds/copies the Go runtime + hook scripts to the shared, per-user XDG
#      location ($XDG_DATA_HOME/claude-bash-approve, default
#      ~/.local/share/claude-bash-approve). Safe and idempotent; does not
#      touch any OpenCode config.
#   2. Renders plugins/bash-approve.ts from the upstream template, substituting
#      the absolute path to that machine's installed hook script.
#
# What this deliberately does NOT do (unlike upstream install.py):
#   - It does not write/modify opencode.json or opencode.jsonc. This repo's
#     bash permission baseline (opencode.jsonc: permission.bash) already sets
#     "*": "ask" so this classifier is the real approval gate; see
#     docs/dev-guide.md.
#   - It does not touch Claude Code or Codex hook wiring.
#
# plugins/bash-approve.ts is gitignored: it embeds an absolute, machine-
# specific path and must be regenerated on each machine (same category as
# opencode.local.jsonc). Run this script once per machine after cloning and
# initializing submodules.
#
# Requirements: Python 3.11+, Go 1.25+.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SUBMODULE_DIR="$REPO_ROOT/claude-bash-approve"

if [ ! -f "$SUBMODULE_DIR/install.py" ]; then
  echo "error: $SUBMODULE_DIR/install.py not found." >&2
  echo "Run: git -C \"$REPO_ROOT/..\" submodule update --init --recursive" >&2
  exit 1
fi

if ! command -v go >/dev/null 2>&1; then
  echo "error: Go is required to build the bash-approve runtime." >&2
  exit 1
fi

python3 - "$SUBMODULE_DIR" "$REPO_ROOT/plugins/bash-approve.ts" <<'PY'
import sys
from pathlib import Path

submodule_dir, plugin_dest = sys.argv[1], sys.argv[2]
sys.path.insert(0, submodule_dir)
import install

runtime_root = install.install_shared_runtime_bundle()
hook_path = install.shared_runtime_opencode_hook_path()
install.render_opencode_plugin(Path(plugin_dest), hook_path)

print(f"Installed shared runtime: {runtime_root}")
print(f"Rendered plugin: {plugin_dest}")
print(f"Hook path: {hook_path}")
PY

echo "Done. Restart OpenCode for the plugin to be picked up (config loads once at startup)."
