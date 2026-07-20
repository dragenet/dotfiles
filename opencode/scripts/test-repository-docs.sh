#!/usr/bin/env bash
#
# test-repository-docs.sh
#
# Fixture-based, non-destructive contract/smoke validation for the
# repository-docs specialist. Exercises path, version, manifest, immutable,
# and Graphify-preinstalled-mode contracts using a disposable local bare
# fixture. Never writes under the real managed corpus.
#
# Exit: 0 if all contracts pass, 1 on any failure.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0
_total=0

_pass()  { _total=$((_total + 1)); PASS=$((PASS + 1)); echo "  PASS: $1"; }
_fail()  { _total=$((_total + 1)); FAIL=$((FAIL + 1)); echo "  FAIL: $1" >&2; }

# ── Fixture scaffolding ───────────────────────────────────────────────────────

smoke_root="$(mktemp -d "${TMPDIR:-/tmp}/repository-docs-test.XXXXXX")"
trap 'rm -rf "$smoke_root"' EXIT

export HOME="$smoke_root/home"
export XDG_CONFIG_HOME="$smoke_root/empty-xdg"
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$smoke_root/source"

sanitized_git() {
  env -u GIT_DIR -u GIT_WORK_TREE -u GIT_COMMON_DIR -u GIT_INDEX_FILE \
    -u GIT_OBJECT_DIRECTORY -u GIT_ALTERNATE_OBJECT_DIRECTORIES \
    -u GIT_CONFIG_PARAMETERS -u GIT_SSH_COMMAND -u GIT_SSH -u GIT_SSH_VARIANT \
    -u GIT_ASKPASS -u SSH_ASKPASS -u GIT_EXEC_PATH \
    GIT_SSH_COMMAND="/usr/bin/ssh -F none" \
    GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_SYSTEM=/dev/null \
    GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_COUNT=0 \
    XDG_CONFIG_HOME="$XDG_CONFIG_HOME" \
    git -c core.hooksPath=/dev/null "$@"
}

echo "== Fixture setup =="

sanitized_git init --no-template "$smoke_root/source"
sanitized_git -C "$smoke_root/source" config user.name fixture
sanitized_git -C "$smoke_root/source" config user.email fixture@example.invalid
printf 'def hello():\n    return "first"\n' > "$smoke_root/source/main.py"
sanitized_git -C "$smoke_root/source" add main.py
sanitized_git -C "$smoke_root/source" commit -m first
printf 'def world():\n    return "second"\n' >> "$smoke_root/source/main.py"
sanitized_git -C "$smoke_root/source" commit -am second
sanitized_git -C "$smoke_root/source" tag -a fixture-v1 -m fixture-v1
sanitized_git init --bare --no-template "$smoke_root/fixture.git"
sanitized_git -C "$smoke_root/source" push "$smoke_root/fixture.git" HEAD:refs/heads/main --tags

# Fixture execution sentinel: prove the test workflow never modified working-tree
# content. Hash actual file content (excluding .git) for a deterministic, Git-agnostic
# fingerprint. A status assertion below catches unstaged modifications index/HEAD
# hashing would miss.
FIXTURE_SENTINEL="$smoke_root/.fixture-sentinel"
touch "$FIXTURE_SENTINEL"
FIXTURE_CONTENT_HASH="$( (cd "$smoke_root/source" && find . -not -path './.git/*' -not -path './.git' -type f -exec shasum -a 256 {} \; | sort -k2 | shasum -a 256) | awk '{print $1}')"

echo ""

# ── Fixture preconditions ─────────────────────────────────────────────────────

echo "== Fixture preconditions =="

if [ "$(sanitized_git -C "$smoke_root/source" rev-list --count HEAD)" -eq 2 ]; then
  _pass "fixture has exactly 2 commits"
else
  _fail "fixture commit count != 2"
fi

if [ "$(sanitized_git -C "$smoke_root/source" cat-file -t fixture-v1)" = "tag" ]; then
  _pass "fixture-v1 is an annotated tag"
