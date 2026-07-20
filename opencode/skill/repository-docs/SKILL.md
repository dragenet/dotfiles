---
name: repository-docs
description: Use ONLY for `/repository-docs add <git-url> --ref <branch|tag|40-hex-commit>`, `/repository-docs query <repository-id>@<40-hex-commit> "<question>"`, or `/repository-docs list` to create immutable, Graphify-indexed Git documentation snapshots under `$HOME/.agents/repositories`.
---

# Repository Documentation Snapshots

Use this skill only through the `repository-docs` specialist. It creates and
queries immutable documentation snapshots; it is not a general-purpose Git
checkout, source browsing, or repository maintenance workflow.

## Non-negotiable safety rules

- Require exactly one explicit `--ref <branch|tag|40-hex-commit>` for `add`.
- Never display, log, store, or place credentials in a command or manifest.
  Let normal Git credential handling obtain any required credential.
- Never run fetched repository code, hooks, package managers, install scripts,
  build scripts, watches, or submodule commands. Do not initialize, fetch, or
  recurse into submodules.
- Never delete, overwrite, alter, repoint, clean, force-reset, or push a
  snapshot. A destination that already exists is a conflict, not a reason to
  reuse or repair it.
- Never use a repository checkout to answer `query`; queries must use only the
  already-built Graphify graph.

## Command contracts

```text
/repository-docs add <git-url> --ref <branch|tag|40-hex-commit>
/repository-docs query <repository-id>@<40-hex-commit> "<question>"
/repository-docs list
```

Reject malformed arguments before making a network request, creating a
directory, or invoking Git.

### Shared validation

Reject an input containing a NUL, newline, carriage return, or other control
character. Treat command arguments as opaque values: invoke Git and Graphify
with an argument array (never with interpolated shell text), terminate options
with `--` where the command supports it, and do not evaluate a value as shell
syntax.

#### Remote validation

Accept only these remote forms:

- `https://<host>/<owner>/<repository>[.git]`, with no user-info, query, or
  fragment; and
- SSH using the exact `git` user: `git@<host>:<owner>/<repository>[.git]` or
  `ssh://git@<host>/<owner>/<repository>[.git]`.

Reject every other scheme or SCP-like username, including `http://`,
`file://`, `git://`, `https://user@host/...`,
`https://user:password@host/...`, `ssh://user@host/...`, `root@host:path`,
hostless remotes, query strings, fragments, and any embedded credential or
token. Reject user-info independently from permitting `git@` SSH remotes.

Parse the accepted remote into lowercase-safe, sanitized `host`, `owner`, and
`repository` components. Each output component may contain only letters,
digits, `.`, `_`, and `-`; replace no value silently. If parsing cannot produce
all three unambiguous components, reject it. Remove a terminal `.git` only from
the repository component. The immutable repository identity is:

```text
<host>_<owner>_<repository>
```

Do not store the original remote URL, even when it passed validation.

#### Ref validation

Require a non-empty ref value. Reject it when it:

- starts with `-`;
- contains `^`, `~`, `{`, `}`, `*`, `?`, or `[`;
- contains a control character or whitespace that changes argument grammar;
- is an abbreviated SHA or any hexadecimal commit value other than exactly
  40 ASCII hexadecimal characters; or
- is a Git object expression rather than a literal branch, tag, or full SHA.

Do not accept a `refs/...` expression as a way to bypass branch/tag ambiguity.
For a non-SHA ref, resolve only an exact branch or exact tag name.

## `add` workflow

### Required sanitized Git invocation environment

Every Git invocation in this workflow and its test harness must run through
this single `sanitized_git` environment wrapper; do not invoke `git` directly.
It clears inherited repository-location and object-store variables, suppresses
all configuration sources and injected configuration, and disables hooks:

```bash
sanitized_git() {
  env -u GIT_DIR -u GIT_WORK_TREE -u GIT_COMMON_DIR -u GIT_INDEX_FILE \
    -u GIT_OBJECT_DIRECTORY -u GIT_ALTERNATE_OBJECT_DIRECTORIES \
    -u GIT_CONFIG_PARAMETERS \
    GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_SYSTEM=/dev/null \
    GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_COUNT=0 \
    XDG_CONFIG_HOME=<empty-config-dir> \
    git -c core.hooksPath=/dev/null "$@"
}
```

`<empty-config-dir>` and `<empty-git-cwd>` are each a dedicated empty
non-repository directory. Run every
`sanitized_git ls-remote` from that directory, never from the caller's current
working directory.

### 1. Resolve an immutable commit

For a branch or tag, use a no-side-effect remote listing with the validated URL
as a single argument. Before every `sanitized_git ls-remote`, create the
dedicated empty non-repository `<empty-git-cwd>` and run the command from that
directory. This excludes system, global, runtime-injected, and inherited
repository-location Git configuration. Request the exact branch and tag names,
including the peeled tag result:

