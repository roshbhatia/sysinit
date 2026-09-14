{ pkgs }:
pkgs.runCommand "github-runner-guard" { nativeBuildInputs = [ pkgs.bash ]; } ''
  export GITHUB_REPOSITORY=roshbhatia/sysinit
  export GITHUB_REF=refs/heads/main
  for event in push schedule workflow_dispatch; do
    GITHUB_EVENT_NAME="$event" bash ${../modules/nixos/github-runner-guard.sh}
  done
  for event in pull_request pull_request_target ""; do
    if GITHUB_EVENT_NAME="$event" bash ${../modules/nixos/github-runner-guard.sh}; then
      exit 1
    fi
  done
  export GITHUB_EVENT_NAME=workflow_dispatch
  if GITHUB_REF=refs/heads/feature bash ${../modules/nixos/github-runner-guard.sh}; then
    exit 1
  fi
  if GITHUB_REPOSITORY=other/repo bash ${../modules/nixos/github-runner-guard.sh}; then
    exit 1
  fi
  touch $out
''
