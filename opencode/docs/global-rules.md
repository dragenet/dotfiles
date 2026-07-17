# Global Rules

> Safety hard rules (reboot/destructive-command protections) live canonically in
> `AGENTS.md` ("Global Hard Rules") — loaded via the most robust channel.

## Filesystem Safety

- NEVER guess, assume, or fabricate filesystem paths — especially usernames in paths like `/Users/<name>/`
- ALWAYS run `pwd` to determine the current working directory before any filesystem operation
- The current user's home directory is available via `$HOME` — never hardcode or guess usernames
- If you need the home directory path, run `echo $HOME` — do not invent it

## Web Content Rules

Route web work to the specialist that matches its scope:

- **Fast fact, version, API flag, or provider reference** → `@web-fast-context`
  using raw `websearch` and `webfetch`.
- **Multi-source research and synthesis** → `@webresearcher`.
- **Known-URL extraction, crawl, or JavaScript interaction** → `@webscraper`.
- **Page change tracking** → `@webmonitor`.

Use `@web-fast-context` for quick sourced context only. Use the Firecrawl
specialists for their corresponding research, extraction, and monitoring work.

> Full, current agent list: see "Agent Roster" in `AGENTS.md`.
