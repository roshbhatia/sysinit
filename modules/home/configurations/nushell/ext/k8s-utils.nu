# Kubernetes utilities for nushell

# knu - kubectl for nushell with structured JSON output
# Usage: knu get pods, knu get nodes, knu describe pod/mypod, etc.
export def knu [
  ...args: string  # kubectl arguments
] {
  kubecolor --kuberc=off ...$args -o json | from json
}

# Get resources with JSON output
export def "knu get" [...args: string] { 
  knu get ...$args 
}

# Describe resources with JSON output
export def "knu describe" [...args: string] { 
  knu describe ...$args 
}

# Stream logs (doesn't need JSON)
export def "knu logs" [...args: string] { 
  kubecolor logs ...$args 
}

# List all pods in all namespaces
export def "knu pods" [] {
  knu get pods -A | get items
}

# List all nodes
export def "knu nodes" [] {
  knu get nodes | get items
}

# List all namespaces
export def "knu namespaces" [] {
  knu get namespaces | get items
}

# Get pod names in a namespace
export def "knu pod-names" [
  namespace?: string  # Namespace (default: current context)
] {
  if $namespace != null {
    knu get pods -n $namespace | get items.metadata.name
  } else {
    knu get pods | get items.metadata.name
  }
}

# Watch resources (streaming, not JSON)
export def "knu watch" [
  resource: string  # Resource type (e.g., pods, nodes)
  ...args: string   # Additional arguments
] {
  kubecolor get $resource --watch ...$args
}
