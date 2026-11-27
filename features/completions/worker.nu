export extern worker [
    --wait(-w): int # Wait for exit; zero waits without a timeout
    --wait-blocked(-b): int # Wait for exit or an input request
    --tail(-t): int # Log lines after a wait
    --name(-n): string # Run name
    --status # Show the workspace worker
    --close # Close the worker pane
    --release: string # Release a run name
    --force # Release a name even if its pane may still report
    --help(-h) # Show usage
    ...command: string
]
