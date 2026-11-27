use std/assert

def invoke [command: string, arguments: list<string>] {
    ^timeout 4s $command ...$arguments | complete
}

def main [root: path, fixture: path] {
    let scratch = mktemp --directory | path expand --strict

    try {
        for name in [
            wezterm
            sudo
            ask
            fd
            fzf
            osascript
            gh
            chafa
        ] {
            let path = $scratch | path join $name

            (
                $'#!($nu.current-exe) --no-config-file' + "\n" + $'$env.UTILITY_TEST_COMMAND = "($name)"' + "\n" + (open --raw $fixture)
            ) | save $path

            ^chmod 700 $path
        }

        let calls = $scratch | path join calls

        with-env {PATH: ($env.PATH | prepend $scratch), WEZTERM_PANE: fixture, ASK_CAPTURE: '1', CALLS: $calls} {
            with-env {UTILITY_TEST_CONNECT_FAIL: '1'} {
                let connected = invoke $nu.current-exe [--no-config-file ($root | path join modules home programs utils dev connect.nu) fixture]
                assert equal $connected.exit_code 23
                assert ($connected.stderr | str contains 'fixture failure')
            }
            let dns = $root | path join modules home programs utils network dns-flush.nu
            for case in [
                {platform: macos, expected: ['dscacheutil -flushcache' 'killall -HUP mDNSResponder']}
                {platform: linux, expected: ['resolvectl flush-caches']}
            ] {
                '' | save --force $calls
                let result = invoke $nu.current-exe [--no-config-file -c $'use ($dns | to json --raw) flush; flush ($case.platform)']
                assert equal $result.exit_code 0 $result.stderr
                assert equal (open --raw $calls | lines) $case.expected
            }
            with-env {FAIL: '7'} {
                '' | save --force $calls
                let result = invoke $nu.current-exe [--no-config-file -c $'use ($dns | to json --raw) flush; flush macos']
                assert equal $result.exit_code 7
                assert equal (open --raw $calls | lines | length) 1
            }
            let source = $scratch | path join seshy.zsh
            open --raw ($root | path join features shell zsh integrations seshy-wezterm.zsh)
                | str replace --all '@seshySessions@' "'/tmp/custom sessions'" | save $source
            let forwarded = invoke zsh [-f -c 'source "$1"; weznot() { :; }; capture() { printf "<%s>\n" "$@"; return 19; }; wezmon capture "one two" "" "literal; echo BAD"' fixture $source]
            assert equal $forwarded.exit_code 19 $forwarded.stderr
            assert equal $forwarded.stdout "<one two>\n<>\n<literal; echo BAD>\n"
            let plain = invoke zsh [-f -c 'source "$1"; wezmon printf "%s" data' fixture $source]
            assert equal $plain.exit_code 0 $plain.stderr
            assert equal $plain.stdout data
            let session = invoke zsh [-f -c 'source "$1"; _seshy_session_name "/tmp/custom sessions/project/repo"' fixture $source]
            assert equal $session.stdout "project\n"
            let hook = $scratch | path join hook.zsh
            open --raw ($root | path join features shell zsh integrations ask.zsh)
                | str replace --all '@timeout@' timeout | save $hook
            let bounded = invoke zsh [-f -c 'source "$1"; _ask_capture; printf ready' fixture $hook]
            assert equal $bounded.exit_code 0 $bounded.stderr
            assert equal $bounded.stdout ready
            let home = $scratch | path join home
            let wallpapers = $home | path join .local share wallpapers
            mkdir $wallpapers
            let selected = $wallpapers | path join 'name "quoted" and trailing '
            let wallpaper = $root | path join modules home programs utils system set-background.nu
            with-env {HOME: $home, SELECTED: $selected, PICKER_EXIT: '0', APPLY_EXIT: '0'} {
                if $nu.os-info.name == macos {
                    let applied = invoke $nu.current-exe [--no-config-file $wallpaper]
                    assert equal $applied.exit_code 0 $applied.stderr
                    assert equal (open --raw $calls) $selected
                    with-env {APPLY_EXIT: '9'} {
                        let failed = invoke $nu.current-exe [--no-config-file $wallpaper]
                        assert equal $failed.exit_code 9
                    }
                }
                'untouched' | save --force $calls
                with-env {PICKER_EXIT: '130'} {
                    let canceled = invoke $nu.current-exe [--no-config-file $wallpaper]
                    assert equal $canceled.exit_code 0 $canceled.stderr
                    assert equal (open --raw $calls) untouched
                }
                with-env {PICKER_EXIT: '2'} {
                    let failed = invoke $nu.current-exe [--no-config-file $wallpaper]
                    assert equal $failed.exit_code 2
                }
            }
            let sample = $scratch | path join sample.txt
            'fixture' | save $sample
            let preview = $root | path join modules home programs utils dev fzf-preview.nu
            for case in [{extension: tar, flag: -cf} {extension: tgz, flag: -czf} {extension: bz2, flag: -cjf}] {
                let archive = $scratch | path join ($'fixture.($case.extension)')
                let created = invoke tar [$case.flag $archive -C $scratch sample.txt]
                assert equal $created.exit_code 0 $created.stderr
                let viewed = invoke $nu.current-exe [--no-config-file $preview $archive --kind archive]
                assert equal $viewed.exit_code 0 $viewed.stderr
                assert ($viewed.stdout | str contains sample.txt)
            }
            let archive = $scratch | path join fixture.7z
            let created = invoke 7zz [a $archive $sample]
            assert equal $created.exit_code 0 $created.stderr
            let viewed = invoke $nu.current-exe [--no-config-file $preview $archive --kind archive]
            assert equal $viewed.exit_code 0 $viewed.stderr
            assert ($viewed.stdout | str contains sample.txt)
        }
    } catch {|failure|
        rm --recursive --force $scratch

        error make $failure
    }

    rm --recursive --force $scratch

    print 'Utility runtime contracts passed'
}
