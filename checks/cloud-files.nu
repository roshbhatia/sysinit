use std/assert

def main [
    committed: path
    rendered: path
    script: path
    environment: path
    installer_host: string
] {
    assert equal (open --raw $committed) (open --raw $rendered) 'Cloud setup drifted; run hack/generate-cloud.sh'

    let contacted = open --raw $script
    | split row 'https://'
    | skip 1
    | each {|value| $value | parse --regex '^(?<host>[A-Za-z0-9.-]+)' }
    | flatten
    | get host
    | uniq

    let allowed = open $environment | get egressAllowlist

    let missing = $contacted | where {|host| $host not-in $allowed }

    assert ($missing | is-empty) $'Cloud setup contacts hosts missing from its allowlist: ($missing)'

    assert ($installer_host in $contacted) 'URL extraction omitted the installer host'
}