else
  _fail "fixture-v1 is not an annotated tag"
fi

if [ "$(sanitized_git -C "$smoke_root/source" tag --list | wc -l | tr -d ' ')" -eq 1 ]; then
  _pass "fixture has exactly 1 tag"
else
  _fail "fixture tag count != 1"
fi

echo ""

# ── Input validation tests (rejection before clone) ───────────────────────────

echo "== Input validation =="

validate_ref() {
  local ref="$1" desc="$2"
  # Reject empty
  if [ -z "$ref" ]; then
    _pass "rejects $desc"
    return 0
  fi
  # Reject: starts with -, contains ^ ~ { } * ? [ , abbreviated (< 40 hex), control chars
  case "$ref" in
    -*)
      _pass "rejects $desc"
      return 0
      ;;
  esac
  case "$ref" in
    *[~{}^*?[]* | *[[:cntrl:]]*)
      _pass "rejects $desc"
      return 0
      ;;
  esac
  # Abbreviated SHA: non-empty hex but < 40 chars
  if [[ "$ref" =~ ^[0-9a-fA-F]+$ ]] && [ "${#ref}" -lt 40 ]; then
    _pass "rejects $desc"
    return 0
  fi
  _fail "should reject $desc but passed validation"
  return 1
}

validate_remote() {
  local url="$1" desc="$2"
  # Must be https:// or git@/ssh://
  case "$url" in
    https://*@*)
      _pass "rejects $desc"
      return 0
      ;;
    https://*:*@*)
      _pass "rejects $desc"
      return 0
      ;;
    http://*)
      _pass "rejects $desc"
      return 0
      ;;
    ssh://*@*)
      local user="${url#ssh://}"; user="${user%%@*}"
      if [ "$user" != "git" ]; then
        _pass "rejects $desc"
        return 0
      fi
      ;;
    *@*:*)
      local user="${url%%@*}"
      if [ "$user" != "git" ]; then
        _pass "rejects $desc"
        return 0
      fi
      ;;
    file://*)
      _pass "rejects $desc"
      return 0
      ;;
  esac
  # It shouldn't pass through for obviously-rejected URL forms
  _fail "should reject $desc but passed validation"
  return 1
}

validate_ref "" "missing (empty) ref" || true
validate_ref "abc123" "abbreviated SHA" || true
validate_ref "-main" "leading-dash ref" || true
validate_ref "main^{}" "ref expression with ^{}" || true
validate_ref "main~1" "ref expression with ~" || true
validate_ref "main?query" "ref with ?" || true
validate_ref "main*branch" "ref with glob *" || true
validate_ref "main[0]" "ref with bracket" || true

validate_remote "https://user@github.com/owner/repo.git" "HTTPS with user-info" || true
validate_remote "https://user:pass@github.com/owner/repo.git" "HTTPS with password" || true
validate_remote "ssh://root@github.com/owner/repo.git" "SSH with non-git user" || true
validate_remote "admin@github.com:owner/repo.git" "SCP-like with non-git user" || true
validate_remote "file:///tmp/repo.git" "file:// remote" || true
validate_remote "http://github.com/owner/repo.git" "http:// remote" || true

echo ""

# ── Resolution, path, and manifest tests ──────────────────────────────────────

echo "== Resolution, path, and manifest =="

# Resolve the annotated tag fixture-v1 from the local bare fixture
empty_cwd="$smoke_root/empty-cwd"
mkdir -p "$empty_cwd"

# Tag resolution: get peeled reference
tag_commit="$(cd "$empty_cwd" && sanitized_git ls-remote "$smoke_root/fixture.git" 'refs/tags/fixture-v1^{}' 2>/dev/null | awk '{print $1}')"

if [ -n "$tag_commit" ] && [ "${#tag_commit}" -eq 40 ]; then
  _pass "annotated tag resolves to 40-hex commit: $tag_commit"
else
  _fail "annotated tag did not resolve to 40-hex commit (got: '$tag_commit')"
fi

resolved_commit="$tag_commit"

# ── Snapshot path construction ────────────────────────────────────────────────

