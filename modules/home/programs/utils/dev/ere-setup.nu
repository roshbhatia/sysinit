#!/usr/bin/env nu

def fail [message: string] {
    print -e $"ere-setup: ($message)"
    exit 1
}

# Point a one-cluster kubeconfig at the connection's endpoint while keeping TLS
# verification against the server name the credentials were issued for.
export def configure [kubeconfig: record, name: string, connection: record] {
    if ($kubeconfig.clusters | length) != 1 or ($kubeconfig.users | length) != 1 {
        error make {msg: "expected one cluster and one user"}
    }
    let server = $kubeconfig.clusters.0.cluster.server? | default ""
    let server_host = (
        try {
            $server | url parse | get host
        } catch {
            ""
        }
    )
    if ($server_host | is-empty) {
        error make {msg: "invalid cluster server"}
    }
    let endpoint = (
        try {
            $connection.endpoint | url parse
        } catch {
            {scheme: "", host: ""}
        }
    )
    if $endpoint.scheme != "https" or ($endpoint.host | is-empty) {
        error make {msg: "endpoint must be an HTTPS URL"}
    }
    let cluster = (
        $kubeconfig.clusters.0.cluster
        | upsert tls-server-name $server_host
        | upsert server $connection.endpoint
    )
    $kubeconfig
    | upsert clusters [
        {name: $name, cluster: $cluster}
    ]
    | upsert contexts [
        {
            name: $name
            context: {
                cluster: $name
                user: $kubeconfig.users.0.name
                namespace: $connection.namespace
            }
        }
    ]
    | upsert current-context $name
}

def remote-command [argv: list<string>] {
    $argv | each {|arg| "'" + ($arg | str replace --all "'" "'\"'\"'") + "'" } | str join " "
}

# Fetch a connection's kubeconfig over SSH, verify it reaches the namespace, and install it.
def main [connection: string, --config: path] {
    if ($connection | path basename) != $connection or $connection in ["." ".."] {
        fail "invalid connection name"
    }
    let connections = (
        try {
            open --raw $config | from json
        } catch {|error|
            fail $error.msg
        }
    )
    let target = $connections | get -o $connection
    if $target == null {
        fail $"unknown connection \"($connection)\""
    }
    let ssh_host = $target.sshHost? | default ""
    let credential_command = $target.credentialCommand? | default []
    if ($ssh_host | is-empty) or ($ssh_host | str starts-with "-") or ($credential_command | is-empty) {
        fail "invalid SSH connection"
    }
    let directory = $env.HOME | path join ".kube"
    mkdir $directory
    chmod 700 $directory
    let staged = (mktemp --tmpdir-path $directory .ere-XXXXXX)
    try {
        let credentials = (
            ^ssh -o BatchMode=yes -o ConnectTimeout=10 $ssh_host (remote-command $credential_command)
            | complete
        )
        if $credentials.exit_code != 0 {
            error make {
                msg: $"ssh exited ($credentials.exit_code): ($credentials.stderr | str trim)"
            }
        }
        $credentials.stdout | save --force $staged
        let normalized = (
            ^kubectl --kubeconfig $staged config view --raw --minify -o json
            | from json
        )
        configure $normalized $connection $target | to json | save --force $staged
        ^kubectl --request-timeout=15s --kubeconfig $staged get namespace $target.namespace
        let destination = $directory | path join $"ere-($connection).yaml"
        mv --force $staged $destination
        let key = $env.HOME | path join ".ssh" "ere"
        mkdir ($key | path dirname)
        if not ($key | path exists) {
            ^ssh-keygen -q -t ed25519 -N "" -f $key
        }
        print $"Prepared ($destination)"
    } catch {|error|
        rm --force $staged
        fail $error.msg
    }
}
