def decode-status [] {
  let entries = ($in | split row (char nul))
  mut rows = []
  mut offset = 0
  while $offset < ($entries | length) {
    let entry = $entries | get $offset
    $offset += 1
    if $entry == '' or ($entry | str starts-with '#') { continue }
    let status = $entry | str substring 0..<2
    let original = if ($status | str contains 'R') or ($status | str contains 'C') {
      let source = $entries | get $offset
      $offset += 1
      $source
    } else { null }
    $rows = $rows | append {
      status: $status
      file: ($entry | str substring 3..)
      original_file: $original
    }
  }
  $rows
}

def decode-log [] {
  let output = $in
  if $output == '' { return [] }
  $output
  | split row (char nul)
  | drop 1
  | chunks 5
  | each {|fields|
    {
      hash: ($fields | get 0)
      short_hash: ($fields | get 1)
      author: ($fields | get 2)
      date: ($fields | get 3 | into datetime)
      subject: ($fields | get 4)
    }
  }
}

# Show working-tree changes; piping returns status, file, and original_file.
@complete external
@structured [--porcelain=v1 -z] { decode-status }
export extern "git status" [
  ...pathspecs: path
  --short(-s)                    # Show concise text output
  --branch(-b)                   # Include branch information
  --show-stash                   # Include stash information
  --verbose(-v)                  # Show staged changes
]

# List commits; piping returns commit identity, author, date, and subject.
@complete external
@structured [-z "--format=%H%x00%h%x00%an%x00%aI%x00%s"] { decode-log }
export extern "git log" [
  ...revisions_and_paths: string
  --max-count(-n): int           # Limit the number of commits
  --all                         # Include all refs
  --author: string              # Match an author
  --grep: string                # Match commit messages
  --since: string               # Show commits after this date
  --until: string               # Show commits before this date
  --first-parent                # Follow only first parents
  --no-merges                   # Exclude merge commits
  --reverse                     # Reverse commit order
  --follow                      # Follow file history beyond renames
  --oneline                     # Use ^git for alternate text formats in pipelines
  --format: string              # Use ^git for alternate formats in pipelines
  --stat                        # Include diff statistics
  --patch(-p)                   # Include patches
]

# Stage matching paths, with native path completion and variadic arguments.
@complete external
export extern "git add" [
  ...pathspecs: path
  --all(-A)                     # Stage all changes
  --update(-u)                  # Stage tracked-file changes
  --patch(-p)                   # Select changes interactively
  --interactive(-i)             # Select files interactively
  --dry-run(-n)                 # Show changes without staging
  --force(-f)                   # Include ignored files
  --intent-to-add(-N)           # Record paths without staging contents
  --verbose(-v)                 # Show staged paths
]
