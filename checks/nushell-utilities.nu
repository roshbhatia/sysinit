# Exercises the nushell ports of the former Go utilities against fixtures. The
# runner imports each script first, because `use` needs a parse-time path.
do {
    let raw = {
        apiVersion: v1
        kind: Config
        clusters: [
            {
                name: default
                cluster: {
                    server: "https://127.0.0.1:6443"
                    certificate-authority-data: cert
                }
            }
        ]
        users: [
            {
                name: admin
                user: {token: test}
            }
        ]
    }
    let result = (
        configure $raw new-host {endpoint: "https://different-host:7443" namespace: private}
    )
    if $result.current-context != new-host or $result.clusters.0.cluster.server != "https://different-host:7443" or $result.clusters.0.cluster.tls-server-name != "127.0.0.1" or $result.clusters.0.cluster.certificate-authority-data != cert {
        error make {msg: "ere-setup configure did not preserve the connection"}
    }
    if $result.contexts.0.context != {cluster: new-host, user: admin, namespace: private} {
        error make {msg: "ere-setup configure wrote the wrong context"}
    }
    if (try {
        configure $raw new-host {endpoint: "http://insecure" namespace: x}
        true
    } catch {
        false
    }) {
        error make {msg: "ere-setup configure accepted an insecure endpoint"}
    }
    if (try {
        configure {clusters: [] users: []} new-host {endpoint: "https://x" namespace: x}
        true
    } catch {
        false
    }) {
        error make {msg: "ere-setup configure accepted a missing cluster"}
    }
    print "nushell utilities passed"
}

# task-context backup and restore against a real Taskwarrior in a scratch home.
do {
    let root = (mktemp -d)
    let rc = $root | path join "taskrc"
    "confirmation=off\nnews.version=3.5.0\nuda.repo.type=string\n" | save $rc
    with-env {TASKRC: $rc TASKDATA: ($root | path join "data")} {
        ^$env.TASK_BINARY rc.verbose:nothing add First repo:/some/repo | ignore
        let uuid = (^$env.TASK_BINARY rc.verbose:nothing rc.json.array:on export | from json | get 0.uuid)
        ^$env.TASK_BINARY rc.verbose:nothing $uuid annotate "Keep annotation" | ignore
        ^$env.TASK_BINARY rc.verbose:nothing add Second $"depends:($uuid)" | ignore
        let snapshots = $root | path join "snapshots"
        let first = (backup $env.TASK_BINARY $snapshots 1)
        let second = (backup $env.TASK_BINARY $snapshots 1)
        if ($first | path exists) { error make {msg: "task-context retention kept the oldest snapshot"} }
        if (ls -l $second | get 0.mode) != "rw-------" { error make {msg: "task-context snapshot is not private"} }
        let recovered = $root | path join "restored"
        restore $env.TASK_BINARY $second $recovered | ignore
        if (try { restore $env.TASK_BINARY $second $recovered; true } catch { false }) {
            error make {msg: "task-context restore overwrote an existing directory"}
        }
        let restored = (with-env {TASKRC: ($recovered | path join "taskrc") TASKDATA: ($recovered | path join "data")} {
            ^$env.TASK_BINARY rc.verbose:nothing rc.json.array:on export | from json
        })
        if ($restored | length) != 2 { error make {msg: "task-context restore lost tasks"} }
        let kept = $restored | where uuid == $uuid | first
        if $kept.repo != "/some/repo" or ($kept.annotations? | is-empty) { error make {msg: "task-context restore lost metadata"} }
        if ($restored | where description == Second | first | get -o depends | is-empty) { error make {msg: "task-context restore lost a dependency"} }
    }
    rm -rf $root
    print "task-context passed"
}

# cache-maintain policy decisions, symlink handling, and uv lock handling.
do {
    let dir = (mktemp -d)
    let empty_bytes = (allocated-bytes $dir)
    let file = $dir | path join "cached"
    0..8191 | each { "x" } | str join | save $file
    let policy = {
        name: fixture
        directory: $dir
        max_bytes: ($empty_bytes + 1)
        command: ["/unused"]
    }
    let dry = maintain $policy false {|p| error make {msg: "dry run ran cleanup"} }
    if $dry.status != "would-prune" { error make {msg: $"cache-maintain dry run: ($dry)"} }
    let small = (
        maintain ($policy | update max_bytes 1048576) true {|p| error make {msg: "small cache cleaned"} }
    )
    if $small.status != "within-limit" { error make {msg: $"cache-maintain small cache: ($small)"} }
    let pruned = maintain $policy true {|p| rm $file }
    if $pruned.status != "pruned" or ($file | path exists) { error make {msg: $"cache-maintain large cache: ($pruned)"} }

    let outside = (mktemp -d)
    0..8191 | each { "x" } | str join | save ($outside | path join "data")
    let linked = (mktemp -d)
    ^ln -s $outside ($linked | path join "external")
    if (allocated-bytes $linked) >= 8192 { error make {msg: "cache-maintain followed a nested symlink"} }
    if (try {
        allocated-bytes ($linked | path join "external")
        true
    } catch {
        false
    }) {
        error make {msg: "cache-maintain accepted a symlink root"}
    }

    let busy_dir = (mktemp -d)
    0..8191 | each { "x" } | str join | save ($busy_dir | path join "cached")
    let busy = (
        maintain {name: uv directory: $busy_dir max_bytes: 1 command: ["/unused"]} true {|p| error make {msg: "Timeout (1s) when waiting for lock"} }
    )
    if $busy.status != "busy" or $busy.after_bytes != $busy.before_bytes { error make {msg: $"cache-maintain uv lock: ($busy)"} }
    rm -rf $dir $outside $linked $busy_dir
    print "cache-maintain passed"
}
