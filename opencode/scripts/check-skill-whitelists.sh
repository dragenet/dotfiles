#!/usr/bin/env bash
#
# check-skill-whitelists.sh
#
# Verifies that every skill referenced in an agent's permission.skill whitelist
# (agent.<name>.permission.skill == "allow" in opencode.jsonc) corresponds to a
# real skill on disk, a known built-in, or — for wildcard patterns — matches at
# least one on-disk skill.
#
# Why: when a skill submodule updates and a skill is renamed/removed, a stale
# whitelist entry silently stops matching (skill/index.ts:314 only filters by
# "deny"; a nonexistent name simply allows nothing). This is silent drift. Run
# this after editing whitelists or updating skill submodules.
#
# Exit: 0 if no dead entries (orphan skills are allowed), 1 if any dead literal
# or dead wildcard entry is found.
#
# Spec: .agents/superpowers/specs/2026-06-14-whitelist-consistency-check-design.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG="${OPENCODE_CONFIG_PATH:-$REPO_ROOT/opencode.jsonc}"

# Built-in skills registered in OpenCode source (NOT SKILL.md files on disk).
# See skill/index.ts (CUSTOMIZE_OPENCODE_SKILL_NAME).
KNOWN_BUILTINS=("customize-opencode")
REPOSITORY_DOCS_AGENT="repository-docs"
REPOSITORY_DOCS_SKILL="repository-docs"
REPOSITORY_DOCS_SKILL_CONTRACT="$REPO_ROOT/skill/repository-docs/SKILL.md"
REPOSITORY_DOCS_AGENT_CONTRACT="$REPO_ROOT/agents/repository-docs.md"
GRAPHIFY_SKILL_CONTRACT="$REPO_ROOT/skill/graphify/SKILL.md"
REPOSITORY_DOCS_GIT_ENVIRONMENT_VARS=(
  "GIT_SSH_COMMAND"
  "GIT_SSH"
  "GIT_SSH_VARIANT"
  "GIT_ASKPASS"
  "SSH_ASKPASS"
  "GIT_EXEC_PATH"
)
REPOSITORY_DOCS_TRUSTED_SSH_COMMAND='GIT_SSH_COMMAND="/usr/bin/ssh -F none"'

LIVE_CONFIG="${HOME}/.config/opencode/opencode.jsonc"
LIVE_AGENTS="${HOME}/.config/opencode/agents"

if ! command -v jq >/dev/null 2>&1; then
  echo "[FAIL] jq is required but not found" >&2
  exit 1
fi
if [[ ! -f "$CONFIG" ]]; then
  echo "[FAIL] opencode.jsonc not found at $CONFIG" >&2
  exit 1
fi

# --- Collect on-disk skill names (frontmatter `name:`, first match per file) ---
DISK_SKILLS="$(
  find "$REPO_ROOT" -name SKILL.md -not -path '*/node_modules/*' -print0 \
    | xargs -0 -I{} awk -F': ' '/^name:/{gsub(/[ \t\r]+$/, "", $2); print $2; exit}' {} \
    | sort -u
)"

# --- Collect whitelist allow-entries: "<agent>\t<skill>" ---
WHITELIST="$(
  jq -r '
    .agent | to_entries[]
    | .key as $a
    | (.value.permission.skill // {}) | to_entries[]
    | select(.value == "allow")
    | "\($a)\t\(.key)"
  ' "$CONFIG"
)"