```text
cd <empty-git-cwd> && sanitized_git ls-remote --refs --tags <url> refs/tags/<ref>
cd <empty-git-cwd> && sanitized_git ls-remote <url> refs/tags/<ref> refs/tags/<ref>^{}
cd <empty-git-cwd> && sanitized_git ls-remote --heads <url> refs/heads/<ref>
```

Interpret the output strictly:

- A branch resolves only from exactly one `refs/heads/<ref>` line containing a
  40-hex object ID.
- A lightweight tag resolves from exactly one `refs/tags/<ref>` 40-hex line.
- An annotated tag must use exactly one peeled `refs/tags/<ref>^{}` 40-hex
  line as the commit; do not use its tag-object ID.
- Reject absent, ambiguous, malformed, or non-40-hex results, including a name
  that resolves as both a branch and tag.

For a full 40-hex SHA, do **not** use `git ls-remote`: servers commonly expose
only advertised branches and tags. Treat it as a proposed commit and verify it
only through the constrained fetch below.

The resolved commit is always lowercase 40-hex and is the sole checkout target.

### 2. Reserve the immutable destination

Construct only this destination:

```text
$HOME/.agents/repositories/<host>_<owner>_<repository>/<resolved-commit>
```

Construct missing parent directories without traversing or inspecting repository
content, then atomically reserve the final destination with `mkdir <destination>`
(never `mkdir -p <destination>`). `mkdir` returning `EEXIST` is a conflict: if
the final destination exists for any reason (empty, partial, populated, or with
`.git`), stop and report it. Reserve the destination before initialization; do
not overwrite, delete, reuse, repair, inspect, or infer that it is identical.

### 3. Fetch without executing repository content

Before initializing the reserved destination, create the dedicated empty
`<empty-config-dir>` and use `sanitized_git` for every Git command. The
environment prevents system/global, runtime-injected, and inherited
repository-location configuration (including filter processes and URL rewrites)
from running; `core.hooksPath=/dev/null` separately disables hooks. Invoke the
following commands as argument arrays, retaining the option order and using the
validated URL, destination, and commit as literal arguments. Never add a remote
or persist the raw URL in Git config:

```text
sanitized_git init --no-template <destination>
sanitized_git -C <destination> fetch --no-tags --no-recurse-submodules --no-write-fetch-head <url> <resolved-commit>
sanitized_git -C <destination> checkout --detach <resolved-commit>
sanitized_git -C <destination> status --porcelain
sanitized_git -C <destination> fsck --no-progress
```

The fetch is the required proof that a proposed raw SHA exists and is
retrievable. For every ref type, reject the operation unless checkout is
detached at exactly `resolved-commit`, `status --porcelain` is empty, and
`fsck` reports no errors. If any command fails, report the failure without
attempting cleanup or deletion; preserve the resulting directory as an
incomplete conflict. Do not retry in place.

### 4. Write a safe manifest

After Git verification succeeds, create only:

```text
<destination>/.agents/repository-docs-manifest.json
```

Create `.agents/` without executing repository content. Generate JSON with a
real JSON encoder (for example, `jq -n --arg ...`), not string concatenation,
and validate it before proceeding. Its exact shape is:

```json
{
  "remote_identity": "<sanitized-host-and-owner>",
  "repository": "<sanitized-repo-name>",
  "requested_ref": "<original-literal-ref>",
  "resolved_commit": "<40-hex-commit>",
  "retrieved_at": "<RFC-3339 timestamp>"
}
```

`remote_identity` and `repository` are derived from sanitized components only.
Never include a raw URL, username, password, token, query, fragment, or other
credential material. Validate the manifest with:

```text
python3 -m json.tool .agents/repository-docs-manifest.json
```

### 5. Build and validate the graph

Require that the Graphify CLI is already installed and available before starting
the operation. If it is unavailable, fail closed; do not install Graphify,
delegate installation, or create a substitute graph. Delegate only indexing to
`@graphify`. From the snapshot directory, perform exactly the canonical
extraction:

```text
graphify extract . --out .agents
```

Do not use `graphify update`, do not create output elsewhere, and do not run a
watch, hook installer, package installer, or repository script. Require this
file and validate its JSON before success:

```text
.agents/graphify-out/graph.json
python3 -m json.tool .agents/graphify-out/graph.json
```

Report the repository identity, resolved commit, immutable snapshot path, and
graph-validation result. Do not report the raw remote URL.

## `query` workflow

1. Parse only `<repository-id>@<40-hex-commit>` plus one non-empty natural
   language question. The identity must match the sanitized identity grammar;
   the commit must be exactly 40 hexadecimal characters.
2. Require an existing snapshot and an existing, JSON-valid graph at:

   ```text
   $HOME/.agents/repositories/<repository-id>/<commit>/.agents/graphify-out/graph.json
   ```

3. Delegate only this graph-backed query to `@graphify`:

   ```text
   graphify query "<question>" --graph .agents/graphify-out/graph.json
   ```

   Run it from the snapshot directory, passing the question as one literal
   argument. Never extract/rebuild, list, grep, read, or otherwise broad-read
   the repository checkout to answer a query.
