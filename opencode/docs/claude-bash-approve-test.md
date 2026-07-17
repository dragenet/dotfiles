# claude-bash-approve isolated classifier test

Tested: 2026-07-16

Upstream: https://github.com/mariusvniekerk/claude-bash-approve

Commit tested: `ef2f5bb72f6ff57df5a011f3fad6c79f66395d4e`

Runtime versions:

- Go: `go version go1.26.4 darwin/arm64`
- OpenCode: `1.18.2`

## Scope

This was an isolated adapter-level test only. The repository was cloned to
`/var/folders/6c/27klmgf913z0m5p82f3s7mf80000gp/T/opencode/claude-bash-approve.IIkWix`.
The Go classifier was built there with `go build -o ./approve-bash .` from
`hooks/bash-approve`. No installer was run, no runtime was installed outside
that clone, and `~/.config/opencode` was not read or modified.

The OpenCode adapter accepts a JSON object on stdin with `tool`, `command`, and
`cwd` fields. It writes a JSON decision. `noop` means the adapter has no
opinion and defers to OpenCode's normal permission flow.

## Observed decisions

All commands below classify input only; they do not execute the embedded shell
command. The clone directory was the harmless `cwd` in each payload.

```sh
cd /var/folders/6c/27klmgf913z0m5p82f3s7mf80000gp/T/opencode/claude-bash-approve.IIkWix/hooks/bash-approve
go build -o ./approve-bash .

printf '%s\n' '{"tool":"bash","command":"git status","cwd":"/var/folders/6c/27klmgf913z0m5p82f3s7mf80000gp/T/opencode/claude-bash-approve.IIkWix"}' | ./approve-bash --opencode
# {"decision":"allow","reason":"git read op"}

printf '%s\n' '{"tool":"bash","command":"rm -r some-path","cwd":"/var/folders/6c/27klmgf913z0m5p82f3s7mf80000gp/T/opencode/claude-bash-approve.IIkWix"}' | ./approve-bash --opencode
# {"decision":"deny","reason":"BLOCKED: rm -r is banned. Remove specific files only, not entire directory trees."}

printf '%s\n' '{"tool":"bash","command":"git push","cwd":"/var/folders/6c/27klmgf913z0m5p82f3s7mf80000gp/T/opencode/claude-bash-approve.IIkWix"}' | ./approve-bash --opencode
# {"decision":"noop","reason":"git push"}

go test ./...
# ok   bash-approve  8.273s
```

The classifier and OpenCode adapter therefore work in isolation: `git status`
was allowed, destructive `rm -r` was denied, and publish command `git push`
deferred instead of receiving a false allow.

## Deployment TODO

Active integration is deliberately deferred. The installer's global scope
modifies the live `~/.config/opencode`, while its project scope embeds an
absolute runtime path; neither is appropriate before deployment.

During the symlink/deploy phase, choose and review a portable hook-runtime path,
then install with global scope only after the staged configuration is live.
