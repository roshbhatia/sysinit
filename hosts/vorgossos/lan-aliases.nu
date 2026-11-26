def main [] {
    mut names = []

    mut publishers = []

    loop {
        let routes = (^kubectl get httproutes.gateway.networking.k8s.io --all-namespaces --output json | complete)

        if $routes.exit_code == 0 {
            let desired = $routes.stdout
            | from json
            | get items
            | each {|route| $route.spec.hostnames? | default [] }
            | flatten
            | where {|name| $name !~ '^\*\.' and ($name | str ends-with '.fridas.club') }
            | str replace --regex '\.fridas\.club$' '.local'
            | uniq
            | sort

            if $desired != $names {
                for publisher in $publishers {
                    try { job kill $publisher }
                }

                $publishers = ($desired | each {|name| job spawn { ^avahi-publish -a -R $name 192.168.50.240 } })

                $names = $desired
            }
        }

        sleep 60sec
    }
}
