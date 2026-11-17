def command-output [directory: path, arguments: list<string>, input?: binary] {
    cd $directory
    let program = $arguments | first
    let arguments = $arguments | skip 1
    let result = if $input == null {
        ^timeout 30s $program ...$arguments | complete
    } else {
        $input | ^timeout 30s $program ...$arguments | complete
    }
    if $result.exit_code != 0 {
        let message = $result.stderr | into binary | decode utf-8
        error make {msg: $'($program) failed: ($message)'}
    }
    $result.stdout
}

def decode-json [text: string, context: string] {
    let value = try {
        $text | from json --strict
    } catch {
        null
    }
    if $value == null { error make {msg: $context} }
    $value
}

def quote-argument [argument: string] {
    if $argument != '' and $argument =~ '^[a-zA-Z0-9_@%+=:,./-]+$' { return $argument }
    "'" + ($argument | str replace --all "'" "'\"'\"'") + "'"
}

def note-document [directory: path, origin: string, blob: string] {
    let raw = command-output $directory [git cat-file blob $blob]
    if ($raw | describe) != string { error make {msg: $'invalid UTF-8 in Git AI note on ($origin)'} }
    let parts = $raw | split row "\n---\n"
    if ($parts | length) < 2 { error make {msg: $'invalid Git AI note on ($origin)'} }
    let metadata = decode-json ($parts | skip 1 | str join "\n---\n") $'invalid Git AI metadata on ($origin)'
    if not ($metadata | describe | str starts-with record) or ($metadata.schema_version? | default '') not-in [authorship/3.0.0 authorship/2.0.0] {
        error make {msg: $'unsupported Git AI note schema on ($origin)'}
    }
    mut paths = {}
    mut current = ''
    for record in ($parts.0 | lines) {
        if $record == '' { continue }
        if not ($record | str starts-with '  ') {
            # Git AI wraps path headers in quotes without JSON escaping.
            $current = if ($record | str starts-with '"') and ($record | str ends-with '"') {
                $record | str substring 1..-2
            } else {
                $record
            }
            $paths = $paths | upsert $current []
        } else {
            let fields = $record | str trim | split row --regex '\s+' --number 2
            if $current == '' or ($fields | length) != 2 { error make {msg: 'invalid Git AI attribution record'} }
            let entries = $paths | get $current
            $paths = $paths | upsert $current ($entries | append {key: $fields.0, spans: $fields.1})
        }
    }
    {paths: $paths, metadata: $metadata}
}

def authorship [
    directory: path
    name: string
    revision: string
    target: string
    note_ids: record
] {
    let arguments = [git -c core.quotePath=false blame --line-porcelain]
    let output = if $target == commits {
        command-output $directory ($arguments | append [$revision -- $name])
    } else {
        let input = if $target == index {
            command-output $directory [
                git
                show
                ($':' + $name)
            ] | into binary
        } else {
            open --raw ($directory | path join $name) | into binary
        }
        (command-output
            $directory
            ($arguments | append [--contents - -- $name])
            $input
        )
    } | into binary | decode utf-8
    mut documents = {}
    mut attributed = {}
    mut prompts = {}
    mut origin = ''
    mut source_line = 0
    mut destination = 0
    mut filename = $name
    for line in ($output | lines) {
        let fields = $line | str trim | split row --regex '\s+'
        if ($fields | length) in [3 4] and $fields.0 =~ '^[0-9a-f]{40}$' {
            $origin = $fields.0
            $source_line = $fields.1 | into int
            $destination = $fields.2 | into int
        } else if ($line | str starts-with 'filename ') {
            let path = $line | str substring 9..
            $filename = if ($path | str starts-with '"') { decode-json $path 'invalid quoted Git blame path' } else { $path }
        } else if ($line | str starts-with (char tab)) and $origin in $note_ids {
            if $origin not-in $documents {
                $documents = $documents | upsert $origin ((note-document
                    $directory
                    $origin
                    ($note_ids | get $origin)
                ))
            }
            let document = $documents | get $origin
            for entry in ($document.paths | get --optional $filename | default []) {
                for span in ($entry.spans | split row ',') {
                    let bounds = $span | split row '-' | each { into int }
                    if ($bounds | first) <= $source_line and $source_line <= ($bounds | last) and not ($entry.key | str starts-with h_) {
                        let record = if ($entry.key | str starts-with s_) {
                            $document.metadata.sessions? | default {} | get --optional ($entry.key | split row '::' | first)
                        } else {
                            $document.metadata.prompts? | default {} | get --optional $entry.key
                        }
                        if $record == null { error make {msg: $'missing Git AI metadata for ($entry.key)'} }
                        $attributed = $attributed | upsert ($destination | into string) $entry.key
                        $prompts = $prompts | upsert $entry.key $record
                    }
                }
            }
        }
    }
    mut ranges = []
    for entry in ($attributed | transpose number key) {
        let number = $entry.number | into int
        if ($ranges | is-not-empty) and ($ranges | last | get key) == $entry.key and ($ranges | last | get end) + 1 == $number {
            let updated = $ranges | last | update end $number
            $ranges = $ranges | update (($ranges | length) - 1) $updated
        } else { $ranges = $ranges | append {start: $number, end: $number, key: $entry.key} }
    }
    {ranges: $ranges, prompts: $prompts}
}

