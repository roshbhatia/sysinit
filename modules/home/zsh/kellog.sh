#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all

# 888             888888                 
# 888             888888                 
# 888             888888                 
# 888  888 .d88b. 888888 .d88b.  .d88b.  
# 888 .88Pd8P  Y8b888888d88""88bd88P"88b 
# 888888K 88888888888888888  888888  888 
# 888 "88bY8b.    888888Y88..88PY88b 888 
# 888  888 "Y8888 888888 "Y88P"  "Y88888 
#                                   888 
#                              Y8b d88P 
#                               "Y88P"

# kellog - Tail k8s logs using stern
function kellog() {
  function show_help() {
    echo "888             888888                 "
    echo "888             888888                 "
    echo "888             888888                 "
    echo "888  888 .d88b. 888888 .d88b.  .d88b.  "
    echo "888 .88Pd8P  Y8b888888d88\"\"88bd88P\"88b "
    echo "888888K 88888888888888888  888888  888 "
    echo "888 \"88bY8b.    888888Y88..88PY88b 888 "
    echo "888  888 \"Y8888 888888 \"Y88P\"  \"Y88888 "
    echo "                                   888 "
    echo "                              Y8b d88P "
    echo "                               \"Y88P\"  "
    echo
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