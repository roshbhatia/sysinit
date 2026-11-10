# Pick a captured thread in the current folder, then resume, fork, or inspect it.
@complete external
export extern threads [
  --all(-a)                     # Include threads from every folder
  --print                       # Print the launch command
  --help(-h)
  ...args: string
]

def thread-output-styles [] {
  [auto plain pretty json ndjson]
}

def thread-search-harnesses [] {
  [claude-code codex opencode pi omp]
}

# List captured threads; piping returns thread records.
@structured [--style json] { from json --strict }
export extern "atuin threads list" [
  --style: string@thread-output-styles
  --help(-h)
]

# Read a captured thread; piping returns its native JSON representation.
@structured [--style json] { from json --strict }
export extern "atuin threads show" [
  thread: string
  --style: string@thread-output-styles
  --help(-h)
]

# Search captured threads; piping returns matching thread records.
@structured [--style json] { from json --strict }
export extern "atuin threads search" [
  ...query: string
  --harness: string@thread-search-harnesses
  --limit: int
  --style: string@thread-output-styles
  --help(-h)
]

# These wrapper subcommands pass directly through to Atuin.
export alias "threads list" = atuin threads list
export alias "threads show" = atuin threads show
export alias "threads search" = atuin threads search
export alias "threads resume" = atuin threads resume
export alias "threads tail" = atuin threads tail
export alias "threads import" = atuin threads import
export alias "threads enable" = atuin threads enable