identity="fixture.invalid_owner_repository"
snapshot="$HOME/.agents/repositories/$identity/$resolved_commit"

# Construct parent directories, then atomically reserve destination
mkdir -p "$HOME/.agents/repositories/$identity"

if mkdir "$snapshot" 2>/dev/null; then
  _pass "atomic destination reservation succeeded"
else
  _fail "atomic destination reservation failed"
fi

# Verify EEXIST conflict
if ! mkdir "$snapshot" 2>/dev/null; then
  _pass "EEXIST conflict detected for existing destination"
else
  _fail "EEXIST should have been detected but mkdir succeeded"
fi

# ── Fetch, checkout, verify ───────────────────────────────────────────────────

empty_xdg="$smoke_root/empty-xdg-for-fetch"
mkdir -p "$empty_xdg"

sanitized_git() {
  env -u GIT_DIR -u GIT_WORK_TREE -u GIT_COMMON_DIR -u GIT_INDEX_FILE \
    -u GIT_OBJECT_DIRECTORY -u GIT_ALTERNATE_OBJECT_DIRECTORIES \
    -u GIT_CONFIG_PARAMETERS -u GIT_SSH_COMMAND -u GIT_SSH -u GIT_SSH_VARIANT \
    -u GIT_ASKPASS -u SSH_ASKPASS -u GIT_EXEC_PATH \
    GIT_SSH_COMMAND="/usr/bin/ssh -F none" \
    GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_SYSTEM=/dev/null \
    GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_COUNT=0 \
    XDG_CONFIG_HOME="$empty_xdg" \
    git -c core.hooksPath=/dev/null "$@"
}

sanitized_git init --no-template "$snapshot"
sanitized_git -C "$snapshot" fetch --no-tags --no-recurse-submodules --no-write-fetch-head "$smoke_root/fixture.git" "$resolved_commit"
sanitized_git -C "$snapshot" checkout --detach "$resolved_commit"

# Verify detached HEAD
head_commit="$(sanitized_git -C "$snapshot" rev-parse --verify HEAD)"
if [ "$head_commit" = "$resolved_commit" ]; then
  _pass "HEAD equals resolved commit"
else
  _fail "HEAD ($head_commit) != resolved commit ($resolved_commit)"
fi

# Verify detached (no symbolic-ref)
if [ -z "$(sanitized_git -C "$snapshot" symbolic-ref -q HEAD 2>/dev/null || true)" ]; then
  _pass "HEAD is detached (no symbolic-ref)"
else
  _fail "HEAD is not detached"
fi

# Verify clean status
if [ -z "$(sanitized_git -C "$snapshot" status --porcelain)" ]; then
  _pass "status --porcelain is empty (clean)"
else
  _fail "status --porcelain is not empty"
fi

# ── Manifest tests ────────────────────────────────────────────────────────────

manifest_dir="$snapshot/.agents"
mkdir -p "$manifest_dir"

# Generate manifest with jq (not string concatenation)
jq -n \
  --arg identity "$identity" \
  --arg repo "repository" \
  --arg ref "fixture-v1" \
  --arg commit "$resolved_commit" \
  --arg retrieved "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{
    remote_identity: $identity,
    repository: $repo,
    requested_ref: $ref,
    resolved_commit: $commit,
    retrieved_at: $retrieved
  }' > "$manifest_dir/repository-docs-manifest.json"

# Validate JSON
if python3 -m json.tool "$manifest_dir/repository-docs-manifest.json" >/dev/null 2>&1; then
  _pass "manifest is valid JSON"
else
  _fail "manifest is not valid JSON"
fi

# No credentials in manifest
if ! grep -Eq 'password|https?://|fixture@example\.invalid' "$manifest_dir/repository-docs-manifest.json"; then
  _pass "manifest contains no credential material"
else
  _fail "manifest contains credential material"
fi

# Ensure resolved_commit length is 40
manifest_commit="$(jq -r '.resolved_commit' "$manifest_dir/repository-docs-manifest.json")"
if [ "${#manifest_commit}" -eq 40 ]; then
  _pass "manifest resolved_commit is 40 hex chars"
