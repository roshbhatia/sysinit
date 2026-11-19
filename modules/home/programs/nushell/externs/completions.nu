def "nu-complete taskwarrior" [] {
    let commands = ^taskwarrior _commands | lines | where not ($it | str starts-with "_")
    [
        ...(
            ^taskwarrior rc.verbose=nothing _zshids
            | lines
            | parse "{value}:{description}"
        )
        ...($commands | each {|command| {value: $command, description: command} })
        ...(
            ^taskwarrior _projects
            | lines
            | each {|project| {value: $"project:($project)", description: project} }
        )
        ...(
            ^taskwarrior _tags
            | lines
            | each {|tag| {value: $"+($tag)", description: tag} }
        )
    ]
}

# Taskwarrior; completes task IDs, commands, projects, and tags.
export extern taskwarrior [
  ...args: string@"nu-complete taskwarrior"
]

def "nu-complete go-task targets" [] {
    let listing = ^task --list-all --json | complete
    if $listing.exit_code != 0 { return [] }
    $listing.stdout | from json | get tasks | each {|target|
    {value: $target.name, description: ($target.desc? | default "")}
  }
}

def "nu-complete go-task output" [] { [interleaved group prefixed] }
def "nu-complete go-task sort" [] { [default alphanumeric none] }

# Run Taskfile targets with go-task.
export extern task [
  ...targets: string@"nu-complete go-task targets"
  --concurrency(-C): int            # Limit number of tasks to run concurrently
  --dir(-d): path                   # Directory in which to look for a Taskfile
  --dry(-n)                         # Print tasks in run order without executing them
  --exit-code(-x)                   # Pass through the exit code of the task command
  --failfast(-F)                    # Stop parallel tasks when one fails
  --force(-f)                       # Run even when the task is up to date
  --global(-g)                      # Run the global Taskfile from $HOME
  --help(-h)
  --init(-i)                        # Create a Taskfile.yml in the current folder
  --interactive                     # Prompt for missing required variables
  --json(-j)                        # Format the task list as JSON
  --list(-l)                        # List tasks with descriptions
  --list-all(-a)                    # List tasks with or without descriptions
  --output(-o): string@"nu-complete go-task output"
  --parallel(-p)                    # Run the given tasks in parallel
  --silent(-s)                      # Disable echoing
  --sort: string@"nu-complete go-task sort"
  --status                          # Exit nonzero if any given task is not up to date
  --summary                         # Show a summary about a task
  --taskfile(-t): path              # Taskfile to run
  --verbose(-v)
  --version
  --watch(-w)                       # Watch the given task
  --yes(-y)                         # Answer yes to all prompts
]

def "nu-complete sketchybar" [] {
    let items = try {
        ^sketchybar --query bar | from json | get items
    } catch {
        []
    }
    [
        ...($items | each {|item| {value: $item, description: item} })
        ...(
            [
                item
                graph
                space
                bracket
                alias
                slider
                event
            ]
            | each {|kind| {value: $kind, description: "component kind"} }
        )
        ...(
            [bar defaults events default_menu_items]
            | each {|target| {value: $target, description: "query target"} }
        )
        ...(
            [
                before
                after
                left
                right
                center
                q
                e
            ]
            | each {|position| {value: $position, description: position} }
        )
    ]
}

# Control SketchyBar; completes live item names and command keywords.
export extern sketchybar [
  ...args: string@"nu-complete sketchybar"
  --config(-c): path                # Configuration file to read
  --bar                             # Set global bar properties
  --add                             # Add an item or component
  --set                             # Change item properties
  --default                         # Change default properties for new items
  --reorder                         # Reorder items
  --move                            # Move an item before or after another
  --clone                           # Clone an item
  --rename                          # Rename an item
  --remove                          # Remove an item
  --push                            # Push data points to a graph
  --subscribe                       # Subscribe an item to events
  --trigger                         # Trigger a custom event
  --query                           # Query bar, item, default, or event state
  --animate                         # Animate property changes
  --hotload                         # Enable or disable the config hotloader
  --reload                          # Reload the current or given config
  --help(-h)
]

