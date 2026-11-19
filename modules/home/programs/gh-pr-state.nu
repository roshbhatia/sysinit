const fields = 'url,state,isDraft,headRefOid,reviewDecision,mergeStateStatus,statusCheckRollup'

const threads_query = 'query($owner: String!, $repo: String!, $number: Int!, $endCursor: String) {
    repository(owner: $owner, name: $repo) {
        pullRequest(number: $number) {
            reviewThreads(first: 100, after: $endCursor) {
                nodes { isResolved }
                pageInfo { hasNextPage endCursor }
            }
        }
    }
}'

def --wrapped github [deadline: datetime, ...arguments: string] {
    let remaining = ([
        20sec
        ($deadline - (date now))
    ] | math min)

    if $remaining <= 0sec { error make {msg: 'GitHub observation deadline elapsed'} }

    let seconds = ($remaining / 1sec) | into string

    let result = ^timeout --signal=KILL $seconds gh ...$arguments | complete

    if $result.exit_code != 0 {
        let message = $result.stderr | str trim

        error make {
            msg: (
                if $message == '' { $'GitHub observation failed with exit ($result.exit_code)' } else { $message }
            )
        }
    }

    $result.stdout
}

def parse-url [url: string] {
    $url
    | parse --regex '^https://github\.com/(?<owner>[a-zA-Z0-9_.-]+)/(?<repo>[a-zA-Z0-9_.-]+)/pull/(?<number>[1-9][0-9]*)$'
    | first
}

def inspect [url: string, deadline: datetime] {
    let target = parse-url $url

    if $target == null { error make {msg: 'Expected a canonical GitHub pull request URL'} }

    let pr = github $deadline pr view $url --json $fields | from json

    let unresolved = if $pr.state == OPEN {
        (github
            $deadline
            api
            graphql
            --paginate
            --slurp
            -f
            $'query=($threads_query)'
            -f
            $'owner=($target.owner)'
            -f
            $'repo=($target.repo)'
            -F
            $'number=($target.number)'
        )
        | from json
        | each {|page| $page.data.repository.pullRequest.reviewThreads.nodes | where isResolved == false | length}
        | math sum
    } else {
        0
    }

    {
        url: $pr.url
        head: $pr.headRefOid
        state: $pr.state
        draft: $pr.isDraft
        review: $pr.reviewDecision
        merge_state: $pr.mergeStateStatus
        unresolved_threads: $unresolved
        checks: ($pr.statusCheckRollup | each {|check|
            {
                name: ($check.name? | default $check.context? | default '')
                state: ($check.conclusion? | default '' | if $in == '' {
                    $check.status? | default $check.state?
                } else {
                    $in
                })
            }
        } | sort-by name state)
        ready: (
            $pr.state == OPEN and not $pr.isDraft and $pr.reviewDecision == APPROVED and $pr.mergeStateStatus == CLEAN and $unresolved == 0
        )
    }
}

def snapshot [urls: list<string>, deadline?: datetime] {
    $urls | uniq | each {|url|
        try {
            inspect $url ($deadline | default ((date now) + 40sec))
        } catch {|failure|
            {url: $url, error: $failure.msg}
        }
    }
}

def main [...urls: string] {
    if ($urls | is-empty) { error make {msg: 'Pass one or more canonical GitHub PR URLs'} }

    snapshot $urls | to json --raw | print
}

def 'main watch' [--interval: duration = 1min, --timeout: duration = 30min, ...urls: string] {
    if ($urls | is-empty) or $interval <= 0sec or $timeout <= 0sec {
        error make {msg: 'Pass PR URLs and positive interval and timeout values'}
    }

    if ($urls | any {|url| (parse-url $url) == null}) {
        error make {msg: 'Expected canonical GitHub pull request URLs'}
    }

    let deadline = (date now) + $timeout

    mut previous = []

    loop {
        if (date now) >= $deadline { exit 8 }

        let current = snapshot $urls $deadline

        for row in $current {
            if $row not-in $previous {
                $row | to json --raw | print
            }
        }

        let remaining = $deadline - (date now)

        if $remaining <= 0sec { exit 8 }

        if ($current | all {|row| $row.ready? == true or $row.state? in [MERGED CLOSED]}) {
            return
        }

        $previous = $current

        sleep ([$remaining $interval] | math min)
    }
}
