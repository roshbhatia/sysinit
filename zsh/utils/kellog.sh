#!/usr/bin/env bash

function kellog() {
  function show_help() {
    echo "Usage: kellog [-h|--help] [-i|--include-container CONTAINER] [-e|--exclude-container CONTAINER] [-I|--include-log LOG_PATTERN] [-E|--exclude-log LOG_PATTERN] [-n|--namespace NAMESPACE] [-m|--minimal] [POD_QUERY]"
    echo "Tail logs from a Kubernetes pod using stern."
    echo "  -h, --help                Show this help message."
    echo "  -i, --include-container   Specify the container name regex to include."
    echo "  -e, --exclude-container   Specify the container name regex to exclude."
    echo "  -I, --include-log         Specify the log pattern regex to include."
    echo "  -E, --exclude-log         Specify the log pattern regex to exclude."
    echo "  -n, --namespace           Specify the namespace."
    echo "  -m, --minimal             Print pod name and message only"
    echo "  POD_QUERY                 Specify the pod query regex (default: '.*')."
  }

  local namespace="default"
  local include_container=""
  local exclude_container=""
  local include_log=""
  local exclude_log=""
  local pod_query=".*"
  local minimal=false
  local args=()

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -h|--help)
        show_help
        return 0
        ;;
      -i|--include-container)
        include_container="--container \"$2\""
        shift 2
        ;;
      -e|--exclude-container)
        exclude_container="--exclude-container \"$2\""
        shift 2
        ;;
      -I|--include-log)
        include_log="--include \"$2\""
        shift 2
        ;;
      -E|--exclude-log)
        exclude_log="--exclude \"$2\""
        shift 2
        ;;
      -n|--namespace)
        namespace="$2"
        shift 2
        ;;
      -m|--minimal)
        minimal=true
        shift
        ;;
      *)
        pod_query="$1"
        shift
        ;;
    esac
  done

  if $minimal; then
    args+=("--template=| {{color .PodColor .PodName}} | {{.Message}} {{\"\n\"}}")
  fi

  stern -n "${namespace}" "${include_container}" "${exclude_container}" "${include_log}" "${exclude_log}" "${args[@]}" "${pod_query}"
}
