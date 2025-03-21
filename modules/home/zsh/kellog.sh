#!/usr/bin/env zsh
# shellcheck disable=all

# kellog - Tail k8s logs using stern
function kellog() {
  function show_help() {
    echo "Usage: kellog [-h|--help] [-n|--namespace NAMESPACE] [-m|--minimal]"
    echo "Tail logs from a Kubernetes pod using stern."
    echo "  -h, --help                Show this help message."
  }

  function list_deployments() {
    local deployments
    deployments=$(kubectl get deployments --all-namespaces -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace --no-headers | sort)
    selected_deployment=$(echo "$deployments" | while read -r deployment; do
        name=$(echo "$deployment" | awk '{print $1}')
        namespace=$(echo "$deployment" | awk '{print $2}')
        echo -e "$name ($namespace)"
    done | fzf --ansi --height=20)

    if [[ -n "$selected_deployment" ]]; then
        deployment_name=$(echo "$selected_deployment" | awk '{print $1}')
        namespace=$(echo "$selected_deployment" | awk -F '[()]' '{print $2}')
        stern -n "$namespace" "$deployment_name" "${args[@]}"
    fi
  }

  local namespace="default"
  local minimal=false
  local args=()

  if [[ "$#" -eq 0 ]]; then
    list_deployments
    return 0
  fi

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -h|--help)
        show_help
        return 0
        ;;
      *)
        show_help
        return 1
        ;;
    esac
  done
}