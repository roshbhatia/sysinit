use std/assert

def main [guard: path] {
    with-env {GITHUB_REPOSITORY: roshbhatia/sysinit, GITHUB_REF: refs/heads/main} {
        for event in [push schedule workflow_dispatch] {
            let allowed = with-env {GITHUB_EVENT_NAME: $event} {
                ^bash $guard | complete
            }

            assert equal $allowed.exit_code 0 $allowed.stderr
        }

        for event in [pull_request pull_request_target ''] {
            let blocked = with-env {GITHUB_EVENT_NAME: $event} {
                ^bash $guard | complete
            }

            assert ($blocked.exit_code != 0) $'Runner accepted event ($event)'
        }

        for invalid in [
            {GITHUB_REF: refs/heads/feature}
            {GITHUB_REPOSITORY: other/repo}
        ] {
            let blocked = with-env ({GITHUB_EVENT_NAME: workflow_dispatch} | merge $invalid) {
                ^bash $guard | complete
            }

            assert ($blocked.exit_code != 0) 'Runner accepted an untrusted source'
        }
    }
}
