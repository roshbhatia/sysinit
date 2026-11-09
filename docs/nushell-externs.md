# Nushell externs

Interactive Nushell loads typed external-command signatures and selected
structured-output declarations. Scripts started with `nu --no-config-file`
retain their own imports and behavior.

The `nushell` overlay pins upstream revision `09f275bd` (0.116.2), which includes
`@structured`. Stable 0.116.1 cannot parse these declarations. The overlay uses
the nixpkgs package once it reaches 0.117.0; the extern and plugin checks still
apply to that upgrade. The pinned source already includes the stable package's
TLS fixes.

## Using the declarations

At the terminal, commands keep their usual output. When Nushell consumes the
output, the declaration adds machine-readable flags and decodes the result:

```nu
git status                            # Ordinary Git status text
git status | where status =~ M        # Records with status, file, original_file
git log -n 10 | select short_hash author date subject
let changes = git status              # Capture structured records
docker ps | select ID Names State
gh pr list --author @me | select number title url
kubectl get pods -n default | get items.metadata.name
nix flake metadata | get locked
uv pip list | where name == pytest
```

Git status uses NUL-delimited porcelain output, preserving spaces, quotes,
newlines, and rename source paths. Git log returns `hash`, `short_hash`,
`author`, `date`, and `subject`; its field separators preserve subjects containing
quotes and vertical bars. Kubernetes lists retain their native `items` field;
single-resource requests return the resource record.
The Git change table excludes branch and stash header lines. Use the caret
form for streaming output such as `^kubectl get pods --watch` or Git log output
that includes patches or statistics.

Use `^` for a text pipeline or an alternate output format:

```nu
^git log --oneline -n 10 | lines
^kubectl get pods -o wide | lines
^gh pr list --json number --jq '.[].number' | lines
```

User arguments follow the injected arguments. An explicit output flag can
therefore replace the declaration's format and make its decoder fail. Use the
caret form in that case. Redirection, `print`, `save`, `complete`, `tee`, `ignore`,
and pipes directly into another external command retain native output, as
described in the [Nushell extern documentation](https://www.nushell.sh/book/externs.html#structured-output).

Declarations match the command's leading words. Put supported global options
after the subcommand, such as `gh pr list --repo owner/repo` or
`kubectl get pods --context name`. Inserting options between the leading words,
such as `gh --repo owner/repo pr list`, uses the ordinary external invocation.

## Coverage and ownership

| Commands | Structured result |
| --- | --- |
| `git status`, `git log` | Change records and commit records |
| `gh pr list`, `gh issue list`, `gh run list` | Selected GitHub JSON fields |
| `docker ps`, `docker images`, their long forms, `docker inspect`, `docker context ls` | Native Docker records |
| `nix flake metadata`, `nix flake show`, `nix path-info` | Native Nix JSON |
| `kubectl get`, `kubecolor get`, `k get`, `kubectl config view` | Native Kubernetes JSON |
| `uv pip list`, `cargo metadata`, `pueue status`, `colima list` | Native tool JSON |

`modules/home/programs/nushell/lib.nix` imports completion signatures for Git,
Nix, Docker, Cargo, uv, ripgrep, SSH, and just from the nixpkgs-pinned
`nu_scripts` package. It then imports the local Git and structured-tool modules.
Other commands retain the existing Fish/Carapace completion fallback.
The local declarations use `@complete external` to retain that dynamic
completion alongside their typed flags.
The pinned community GitHub module uses a deprecated command form, so GitHub
uses the local declarations and Carapace completion.

`git add` declares variadic path arguments. Structured declarations cover read
commands; commands such as `git branch` retain their existing completion
signature because they also perform mutations.

`checks/nushell-externs.nix` exercises real Git repositories and CLI fixtures
through the actual Nushell declarations. The checks cover format argument
injection, variable capture, native output, caret escape, filenames, renames,
empty results, invalid JSON, external failures, and completion. They do not
query GitHub, Kubernetes, or cloud accounts.
