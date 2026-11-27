export def review-timing [phase: string, started: datetime] {
    if $env.SYSINIT_REVIEW_TIMING? == '1' {
        {
            phase: $phase
            milliseconds: (((date now) - $started) / 1ms)
        } | to json --raw | print -e
    }
}
