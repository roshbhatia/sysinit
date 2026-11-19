use std/assert
use ./lib/process.nu [checked-command with-fixture]

def main [version: string, taskwarrior: path] {
    with-fixture {|root|
        with-env {
            HOME: ($root | path join home)
            TASKRC: ($root | path join taskrc)
            TASKDATA: ($root | path join tasks)
        } {
            mkdir $env.HOME
            touch $env.TASKRC

            assert equal (checked-command task --version | str trim) $version

            checked-command taskwarrior rc.confirmation:no add 'Command separation' | ignore

            let tasks = checked-command taskwarrior rc.json.array:on export | from json

            assert equal $tasks.0.description 'Command separation'
            assert (not ($taskwarrior | path join bin task | path exists))
            assert (not ($taskwarrior | path join share zsh site-functions _task | path exists))

            let completion = $taskwarrior | path join share zsh site-functions _taskwarrior

            assert (open --raw $completion | str contains '#compdef taskwarrior')
            checked-command zsh -n $completion | ignore

            {version: '3', tasks: {default: {cmds: ['echo taskfile-command-ok']}}}
            | to yaml
            | save ($root | path join Taskfile.yml)

            let executed = do {
                cd $root
                checked-command task
            }

            assert ($executed | str contains taskfile-command-ok)
        }
    }
}
