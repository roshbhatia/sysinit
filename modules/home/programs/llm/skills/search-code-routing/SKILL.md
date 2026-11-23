---
name: search-code-routing
description: Choose rg, ast-grep, calldiff, or GitHub search for local code discovery, structural edits, and cross-repository lookup.
allowed-tools: Bash(rg:*) Bash(grep:*) Bash(ast-grep:*) Bash(gh:*) Read Glob
---

# Search code

| Question | Tool |
| --- | --- |
| Where is this literal, exact identifier, or file? | `rg`, paths, or native glob |
| Which declarations are in unfamiliar code? | `ast-grep outline` where the installed outline supports the language |
| Where does this call shape, signature, or syntax occur? | `ast-grep run -p '<pattern>' -l <language> <path>` |
| Who calls this, or which call paths did a diff move? | `calldiff`. Load `review-call-graph` for edge selection and supported languages. |
| What is in a repository outside the local checkout? | `gh search` for indexed repository, issue, PR, or code results. |

Start at the narrowest path that can answer the question. Read the surrounding
source before drawing a conclusion. Local reads show the actual checkout and
uncommitted changes. Treat ranked, indexed, or truncated results as samples.

The installed outline can return no declarations for Nix and Lua. Use an
explicit language with structural `ast-grep run` or read the relevant lines.
`calldiff` does not index Nix.

For multi-site syntax changes, preview the structural rewrite and inspect
every hunk before applying. See [structural rewrites](references/structural-rewrites.md)
for preview, application, and positive and negative pattern checks.
