#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all

# 888      .d888         .d888 
# 888     d88P"         d88P"  
# 888     888           888    
# 888  88888888888888888888888 
# 888 .88P888      d88P 888    
# 888888K 888     d88P  888    
# 888 "88b888    d88P   888    
# 888  888888   88888888888

# kfzf - Fuzzy find and describe k8s resources
function kfzf() {
  # Show help if requested
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "888      .d888         .d888 "
    echo "888     d88P\"         d88P\"  "
    echo "888     888           888    "
    echo "888  88888888888888888888888 "
    echo "888 .88P888      d88P 888    "
    echo "888888K 888     d88P  888    "
    echo "888 \"88b888    d88P   888    "
    echo "888  888888   88888888888    "
    echo
    echo "Usage: kfzf [RESOURCE] [NAMESPACE] [OUTPUT_FORMAT]"
    echo
    echo "Fuzzy find and describe Kubernetes resources."
    echo
    echo "Arguments:"
    echo "  RESOURCE        Resources to search (default: pods,deployments,replicasets,statefulsets)"
    echo "  NAMESPACE       Namespace to search in (default: default)"
    echo "  OUTPUT_FORMAT   Format to display (-oyaml, -ojson, or describe [default])"
    echo
    echo "Examples:"
    echo "  kfzf pods default"
    echo "  kfzf deployments kube-system -oyaml"
    return 0
  fi
  local resource="$1"
  local namespace="${2:-default}"
  local output_format="${3:-describe}"

  if [[ -z "$resource" ]]; then
    resource="pods,deployments,replicasets,statefulsets"
  fi

  local preview_command="kubectl describe {2} {3} -n {1}"
  if [[ "$output_format" == "-oyaml" ]]; then
    preview_command="kubectl get {2} {3} -n {1} -o yaml"
  elif [[ "$output_format" == "-ojson" ]]; then
    preview_command="kubectl get {2} {3} -n {1} -o json"
  fi

  local resources
  resources=$(kubectl get "$resource" --all-namespaces -o custom-columns="Namespace:.metadata.namespace,Kind:.kind,Name:.metadata.name")
  
  echo "$resources" | fzf --ansi --height=100% --preview "$preview_command | bat --color=always" --preview-window=right:50% --preview-window=wrap
}