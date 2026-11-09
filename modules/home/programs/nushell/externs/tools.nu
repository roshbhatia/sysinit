# List pull requests; piping returns selected GitHub fields.
@complete external
@structured [--json "number,title,url,state,isDraft,author,headRefName,baseRefName,updatedAt"] { from json --strict }
export extern "gh pr list" [
  --repo(-R): string
  --limit(-L): int
  --state(-s): string
  --author(-A): string
  --assignee(-a): string
  --base(-B): string
  --head(-H): string
  --label(-l): string
  --search(-S): string
  --draft(-d)
  --web(-w)
  --json: string
  --jq(-q): string
  --template(-t): string
]

# List issues; piping returns selected GitHub fields.
@complete external
@structured [--json "number,title,url,state,author,assignees,labels,updatedAt"] { from json --strict }
export extern "gh issue list" [
  --repo(-R): string
  --limit(-L): int
  --state(-s): string
  --author(-A): string
  --assignee(-a): string
  --label(-l): string
  --search(-S): string
  --mention: string
  --milestone(-m): string
  --web(-w)
  --json: string
  --jq(-q): string
  --template(-t): string
]

# List workflow runs; piping returns selected GitHub fields.
@complete external
@structured [--json "databaseId,workflowName,headBranch,status,conclusion,url,createdAt"] { from json --strict }
export extern "gh run list" [
  --repo(-R): string
  --limit(-L): int
  --branch(-b): string
  --workflow(-w): string
  --status(-s): string
  --event(-e): string
  --commit(-c): string
  --user(-u): string
  --json: string
  --jq(-q): string
  --template(-t): string
]

# List containers; piping returns Docker's JSON records.
@complete external
@structured [--format "{{json .}}"] { collect | from json --objects --strict }
export extern "docker container ls" [
  --all(-a)
  --filter(-f): string
  --format: string
  --last(-n): int
  --latest(-l)
  --no-trunc
  --quiet(-q)
  --size(-s)
]

# List images; piping returns Docker's JSON records.
@complete external
@structured [--format "{{json .}}"] { collect | from json --objects --strict }
export extern "docker image ls" [
  repository?: string
  --all(-a)
  --digests
  --filter(-f): string
  --format: string
  --no-trunc
  --quiet(-q)
  --tree
]

export alias "docker ps" = docker container ls
export alias "docker images" = docker image ls

# Inspect Docker objects; piping decodes the native JSON array.
@complete external
@structured [] { from json --strict }
export extern "docker inspect" [
  ...objects: string
  --format(-f): string
  --size(-s)
  --type: string
]

# List Docker contexts; piping returns JSON records.
@complete external
@structured [--format "{{json .}}"] { collect | from json --objects --strict }
export extern "docker context ls" [
  --format: string
  --quiet(-q)
]

# Read flake metadata; piping returns the native JSON record.
@complete external
@structured [--json] { from json --strict }
export extern "nix flake metadata" [
  flake?: string
  --json
  --no-write-lock-file
  --offline
  --refresh
]

# Show flake outputs; piping returns the native JSON record.
@complete external
@structured [--json] { from json --strict }
export extern "nix flake show" [
  flake?: string
  --json
  --all-systems
  --legacy
  --no-write-lock-file
]

# Read store-path metadata; piping returns the native JSON value.
@complete external
@structured [--json] { from json --strict }
export extern "nix path-info" [
  ...installables: string
  --json
  --recursive(-r)
  --closure-size(-S)
  --size(-s)
  --store: string
]

# Read Kubernetes resources; lists retain their native items field.
@complete external
@structured [-o json] { from json --strict }
export extern "kubectl get" [
  ...resources: string
  --namespace(-n): string
  --context: string
  --all-namespaces(-A)
  --selector(-l): string
  --field-selector: string
  --output(-o): string
  --watch(-w)
  --ignore-not-found
]

@complete external
@structured [-o json] { from json --strict }
export extern "kubecolor get" [
  ...resources: string
  --namespace(-n): string
  --context: string
  --all-namespaces(-A)
  --selector(-l): string
  --field-selector: string
  --output(-o): string
  --watch(-w)
  --ignore-not-found
]

@complete external
@structured [-o json] { from json --strict }
export extern "k get" [
  ...resources: string
  --namespace(-n): string
  --context: string
  --all-namespaces(-A)
  --selector(-l): string
  --field-selector: string
  --output(-o): string
  --watch(-w)
  --ignore-not-found
]

# Read kubeconfig using kubectl's default credential redaction.
@complete external
@structured [-o json] { from json --strict }
export extern "kubectl config view" [
  --context: string
  --minify
  --flatten
  --output(-o): string
]

# List installed Python packages; piping returns package records.
@complete external
@structured [--format json] { from json --strict }
export extern "uv pip list" [
  --python(-p): string
  --system
  --outdated(-o)
  --editable(-e)
  --format: string
]

# Read Cargo workspace metadata; piping decodes the native JSON record.
@complete external
@structured [--format-version "1"] { from json --strict }
export extern "cargo metadata" [
  --manifest-path: path
  --no-deps
  --offline
  --locked
  --frozen
  --features: string
  --all-features
  --no-default-features
  --filter-platform: string
  --format-version: int
]

# Read task execution state; piping returns Pueue's native JSON record.
@complete external
@structured [--json] { from json --strict }
export extern "pueue status" [
  ...query: string
  --json(-j)
  --group(-g): string
]

# List local Colima instances; piping returns JSON records.
@complete external
@structured [--json] { collect | from json --objects --strict }
export extern "colima list" [
  --json(-j)
]