# This skill can create immutable external snapshots, so only its dedicated
# specialist may whitelist it. Generic whitelist resolution alone is not enough.
repository_docs_route_is_exclusive() {
  local routes
  routes="$(jq -r --arg skill "$REPOSITORY_DOCS_SKILL" '
    .agent | to_entries[]
    | select((.value.permission.skill // {})[$skill] == "allow")
    | .key
  ' "$CONFIG")"
  [[ "$routes" == "$REPOSITORY_DOCS_AGENT" ]]
}

repository_docs_command_routes_to_agent() {
  jq -e --arg agent "$REPOSITORY_DOCS_AGENT" \
    '.command["repository-docs"].agent == $agent' "$CONFIG" >/dev/null
}

repository_docs_command_keeps_subtask_enabled() {
  jq -e '.command["repository-docs"] | if has("subtask") then .subtask == true else true end' "$CONFIG" >/dev/null
}

# Every documented sanitized_git wrapper must clear command-execution overrides.
# Check wrapper blocks individually so a token in the fixture cannot mask an
# omission from the production contract (or vice versa).
repository_docs_sanitized_git_environment_is_complete() {
  local contract required
  local contracts=("$REPOSITORY_DOCS_SKILL_CONTRACT" "$REPOSITORY_DOCS_AGENT_CONTRACT")

  for contract in "${contracts[@]}"; do
    for required in "${REPOSITORY_DOCS_GIT_ENVIRONMENT_VARS[@]}"; do
      if ! awk -v required="$required" '
        /^sanitized_git\(\) \{/ { in_wrapper = 1; found = 0; wrappers++; next }
        in_wrapper && /^}/ {
          if (!found) missing = 1
          in_wrapper = 0
          next
        }
        in_wrapper && $0 ~ ("-u[[:space:]]+" required "([[:space:]]|$)") { found = 1 }
        END { exit !(wrappers > 0 && !missing) }
      ' "$contract"; then
        echo "[FAIL] every repository-docs sanitized_git wrapper in $contract must clear $required"
        return 1
      fi
    done
    if ! awk -v required="$REPOSITORY_DOCS_TRUSTED_SSH_COMMAND" '
      /^sanitized_git\(\) \{/ { in_wrapper = 1; found = 0; wrappers++; next }
      in_wrapper && /^}/ {
        if (!found) missing = 1
        in_wrapper = 0
        next
      }
      in_wrapper && index($0, required) { found = 1 }
      END { exit !(wrappers > 0 && !missing) }
    ' "$contract"; then
      echo "[FAIL] every repository-docs sanitized_git wrapper in $contract must pin GIT_SSH_COMMAND to /usr/bin/ssh -F none"
      return 1
    fi
  done
}

# Repository snapshots may only delegate Graphify through its documented
# no-install mode. Inspect that mode's code block separately so normal Graphify
# installation instructions remain available to ordinary Graphify invocations.
repository_docs_graphify_route_uses_preinstalled_mode() {
  local contract
  local contracts=("$REPOSITORY_DOCS_SKILL_CONTRACT" "$REPOSITORY_DOCS_AGENT_CONTRACT")

  for contract in "${contracts[@]}"; do
    if ! grep -Fq -- "graphify extract . --out .agents --preinstalled" "$contract"; then
      echo "[FAIL] repository-docs Graphify extraction in $contract must use --preinstalled"
      return 1
    fi
  done
}

graphify_preinstalled_mode_has_no_install_path() {
  if ! awk '
    /^### `--preinstalled` mode:/ { in_mode = 1; next }
    in_mode && /^### / { exit }
    in_mode && /^```bash$/ { in_code = !in_code; saw_code = 1; next }
    in_mode && in_code && /(^|[^[:alnum:]_-])(uv|pip|installer|install)([^[:alnum:]_-]|$)/ { forbidden = 1 }
    END { exit !(in_mode && saw_code && !forbidden) }
  ' "$GRAPHIFY_SKILL_CONTRACT"; then
    echo "[FAIL] Graphify --preinstalled mode must contain a detection-only code path with no installer command"
    return 1
  fi
}

repository_docs_graphify_extract_keeps_default_ask() {
  if grep -Fq -- '"graphify extract*": allow' "$REPOSITORY_DOCS_AGENT_CONTRACT"; then
    echo "[FAIL] repository-docs agent frontmatter must not auto-allow graphify extract"
    return 1
  fi
  if ! jq -e '.agent["repository-docs"].permission.bash | has("graphify extract*") | not' "$CONFIG" >/dev/null; then
    echo "[FAIL] repository-docs staged configuration must not auto-allow graphify extract"
    return 1
  fi
}

graphify_preinstalled_mode_is_isolated_from_snapshot() {
  local mode
  mode="$(awk '
    /^### `--preinstalled` mode:/ { in_mode = 1 }
    in_mode { print }
    in_mode && /^### Step 1 / { exit }
  ' "$GRAPHIFY_SKILL_CONTRACT")"

  for required in \
    'GRAPHIFY_BIN="$(realpath "$GRAPHIFY_BIN")"' \
    'SNAPSHOT_ROOT="$(pwd -P)"' \
    'GRAPHIFY_PYTHON="$(realpath "$GRAPHIFY_PYTHON")"' \
    'SAFE_CWD="$(mktemp -d' \
    '"$GRAPHIFY_PYTHON" -I -c' \
    '"$GRAPHIFY_BIN" --help'; do
    if ! grep -Fq -- "$required" <<<"$mode"; then
      echo "[FAIL] Graphify --preinstalled mode must require $required"
      return 1
    fi
  done

  if ! grep -Fq -- 'append `-I` to every such Python invocation' "$GRAPHIFY_SKILL_CONTRACT"; then
    echo "[FAIL] Graphify --preinstalled mode must require isolated execution for every later Python invocation"
    return 1
  fi

  # A hostile ssh_config must not influence the fixed transport: -F none
  # excludes both user and system configuration before any ProxyCommand or
  # Match exec directive can be evaluated.
  if ! (
    set -e
    local fixture_root ssh_config
    fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/repository-docs-ssh-fixture.XXXXXX")"
    trap 'rm -rf "$fixture_root"' EXIT
    ssh_config="$fixture_root/config"
    printf 'Host *\n    ProxyCommand /bin/false\n    Match exec "/bin/false"\n' > "$ssh_config"
    test -f /usr/bin/ssh
    grep -Fx '    ProxyCommand /bin/false' "$ssh_config" >/dev/null
    grep -Fx '    Match exec "/bin/false"' "$ssh_config" >/dev/null
    ! /usr/bin/ssh -F none -G hostile.invalid 2>/dev/null | grep -F '/bin/false' >/dev/null
  ); then
    echo "[FAIL] repository-docs trusted SSH transport permits hostile ssh_config directives"
    return 1
  fi

  # A snapshot-local graphify package must not be importable by the documented
  # isolated preflight, even when an inherited PYTHONPATH points at it.
  if ! (
    set -e
    local fixture_root safe_cwd
    fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/graphify-preinstalled-fixture.XXXXXX")"
    safe_cwd="$(mktemp -d "${TMPDIR:-/tmp}/graphify-preinstalled-safe.XXXXXX")"
    trap 'rm -rf "$fixture_root" "$safe_cwd"' EXIT
    mkdir -p "$fixture_root/graphify"
    printf 'raise RuntimeError("snapshot-local graphify was imported")\n' > "$fixture_root/graphify/__init__.py"
    (
      cd "$safe_cwd"
      FIXTURE_ROOT="$fixture_root" PYTHONPATH="$fixture_root" python3 -I -c '
import importlib.util
import os
spec = importlib.util.find_spec("graphify")
assert spec is None or not os.path.abspath(spec.origin or "").startswith(os.path.abspath(os.environ["FIXTURE_ROOT"]) + os.sep)
'
    )
  ); then
    echo "[FAIL] Graphify --preinstalled isolation permits a snapshot-local graphify package"
    return 1
  fi

  # A CLI or interpreter may be linked through an external path into the
  # snapshot. Final-target realpaths must still fail the containment check.
  if ! (
    set -e
    local fixture_root snapshot_root external_root cli_target python_target cli_link python_link
    fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/graphify-preinstalled-symlink-fixture.XXXXXX")"
    trap 'rm -rf "$fixture_root"' EXIT
    snapshot_root="$fixture_root/snapshot"
    external_root="$fixture_root/external"
    mkdir -p "$snapshot_root/bin" "$external_root"
    snapshot_root="$(realpath "$snapshot_root")"
    cli_target="$snapshot_root/bin/graphify"
    python_target="$snapshot_root/bin/python"
    : > "$cli_target"
    : > "$python_target"
    cli_link="$external_root/graphify"
    python_link="$external_root/python"
    ln -s "$cli_target" "$cli_link"
    ln -s "$python_target" "$python_link"
    for target in "$(realpath "$cli_link")" "$(realpath "$python_link")"; do
      case "$target" in "$snapshot_root"|"$snapshot_root"/*) ;; *) exit 1 ;; esac
    done
  ); then
    echo "[FAIL] Graphify --preinstalled containment check permits a symlink target inside the snapshot"
    return 1
  fi
}

repository_docs_graphify_validation_is_isolated() {
  local contract
  local contracts=("$REPOSITORY_DOCS_SKILL_CONTRACT" "$REPOSITORY_DOCS_AGENT_CONTRACT")

  for contract in "${contracts[@]}"; do
    if ! grep -Fq -- 'python3 -I -m json.tool .agents/graphify-out/graph.json' "$contract"; then
      echo "[FAIL] repository-docs Graphify validation in $contract must use isolated Python"
      return 1
    fi
  done
}

# --- Staged ↔ live config drift assertions ---

stage_live_agent_frontmatter_identical() {
  local agent="$1" staged_file="$2" live_file="$3"
  if [[ ! -f "$staged_file" ]]; then
    echo "[FAIL] staged agent $agent not found at $staged_file"
    return 1
  fi
  if [[ ! -f "$live_file" ]]; then
    echo "[FAIL] live agent $agent not found at $live_file"
    return 1
  fi
  if ! diff -q "$staged_file" "$live_file" >/dev/null 2>&1; then
    echo "[FAIL] staged and live $agent agent frontmatter differ — config drift"
    return 1
  fi
}

stage_live_command_binding_identical() {
  local cmd="$1"
  local staged_binding live_binding
  staged_binding="$(jq -r --arg c "$cmd" '.command[$c] // {}' "$CONFIG")"
  live_binding="$(jq -r --arg c "$cmd" '.command[$c] // {}' "$LIVE_CONFIG")"
  if [[ "$staged_binding" != "$live_binding" ]]; then
    echo "[FAIL] staged and live command $cmd binding differ — config drift"
    return 1
  fi
}

stage_live_permission_object_identical() {
  local agent="$1" perm="$2" key="$3"
  local staged_obj live_obj
  staged_obj="$(jq -r --arg a "$agent" --arg p "$perm" --arg k "$key" \
    '.agent[$a].permission[$p][$k] // "MISSING"' "$CONFIG")"
  live_obj="$(jq -r --arg a "$agent" --arg p "$perm" --arg k "$key" \
    '.agent[$a].permission[$p][$k] // "MISSING"' "$LIVE_CONFIG")"
  if [[ "$staged_obj" != "$live_obj" ]]; then
    echo "[FAIL] staged and live $agent permission $perm.$key differ — config drift"
    return 1
  fi
}

stage_live_repository_docs_route_is_exclusive() {
  local routes
  routes="$(jq -r --arg skill "$REPOSITORY_DOCS_SKILL" '
    .agent | to_entries[]
    | select((.value.permission.skill // {})[$skill] == "allow")
    | .key
  ' "$LIVE_CONFIG")"
  [[ "$routes" == "$REPOSITORY_DOCS_AGENT" ]]
}

stage_live_graphify_task_only_to_extractor() {
  local live_file="$LIVE_AGENTS/graphify.md"
  if [[ ! -f "$live_file" ]]; then
    echo "[FAIL] live graphify agent file not found at $live_file"
    return 1
  fi
  # Extract the task permission block from YAML frontmatter
  local task_block
  task_block="$(awk '/^permission:/{in_perm=1; next} in_perm && /^  task:/{in_task=1; next} in_task && /^  [a-z]/ && !/^    /{exit} in_task {print}' "$live_file")"
  if ! echo "$task_block" | grep -q '"\*": deny'; then
    echo "[FAIL] live graphify task permission missing deny-all"
    return 1
  fi
  if ! echo "$task_block" | grep -q 'graphify-extractor: allow'; then
    echo "[FAIL] live graphify task permission missing graphify-extractor allow"
    return 1
  fi
}

stage_live_repository_docs_external_directory_is_restricted() {
  local ext_dir
  ext_dir="$(jq -r '.agent["repository-docs"].permission.external_directory // {}' "$LIVE_CONFIG")"
  if [[ "$(echo "$ext_dir" | jq -r '.["*"]')" != "ask" ]]; then
    echo "[FAIL] live repository-docs external_directory missing ask-all"
    return 1
  fi
  if [[ "$(echo "$ext_dir" | jq -r '.["~/.agents/repositories/**"]')" != "allow" ]]; then
    echo "[FAIL] live repository-docs external_directory missing managed corpus allow"
    return 1
  fi
  if [[ "$(echo "$ext_dir" | jq -r 'keys | length')" -ne 2 ]]; then
    echo "[FAIL] live repository-docs external_directory has unexpected entries"
    return 1
  fi
}

is_disk_skill() { grep -Fxq -- "$1" <<<"$DISK_SKILLS"; }

is_builtin() {
  local s="$1" b
  for b in "${KNOWN_BUILTINS[@]}"; do [[ "$s" == "$b" ]] && return 0; done
  return 1
}

# Does on-disk skill set contain anything matching the given glob pattern?
wildcard_has_match() {
  local pattern="$1" disk
  while IFS= read -r disk; do
    [[ -z "$disk" ]] && continue
    # shellcheck disable=SC2053  # intentional glob match (pattern unquoted)
    [[ "$disk" == $pattern ]] && return 0
  done <<<"$DISK_SKILLS"
  return 1
}

fail_count=0
checked=0

while IFS=$'\t' read -r agent skill; do
  [[ -z "${agent:-}" || -z "${skill:-}" ]] && continue
  [[ "$skill" == "*" ]] && continue   # deny-all base, never an allow anyway
  checked=$((checked + 1))

  if [[ "$skill" == *"*"* ]]; then
    if ! wildcard_has_match "$skill"; then
      echo "[FAIL] $agent: wildcard '$skill' matches no skill on disk"
      fail_count=$((fail_count + 1))
    fi
  else
    if ! is_disk_skill "$skill" && ! is_builtin "$skill"; then
      echo "[FAIL] $agent: '$skill' not found on disk and not a known built-in"
      fail_count=$((fail_count + 1))
    fi
  fi
done <<<"$WHITELIST"

if ! repository_docs_route_is_exclusive; then
  echo "[FAIL] repository-docs skill route must be allowed only by repository-docs"
  fail_count=$((fail_count + 1))
fi

if ! repository_docs_command_routes_to_agent; then
  echo "[FAIL] /repository-docs command must be bound to repository-docs"
  fail_count=$((fail_count + 1))
fi

if ! repository_docs_command_keeps_subtask_enabled; then
  echo "[FAIL] /repository-docs command must keep subtask enabled (true or omitted)"
  fail_count=$((fail_count + 1))
fi

if ! repository_docs_sanitized_git_environment_is_complete; then
  fail_count=$((fail_count + 1))
fi

if ! repository_docs_graphify_route_uses_preinstalled_mode; then
  fail_count=$((fail_count + 1))
fi

if ! graphify_preinstalled_mode_has_no_install_path; then
  fail_count=$((fail_count + 1))
fi

if ! repository_docs_graphify_extract_keeps_default_ask; then
  fail_count=$((fail_count + 1))
fi

if ! graphify_preinstalled_mode_is_isolated_from_snapshot; then
  fail_count=$((fail_count + 1))
fi

if ! repository_docs_graphify_validation_is_isolated; then
  fail_count=$((fail_count + 1))
fi

# --- Staged ↔ live config drift assertions ---

if ! stage_live_agent_frontmatter_identical "repository-docs" \
  "$REPOSITORY_DOCS_AGENT_CONTRACT" \
  "$LIVE_AGENTS/repository-docs.md"; then
  fail_count=$((fail_count + 1))
fi

if ! stage_live_agent_frontmatter_identical "graphify" \
  "$REPO_ROOT/agents/graphify.md" \
  "$LIVE_AGENTS/graphify.md"; then
  fail_count=$((fail_count + 1))
fi

if ! stage_live_command_binding_identical "repository-docs"; then
  fail_count=$((fail_count + 1))
fi

if ! stage_live_permission_object_identical "repository-docs" "skill" "repository-docs"; then
  fail_count=$((fail_count + 1))
fi

if ! stage_live_permission_object_identical "repository-docs" "skill" "graphify"; then
  fail_count=$((fail_count + 1))
fi

if ! stage_live_permission_object_identical "graphify" "skill" "graphify"; then
  fail_count=$((fail_count + 1))
fi

if ! stage_live_repository_docs_route_is_exclusive; then
  echo "[FAIL] live repository-docs skill route must be allowed only by repository-docs — config drift"
  fail_count=$((fail_count + 1))
fi

if ! stage_live_graphify_task_only_to_extractor; then
  fail_count=$((fail_count + 1))
fi

if ! stage_live_repository_docs_external_directory_is_restricted; then
  fail_count=$((fail_count + 1))
fi

# --- Orphans: on-disk skills no agent allows (literal or via wildcard) — INFO ---
orphan_count=0
while IFS= read -r disk; do
  [[ -z "$disk" ]] && continue
  owned=0
  while IFS=$'\t' read -r _agent skill; do
    [[ -z "${skill:-}" || "$skill" == "*" ]] && continue
    if [[ "$skill" == *"*"* ]]; then
      # shellcheck disable=SC2053
      [[ "$disk" == $skill ]] && { owned=1; break; }
    else
      [[ "$disk" == "$skill" ]] && { owned=1; break; }
    fi
  done <<<"$WHITELIST"
  if [[ "$owned" -eq 0 ]]; then
    echo "[INFO] orphan skill (no agent whitelists it): $disk"
    orphan_count=$((orphan_count + 1))
  fi
done <<<"$DISK_SKILLS"

echo "---"
if [[ "$fail_count" -eq 0 ]]; then
  echo "[PASS] all $checked whitelist entries resolve to a real skill, built-in, or wildcard match ($orphan_count orphan(s), informational)"
  exit 0
else
  echo "[FAIL] $fail_count dead whitelist entr(ies) found out of $checked checked"
  exit 1
fi