4. Return the graph result with its available graph source citations. If the
   graph is missing, invalid, or the query fails, report that exact condition;
   do not substitute a checkout scan or a rebuilt graph.

## `list` workflow

Enumerate only the managed corpus directory structure and the manifest path:

```text
$HOME/.agents/repositories/<repository-id>/<40-hex-commit>/.agents/repository-docs-manifest.json
```

For each JSON-valid manifest, return identity, resolved commit, requested ref,
and retrieval date. This is manifest-only enumeration: do not inspect checkout
files, Git metadata, or graph contents. If the managed corpus does not exist,
return an empty list. If an entry is malformed or lacks a manifest, identify
the path as invalid/incomplete without inferring values or deleting anything.

## Errors and public smoke evidence

Fail closed and state the operation, validated identifier (never raw remote
with credentials), and condition: invalid remote/ref, unresolved or ambiguous
ref, existing destination, fetch/checkout/clean/fsck failure, invalid manifest,
or missing/invalid Graphify output.

### Task3 test-harness-only local fixture

Run this disposable local-fixture smoke flow only when an operator requests
Task3 test-harness-only verification. The test runner, using its own setup
permissions, performs every fixture setup action below; the production
`repository-docs` specialist must never perform them. It creates neither a
real corpus entry nor a network connection:

```bash
set -euo pipefail
smoke_root="$(mktemp -d)"
trap 'rm -rf "$smoke_root"' EXIT
export HOME="$smoke_root/home"
export XDG_CONFIG_HOME="$smoke_root/empty-xdg"
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$smoke_root/source"
sanitized_git() {
  env -u GIT_DIR -u GIT_WORK_TREE -u GIT_COMMON_DIR -u GIT_INDEX_FILE \
    -u GIT_OBJECT_DIRECTORY -u GIT_ALTERNATE_OBJECT_DIRECTORIES \
    -u GIT_CONFIG_PARAMETERS \
    GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_SYSTEM=/dev/null \
    GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_COUNT=0 \
    XDG_CONFIG_HOME="$XDG_CONFIG_HOME" \
    git -c core.hooksPath=/dev/null "$@"
}

sanitized_git init --no-template "$smoke_root/source"
sanitized_git -C "$smoke_root/source" config user.name fixture
sanitized_git -C "$smoke_root/source" config user.email fixture@example.invalid
printf 'first\n' > "$smoke_root/source/README.md"
sanitized_git -C "$smoke_root/source" add README.md
sanitized_git -C "$smoke_root/source" commit -m first
printf 'second\n' >> "$smoke_root/source/README.md"
sanitized_git -C "$smoke_root/source" commit -am second
sanitized_git -C "$smoke_root/source" tag -a fixture-v1 -m fixture-v1
sanitized_git init --bare --no-template "$smoke_root/fixture.git"
sanitized_git -C "$smoke_root/source" push "$smoke_root/fixture.git" HEAD:refs/heads/main --tags

# Clear fixture assertion: exactly two commits and one annotated tag exist.
test "$(sanitized_git -C "$smoke_root/source" rev-list --count HEAD)" = 2
test "$(sanitized_git -C "$smoke_root/source" cat-file -t fixture-v1)" = tag
test "$(sanitized_git -C "$smoke_root/source" tag --list | wc -l | tr -d ' ')" = 1
```

Production remote-validation assertions are separate from this fixture: assert
that the input validator rejects a missing ref, abbreviated SHA, `--ref=-main`,
`main^{}`, glob-containing refs, credential-bearing HTTPS URLs, and every local
path or `file://` remote. A local/file remote does not pass production URL
validation and must never be submitted to the production workflow.

Separately, the Task3 harness may use
`<url>="$smoke_root/fixture.git"` and `<ref>=fixture-v1` only to exercise the
pure local Git and Graphify assertions below with test-runner permissions. This
does not exercise production remote validation or require the production
specialist to run setup actions it is denied. Its test-only destination is below
`$HOME/.agents/repositories/fixture.invalid_owner_repository/<resolved-commit>`.
After the harness completes its lower-level sanitized Git sequence, assert:

```bash
test "$(sanitized_git -C "$snapshot" rev-parse --verify HEAD)" = "$resolved_commit"
test "$(sanitized_git -C "$snapshot" symbolic-ref -q HEAD || true)" = ""
test -z "$(sanitized_git -C "$snapshot" status --porcelain)"
test "${#resolved_commit}" = 40
python3 -m json.tool "$snapshot/.agents/repository-docs-manifest.json" >/dev/null
! grep -Eq 'password|https?://|fixture@example\.invalid' "$snapshot/.agents/repository-docs-manifest.json"
```

Require an already-installed Graphify binary. Run `graphify extract . --out
.agents` from `$snapshot`, then require
`python3 -m json.tool "$snapshot/.agents/graphify-out/graph.json" >/dev/null`.
If Graphify is unavailable, the harness must fail closed; it must not install,
delegate installation, or create a graph stub. The smoke flow must never write
to the real `$HOME/.agents/repositories` corpus because `HOME` is redirected
above.
