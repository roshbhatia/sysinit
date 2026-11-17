def --wrapped main [...args: string] {
    if $args.0 == '-x' { exit ($env.APP_COPY_TEST_PGREP_EXIT? | default '1' | into int) }
    let app = $args | last
    if '--verify' in $args {
        if (open --raw ($app | path join payload)) != signed { exit 1 }
        return
    }
    print 'designated => certificate leaf = test'
}
