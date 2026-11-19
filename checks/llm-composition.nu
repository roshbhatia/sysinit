use std/assert
use lib/process.nu checked-command

def main [configuration: path, templates: path] {
    let config = checked-command yq -o=json '.' $configuration | from json

    let carriers = $config.chains.PreToolUse | where {|step| $step.args?.reader? != null}

    let readers = $carriers | get args.reader | uniq

    assert equal ($readers | length) 1

    assert equal ($carriers | get provider | sort) [bash-guard read-router]

    let template = $readers.0 | split row '-t ' | last

    let prompt = checked-command yq -o=json '.' ($templates | path join ask/templates/prompts $'($template).yaml') | from json

    assert equal $prompt.name $template

    for value in [$prompt.provider $prompt.model] {
        assert (($value | describe) == string and ($value | is-not-empty))
    }

    assert ($templates | path join ask/templates/schemas $'($prompt.schema).yaml' | path exists)

    with-env {XDG_CONFIG_HOME: $templates} {
        for rubric in [task-triage log-triage answer-review] {
            assert (checked-command ask rubric show $rubric | from json | is-not-empty)
        }
    }
}
