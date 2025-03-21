#!/usr/bin/env zsh
# shellcheck disable=all

# kfzf - Fuzzy find and describe k8s resources
function kfzf() {
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