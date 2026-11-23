# Structural rewrites

Use a structural rewrite when the same syntax change applies at multiple
sites. Choose the smallest path that contains the intended matches.

```sh
ast-grep run -p 'foo($A, $$$REST)' -r 'bar($A, $$$REST)' -l ts src/
ast-grep run -p 'foo($A, $$$REST)' -r 'bar($A, $$$REST)' -l ts -U src/
```

The first command previews the patch. Inspect each hunk before running the
second command, which applies all matches. Review the resulting diff and run
the relevant behavior check. An AST match establishes syntax shape.

## Build a pattern

1. Inspect the syntax with `ast-grep run --debug-query=ast -p '<example>' -l <language> <path>`.
   When the ast-grep MCP is available, `dump_syntax_tree` is another way to
   inspect representative source.
2. Compose the smallest necessary conditions. Use relational rules
   (`inside`, `has`, `follows`) and composite rules (`all`, `any`, `not`) for
   structure that one pattern cannot express.
3. Test on a known-positive and nearby negative snippet in separate fixture
   files. Use the CLI with an explicit path, or use MCP's `test_match_code_rule`
   where available.
4. Check language support and the known-positive result before interpreting an
   empty result as absence.