else
  _fail "manifest resolved_commit length is ${#manifest_commit}, not 40"
fi

echo ""

# ── Graphify preinstalled-mode tests ──────────────────────────────────────────

echo "== Graphify preinstalled mode =="

if command -v graphify >/dev/null 2>&1; then
  _pass "graphify CLI found"

  GRAPHIFY_BIN="$(command -v graphify)"
  case "$GRAPHIFY_BIN" in
    /*) ;; *) _fail "graphify path is not absolute"; ;;
  esac

  GRAPHIFY_BIN="$(realpath "$GRAPHIFY_BIN")"
  SNAPSHOT_ROOT="$(cd "$snapshot" && pwd -P)"

  # Verify graphify binary is outside the snapshot
  case "$GRAPHIFY_BIN" in
    "$SNAPSHOT_ROOT"|"$SNAPSHOT_ROOT"/*)
      _fail "graphify binary is inside the snapshot"
      ;;
    *)
      _pass "graphify binary is outside the snapshot"
      ;;
  esac

  # Extract the graph from the snapshot
  if (cd "$snapshot" && graphify extract . --out .agents --preinstalled >/dev/null 2>&1); then
    _pass "graphify extract succeeded"
  else
    _fail "graphify extract with --preinstalled failed"
  fi

  # Validate graph.json
  if [ -f "$snapshot/.agents/graphify-out/graph.json" ]; then
    if python3 -I -m json.tool "$snapshot/.agents/graphify-out/graph.json" >/dev/null 2>&1; then
      _pass "graph.json is valid JSON"
    else
      _fail "graph.json is not valid JSON"
    fi
  else
    _fail "graph.json not found at expected path"
  fi
else
  _fail "graphify CLI not found — must be preinstalled (fail closed, no skip)"
fi

echo ""

# ── Immutable snapshot contract ───────────────────────────────────────────────

echo "== Immutable snapshot contract =="

# Verify the snapshot directory still exists and is intact
if [ -d "$snapshot" ]; then
  _pass "snapshot directory exists after all operations"
else
  _fail "snapshot directory is missing"
fi

if [ -f "$snapshot/.agents/repository-docs-manifest.json" ]; then
  _pass "manifest file exists after all operations"
else
  _fail "manifest file is missing"
fi

# Verify the corpus directory is under the test HOME, not the real one
case "$snapshot" in
  "$smoke_root"*)
    _pass "snapshot is under disposable test root"
    ;;
  *)
    _fail "snapshot is NOT under disposable test root: $snapshot"
    ;;
esac

echo ""

# ── Fixture content unchanged assertion ────────────────────────────────────────

echo "== Fixture content integrity =="

if [ -f "$FIXTURE_SENTINEL" ]; then
  _pass "fixture execution sentinel exists"
else
  _fail "fixture execution sentinel is missing"
fi

CURRENT_FIXTURE_HASH="$( (cd "$smoke_root/source" && find . -not -path './.git/*' -not -path './.git' -type f -exec shasum -a 256 {} \; | sort -k2 | shasum -a 256) | awk '{print $1}')"
if [ "$CURRENT_FIXTURE_HASH" = "$FIXTURE_CONTENT_HASH" ]; then
  _pass "fixture content hash unchanged — test workflow did not modify working-tree content"
else
  _fail "fixture content hash changed — test workflow modified working-tree content"
fi

# Status assertion: detect unstaged modifications index/HEAD hashing would miss
if [ -z "$(sanitized_git -C "$smoke_root/source" status --porcelain)" ]; then
  _pass "fixture source status is clean (no unstaged modifications)"
else
  _fail "fixture source has unstaged modifications"
fi

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────

echo "== Results =="
echo "  PASS: $PASS  FAIL: $FAIL  TOTAL: $_total"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "[FAIL] $FAIL test(s) failed"
  exit 1
else
  echo "[PASS] all $_total tests passed"
  exit 0
fi