# Kubernetes utilities for nushell

# knu - kubectl for nushell with structured JSON output
# Usage: knu get pods, knu get nodes, knu describe pod/mypod, etc.
export def knu [
  ...args: string  # kubectl arguments
] {
  kubectl --kuberc=off ...$args -o json | from json
}

# Get resources with JSON output
export def "knu get" [...args: string] {
  kubectl --kuberc=off get ...$args -o json | from json
}

# Describe resources with JSON output
export def "knu describe" [...args: string] {
  kubectl --kuberc=off describe ...$args -o json | from json
}

# Stream logs (doesn't need JSON)
export def "knu logs" [...args: string] {
  kubectl logs ...$args
}

# List all pods in all namespaces
export def "knu pods" [] {
  kubectl --kuberc=off get pods -A -o json | from json | get items
}

# List all nodes
export def "knu nodes" [] {
  kubectl --kuberc=off get nodes -o json | from json | get items
}

# List all namespaces
export def "knu namespaces" [] {
  kubectl --kuberc=off get namespaces -o json | from json | get items
}

# Get pod names in a namespace
export def "knu pod-names" [
  namespace?: string  # Namespace (default: current context)
] {
  if $namespace != null {
    kubectl --kuberc=off get pods -n $namespace -o json | from json | get items.metadata.name
  } else {
    kubectl --kuberc=off get pods -o json | from json | get items.metadata.name
  }
}

# Watch resources (streaming, not JSON)
export def "knu watch" [
  resource: string  # Resource type (e.g., pods, nodes)
  ...args: string   # Additional arguments
] {
  kubectl get $resource --watch ...$args
}