def notes [request: record] {
    if ($request.version? | default '') != changes.provider/v1 or ($request.action? | default '') != changes.notes {
        error make {msg: 'expected a changes.provider/v1 changes.notes request'}
    }
    let directory = $request.directory
    if ($request.validation? | default false) {
        command-output $directory [git-ai --version] | ignore
        return []
    }
    let note_ids = command-output $directory [git notes --ref=ai list] | lines | reduce --fold {} {|line, result|
        let fields = $line | split row --regex '\s+'
        $result | upsert $fields.1 $fields.0
    }
    if ($note_ids | is-empty) { return [] }
    let target = if ($request.to? | default '') != '' { 'commits' } else if ($request.staged? | default false) { 'index' } else { 'working' }
    let reference = ($request.head? | default --empty HEAD) + '^{commit}'
    let revision = command-output $directory [git rev-parse --verify --end-of-options $reference] | str trim
    mut result = []
    for name in $request.files {
        let parts = $name | split row '/'
        if $name == '' or ($parts | any {|part| $part in ['' . ..]}) { error make {msg: $'invalid repository path: ($name)'} }
        if $target == working and (($directory | path join $name | path expand | path type) != file) { continue }
        let exists = if $target == commits {
            command-output $directory [
                git
                ls-tree
                --name-only
                $revision
                --
                $name
            ]
        } else {
            let tracked = command-output $directory [git ls-files -- $name]
            if $tracked == '' {
                ''
            } else {
                command-output $directory [
                    git
                    ls-tree
                    --name-only
                    $revision
                    --
                    $name
                ]
            }
        }
        if $exists == '' { continue }
        let blame = authorship $directory $name $revision $target $note_ids
        for range in $blame.ranges {
            let agent = $blame.prompts | get $range.key | get agent_id
            let span = if $range.start == $range.end {
                $range.start | into string
            } else {
                $'($range.start)-($range.end)'
            }
            let identifier = $'($revision):($name):($span):($range.key)' | hash sha256 | str substring 0..23
            let position = {
                path: $name
                side: RIGHT
                startSide: RIGHT
                startLine: $range.start
                line: $range.end
                head: (
                    if $target == commits {
                        $revision
                    } else {
                        $request.head? | default ''
                    }
                )
                base: ($request.base? | default '')
                fingerprint: ($request.fingerprint? | default '')
                target: $target
            }
            let trace_command = [traces --all --session $agent.id] | each {|argument| quote-argument $argument} | str join ' '
            $result = $result | append {
                id: $'git-ai:($identifier)', source: git-ai, sourceId: $identifier
                summary: $'($agent.tool) / ($agent.model)', rationale: $'Open the originating session: ($trace_command)'
                author: $agent.tool, origin: external, authority: advisory, state: open, session: $agent.id
                provenance: {kind: git-ai, tool: $agent.tool, sessionId: $agent.id, workingDirectory: $directory}
                anchor: $position, placement: ($position | upsert quality exact)
            }
        }
    }
    $result
}

def main [] {
    let input = $in
    let request = decode-json $input 'expected a JSON changes provider request'
    try {
        {
            version: changes.provider/v1
            notes: (notes $request)
        } | to json --raw | print
    } catch {|failure|
        print --stderr $'changes-provider-git-ai: ($failure.msg)'
        exit 1
    }
}
