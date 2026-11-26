use std/assert

def main [helper: path] {
    let root = mktemp -d | path expand --strict

    try {
        let directory = $root | path join plugins cache openai-codex codex fixture hooks

        mkdir $directory

        let path = $directory | path join hooks.json

        let document = {
            metadata: preserved
            hooks: {
                SessionEnd: [
                    {
                        hooks: [
                            {timeout: 30}
                            {timeout: 4.5}
                            {timeout: 2}
                            {timeout: '30'}
                            {command: unchanged}
                        ]
                    }
                    {other: preserved}
                ]
                Stop: [
                    {
                        hooks: [
                            {timeout: 30}
                        ]
                    }
                ]
            }
        }

        $document | to json | save $path

        ^chmod 640 $path

        let shell = $nu.current-exe

        ^$shell --no-config-file $helper $root

        let result = open $path

        assert equal (
            $result.hooks.SessionEnd
            | first
            | get hooks
            | first 4
            | get timeout
        ) [3 3 2 '30']

        assert equal ($result.hooks.SessionEnd | last) {other: preserved}

        assert equal $result.hooks.Stop $document.hooks.Stop

        assert equal $result.metadata preserved

        assert equal (ls --long $path | first | get mode) 'rw-r-----'

        let backup = $directory | path join hooks.json.before-sysinit-timeout

        assert equal (open --raw $backup | from json) $document

        let modified = ls --long $path | first | get modified

        ^$shell --no-config-file $helper $root

        assert equal (ls --long $path | first | get modified) $modified

        assert equal (open --raw $backup | from json) $document

        '{' | save --force $path

        let failed = ^$shell --no-config-file $helper $root | complete

        assert ($failed.exit_code != 0)

        assert equal (open --raw $path) '{'
    } catch {|failure|
        rm -rf $root

        error make $failure
    }

    rm -rf $root

    print 'Codex plugin hook checks passed'
}
