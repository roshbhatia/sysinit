def --wrapped main [...args: string] {
    let file = $env.DEFAULTS_TEST_STATE
    let events = $env.DEFAULTS_TEST_EVENTS
    if $args.0 == '-q' {
        {operation: restart} | to json --raw | $in + (char newline) | save --append $events
        return
    }
    let operation = $args.0
    let domain = $args.1
    if $operation == export {
        {operation: export, domain: $domain} | to json --raw | $in + (char newline) | save --append $events
        match ($env.DEFAULTS_TEST_READ_MODE? | default '') {
            denied => {
                print --stderr 'permission denied'
                exit 1
            }
            invalid => {
                print --raw '<invalid plist>'
                return
            }
        }
        let state = open --raw $file | from json
        if $domain not-in ($state | columns) {
            print --stderr 'Domain does not exist'
            exit 1
        }
        $state | get $domain | to plist | print --raw $in
        return
    }
    if ($env.DEFAULTS_TEST_WRITE_FAIL? | default false | into bool) {
        print --stderr 'write denied'
        exit 1
    }
    let key = $args.2
    let state = open --raw $file | from json
    let current = $state | get -o $domain | default {}
    let updated = match $operation {
        write => {
            $current | upsert $key ($args.3 | from plist)
        }
        delete => {
            $current | reject $key
        }
        _ => { error make {msg: $"Unexpected defaults operation ($operation)"} }
    }
    $state | upsert $domain $updated | to json | save --force $file
    {operation: $operation, domain: $domain, key: $key} | to json --raw | $in + (char newline) | save --append $events
}
