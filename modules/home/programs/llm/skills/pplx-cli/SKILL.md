---
description: 'Uses the Perplexity CLI (`pplx`) for general external web research: live web search and page-content fetch returning structured JSON. Auth-conditional: use pplx only when authenticated (`PERPLEXITY_API_KEY` set or a `pplx auth login` credentials file), otherwise fall back to the built-in WebSearch/WebFetch. Never send internal, private, or in-repo content to pplx. Use when doing external/public web research, not for internal docs or private data.'
allowed-tools: Bash(pplx:*)
---

Use the Perplexity CLI (`pplx`) for general external web research: live web
search and page-content fetch that return structured JSON.

## Auth-conditional routing (check first)

`pplx` only works when authenticated. Decide the tool at runtime:

1. Check auth: `PERPLEXITY_API_KEY` is set, OR a credentials file exists from a
   prior `pplx auth login` (`${XDG_CONFIG_HOME:-$HOME/.config}/perplexity/credentials.json`,
   or the macOS Application Support path). There is no `pplx auth status`
   subcommand; the only auth subcommand is `login`.
2. If authed AND the target is external, public information: use `pplx`.
3. If NOT authed: fall back to the built-in WebSearch/WebFetch. Do not call
   `pplx`; do not block on a login prompt.
4. NEVER send internal, private, or in-repo content to `pplx`: use local
   tools (grep, Read, ast-grep) for anything in this repo or on this machine.

```bash
# good — a public question, no repo content in the query
pplx search web "nixpkgs cctools ld64 darwin link failure tracking issue"

# bad — ships a private path and the repo's own code to a third party
pplx search web "why does overlays/lima.nix fail with $(cat overlays/lima.nix)"
```

Auth setup is the owner's job: `pplx auth login` (interactive, needs a TTY),
or export `PERPLEXITY_API_KEY` (non-interactive; `auth login` rejects piped
input). The env var takes precedence over stored credentials.

## Commands

```
pplx search web "<query>" [-n COUNT] [--domains a.com,b.com] \
  [--recency-filter] [--published-after-date MM/DD/YYYY] \
  [--output-dir DIR] [--stdout-preview N]

pplx content fetch "<url>" [--no-cache] [--html] \
  [--output-dir DIR] [--stdout-preview N]
```

## Rules and pitfalls

- Success prints JSON to stdout; an error prints a JSON error object to stderr
  with exit code 1. Parse stderr for errors; stdout carries results only.
- Pass `--output-dir` together with `--stdout-preview N` for large results;
  a bare `--stdout-preview` still writes full-size output.
- Multiple positional query terms reformulate ONE search; they do not run
  separate searches. Run `pplx search web` again for a distinct query.
- Date flags use MM/DD/YYYY, not ISO dates.
- When authed, `pplx content fetch <url>` MAY serve as the snapshot fetcher
  for `citelock capture`; the quote-anchor semantics are unchanged.
