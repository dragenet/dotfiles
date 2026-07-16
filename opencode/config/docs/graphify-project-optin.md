# Graphify Project Opt-In Template

Copy this block into a project's `AGENTS.md` only after agreeing with the user
that graphify is appropriate for that project.

```markdown
## Graphify

Graphify is enabled for this project. Its graph output is stored in
`graphify-out/`.

Route repository-structure questions to `@graphify` rather than broad manual
reads of the repository.

Build the initial graph with `@graphify`, then install the post-commit hook:
`graphify hook install`. Code-only commits update the graph automatically.
Documentation or image changes require `@graphify` or a manual
`graphify . --update`.

Graphify is opt-in per project, not a global mandatory rule. Agree with the
user before enabling it for a project.
```