# Pick and apply a wallpaper.
export extern set-background [
  --update                          # Pull wallpaper repository updates first
]

def "nu-complete statix format" [] { [stderr errfmt json] }

# Lint Nix code with statix.
export extern statix [
  command?: string@[check fix single explain dump list help]
  --help(-h)
]

# Report lints and suggestions.
export extern "statix check" [
  ...paths: path
  --ignore(-i): string              # Globs of file patterns to skip
  --unrestricted(-u)                # Do not respect .gitignore files
  --format(-o): string@"nu-complete statix format"
  --config(-c): path                # statix.toml or its parent directory
  --stdin(-s)                       # Read a file on stdin, write diagnostics to stdout
  --help(-h)
]

# Fix issues raised by statix check.
export extern "statix fix" [
  ...paths: path
  --ignore(-i): string              # Globs of file patterns to skip
  --unrestricted(-u)                # Do not respect .gitignore files
  --dry-run(-d)                     # Display a diff instead of editing files
  --config(-c): path                # statix.toml or its parent directory
  --stdin(-s)                       # Read a file on stdin, write output to stdout
  --help(-h)
]

# Fix exactly one issue at a position.
export extern "statix single" [
  path?: path
  --position(-p): string            # Position to attempt a fix at
  --dry-run(-d)                     # Display a diff instead of editing the file
  --stdin(-s)                       # Read a file on stdin, write output to stdout
  --config(-c): path                # statix.toml or its parent directory
  --help(-h)
]

# Explain a lint warning code.
export extern "statix explain" [
  code: string
  --help(-h)
]

# Find dead code in Nix files.
export extern deadnix [
  ...paths: path
  --no-lambda-arg(-l)               # Do not check lambda parameter arguments
  --no-lambda-pattern-names(-L)     # Do not check lambda attrset pattern names
  --no-underscore(-_)               # Do not check bindings that start with _
  --warn-used-underscore(-W)        # Warn when bindings that start with _ are used
  --quiet(-q)                       # Do not print the dead code report
  --edit(-e)                        # Remove unused code from the source files
  --hidden(-h)                      # Recurse into hidden directories and files
  --help
  --fail(-f)                        # Exit 1 when unused code is found
  --output-format(-o): string@[human-readable json]
  --exclude: path                   # Files to exclude from analysis
  --version(-V)
]

def "nu-complete amp commands" [] {
    [
        version
        logout
        account
        login
        orb
        portal
        net
        profile
        runner
        clone
        git-setup
        files
        top
        last
        report-bug
        threads
        tools
        plugins
        skill
        permissions
        mcp
        config
        domains
        projects
        spaces
        boxes
        oauth-clients
        secrets
        svc
        usage
        update
        completions
    ]
}

# Amp coding agent CLI.
@complete external
export extern amp [
  command?: string@"nu-complete amp commands"
  ...args: string
  --visibility: string@[private unlisted workspace group]
  --version(-V)
  --notifications
  --no-notifications
  --color
  --no-color
  --settings-file: path
  --log-level: string
  --log-file: path
  --ide
  --no-ide
  --mcp-config: string              # JSON or file path for MCP servers
  --mode(-m): string                # Agent mode or provider/name model
  --effort: string                  # Reasoning effort for a new thread
  --features: string                # Comma-separated thread features
  --fast
  --executor: string
  --runner-dir: path
  --no-tui
  --share
  --desktop
  --share-network
  --amp-env
  --remote-control-terminal
  --no-remote-control-terminal
  --model: string                   # Model as provider/name
  --execute(-x)                     # Run one message non-interactively
  --attach: path
  --project
  --orb-size: string
  --orb-provider: string
  --profile: string
  --title: string
  --stream-json
  --stream-json-thinking
  --stream-json-input
  --plugin-ready-timeout
  --timings
  --no-archive-after-execute
  --label(-l): string
  --space: string
]
