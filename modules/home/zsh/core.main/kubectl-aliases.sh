#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all

compdef _kubectl kubecolor
compdef _kubectl k

# Basic kubectl commands (as kubecolor)
alias k='kubecolor'                                               # Basic kubecolor command
alias ksys='kubecolor --namespace=kube-system'                    # kubecolor commands in kube-system namespace
alias ka='kubecolor apply --recursive -f'                         # Apply a configuration from file(s)
alias ksysa='kubecolor --namespace=kube-system apply --recursive -f' # Apply configuration in kube-system namespace
alias kak='kubecolor apply -k'                                    # Apply a kustomization directory2
alias kk='kubecolor kustomize'                                    # Preview kustomize output

# Execution and logs
alias kex='kubecolor exec -i -t'                                 # Execute command in container interactively
alias ksysex='kubecolor --namespace=kube-system exec -i -t'      # Execute command in kube-system container
alias klo='kubecolor logs -f'                                    # Stream logs from pod
alias ksyslo='kubecolor --namespace=kube-system logs -f'         # Stream logs from kube-system pod
alias klop='kubecolor logs -f -p'                                # Stream logs from previous instance of pod
alias ksyslop='kubecolor --namespace=kube-system logs -f -p'     # Stream logs from previous kube-system pod

# Cluster interaction
alias kp='kubecolor proxy'                                       # Start proxy to kubernetes API server
alias kpf='kubecolor port-forward'                               # Forward ports from pod to local machine

# Resource operations
alias kg='kubecolor get'                                         # List resources
alias ksysg='kubecolor --namespace=kube-system get'              # List resources in kube-system
alias kd='kubecolor describe'                                    # Show detailed resource information
alias ksysd='kubecolor --namespace=kube-system describe'         # Show kube-system resource details
alias krm='kubecolor delete'                                     # Delete resources
alias ksysrm='kubecolor --namespace=kube-system delete'          # Delete kube-system resources

# Pod operations
alias krun='kubecolor run --rm --restart=Never --image-pull-policy=IfNotPresent -i -t'          # Run pod and attach to it
alias ksysrun='kubecolor --namespace=kube-system run --rm --restart=Never --image-pull-policy=IfNotPresent -i -t' # Run pod in kube-system
alias kgpo='kubecolor get pods'                                  # List pods
alias ksysgpo='kubecolor --namespace=kube-system get pods'       # List kube-system pods
alias kdpo='kubecolor describe pods'                             # Describe pods
alias ksysdpo='kubecolor --namespace=kube-system describe pods'  # Describe kube-system pods
alias krmpo='kubecolor delete pods'                              # Delete pods
alias ksysrmpo='kubecolor --namespace=kube-system delete pods'   # Delete kube-system pods

# Deployment operations
alias kgdep='kubecolor get deployment'                           # List deployments
alias ksysgdep='kubecolor --namespace=kube-system get deployment' # List kube-system deployments
alias kddep='kubecolor describe deployment'                      # Describe deployments
alias ksysddep='kubecolor --namespace=kube-system describe deployment' # Describe kube-system deployments
alias krmdep='kubecolor delete deployment'                       # Delete deployments
alias ksysrmdep='kubecolor --namespace=kube-system delete deployment' # Delete kube-system deployments

# StatefulSet operations
alias kgsts='kubecolor get statefulset'                          # List statefulsets
alias ksysgsts='kubecolor --namespace=kube-system get statefulset' # List kube-system statefulsets
alias kdsts='kubecolor describe statefulset'                     # Describe statefulsets
alias ksysdsts='kubecolor --namespace=kube-system describe statefulset' # Describe kube-system statefulsets
alias krmsts='kubecolor delete statefulset'                      # Delete statefulsets
alias ksysrmsts='kubecolor --namespace=kube-system delete statefulset' # Delete kube-system statefulsets

# Service operations
alias kgsvc='kubecolor get service'                              # List services
alias ksysgsvc='kubecolor --namespace=kube-system get service'   # List kube-system services
alias kdsvc='kubecolor describe service'                         # Describe services
alias ksysdsvc='kubecolor --namespace=kube-system describe service' # Describe kube-system services
alias krmsvc='kubecolor delete service'                          # Delete services
alias ksysrmsvc='kubecolor --namespace=kube-system delete service' # Delete kube-system services

# Ingress operations
alias kging='kubecolor get ingress'                              # List ingresses
alias ksysging='kubecolor --namespace=kube-system get ingress'   # List kube-system ingresses
alias kding='kubecolor describe ingress'                         # Describe ingresses
alias ksysding='kubecolor --namespace=kube-system describe ingress' # Describe kube-system ingresses
alias krming='kubecolor delete ingress'                          # Delete ingresses
alias ksysrming='kubecolor --namespace=kube-system delete ingress' # Delete kube-system ingresses

# ConfigMap operations
alias kgcm='kubecolor get configmap'                             # List configmaps
alias ksysgcm='kubecolor --namespace=kube-system get configmap'  # List kube-system configmaps
alias kdcm='kubecolor describe configmap'                        # Describe configmaps
alias ksysdcml='kubecolor --namespace=kube-system describe configmap' # Describe kube-system configmaps
alias krmcml='kubecolor delete configmap'                        # Delete configmaps
alias ksysrmcm='kubecolor --namespace=kube-system delete configmap' # Delete kube-system configmaps

# Secret operations
alias kgsec='kubecolor get secret'                               # List secrets
alias ksysgsec='kubecolor --namespace=kube-system get secret'    # List kube-system secrets
alias kdsec='kubecolor describe secret'                          # Describe secrets
alias ksysdsec='kubecolor --namespace=kube-system describe secret' # Describe kube-system secrets
alias krmsec='kubecolor delete secret'                           # Delete secrets
alias ksysrmsec='kubecolor --namespace=kube-system delete secret' # Delete kube-system secrets

# Node operations
alias kgno='kubecolor get nodes'                                 # List nodes
alias kdno='kubecolor describe nodes'                            # Describe nodes
alias kgns='kubecolor get namespaces'                            # List namespaces
alias kdns='kubecolor describe namespaces'                       # Describe namespaces
alias krmns='kubecolor delete namespaces'                        # Delete namespaces

# YAML output
alias kgoyaml='kubecolor get -o=yaml'                           # Get YAML output
alias ksysgoyaml='kubecolor --namespace=kube-system get -o=yaml' # Get kube-system YAML output
alias kgpooyaml='kubecolor get pods -o=yaml'                    # Get YAML output for pods
alias ksysgpooyaml='kubecolor --namespace=kube-system get pods -o=yaml' # Get kube-system pods YAML output
alias kgdepoyaml='kubecolor get deployment -o=yaml'             # Get YAML output for deployments
alias ksysgdepoyaml='kubecolor --namespace=kube-system get deployment -o=yaml' # Get kube-system deployments YAML output
alias kgstsoyaml='kubecolor get statefulset -o=yaml'            # Get YAML output for statefulsets
alias ksysgstsoyaml='kubecolor --namespace=kube-system get statefulset -o=yaml' # Get kube-system statefulsets YAML output
alias kgsvcoyaml='kubecolor get service -o=yaml'                # Get YAML output for services
alias ksysgsvcoyaml='kubecolor --namespace=kube-system get service -o=yaml' # Get kube-system services YAML output
alias kgingoyaml='kubecolor get ingress -o=yaml'                # Get YAML output for ingresses
alias ksysgingoyaml='kubecolor --namespace=kube-system get ingress -o=yaml' # Get kube-system ingresses YAML output
alias kgcmoyaml='kubecolor get configmap -o=yaml'               # Get YAML output for configmaps
alias ksysgcmoyaml='kubecolor --namespace=kube-system get configmap -o=yaml' # Get kube-system configmaps YAML output
alias kgsecoyaml='kubecolor get secret -o=yaml'                 # Get YAML output for secrets
alias ksysgsecoyaml='kubecolor --namespace=kube-system get secret -o=yaml' # Get kube-system secrets YAML output
alias kgnooyaml='kubecolor get nodes -o=yaml'                   # Get YAML output for nodes
alias kgnsoyaml='kubecolor get namespaces -o=yaml'              # Get YAML output for namespaces

# Wide output
alias kgowide='kubecolor get -o=wide'                           # Get wide output
alias ksysgowide='kubecolor --namespace=kube-system get -o=wide' # Get kube-system wide output
alias kgpoowide='kubecolor get pods -o=wide'                     # Get wide output for pods
alias ksysgpoowide='kubecolor --namespace=kube-system get pods -o=wide' # Get kube-system pods wide output
alias kgdepowide='kubecolor get deployment -o=wide'              # Get wide output for deployments
alias ksysgdepowide='kubecolor --namespace=kube-system get deployment -o=wide' # Get kube-system deployments wide output
alias kgstsowide='kubecolor get statefulset -o=wide'             # Get wide output for statefulsets
alias ksysgstsowide='kubecolor --namespace=kube-system get statefulset -o=wide' # Get kube-system statefulsets wide output
alias kgsvcowide='kubecolor get service -o=wide'                 # Get wide output for services
alias ksysgsvcowide='kubecolor --namespace=kube-system get service -o=wide' # Get kube-system services wide output
alias kgingowide='kubecolor get ingress -o=wide'                 # Get wide output for ingresses
alias ksysgingowide='kubecolor --namespace=kube-system get ingress -o=wide' # Get kube-system ingresses wide output
alias kgcmowide='kubecolor get configmap -o=wide'                # Get wide output for configmaps
alias ksysgcmowide='kubecolor --namespace=kube-system get configmap -o=wide' # Get kube-system configmaps wide output
alias kgsecowide='kubecolor get secret -o=wide'                  # Get wide output for secrets
alias ksysgsecowide='kubecolor --namespace=kube-system get secret -o=wide' # Get kube-system secrets wide output
alias kgnoowide='kubecolor get nodes -o=wide'                    # Get wide output for nodes
alias kgnsowide='kubecolor get namespaces -o=wide'               # Get wide output for namespaces

# JSON output
alias kgojson='kubecolor get -o=json'                            # Get JSON output
alias ksysgojson='kubecolor --namespace=kube-system get -o=json' # Get kube-system JSON output
alias kgpoojson='kubecolor get pods -o=json'                     # Get JSON output for pods
alias ksysgpoojson='kubecolor --namespace=kube-system get pods -o=json' # Get kube-system pods JSON output
alias kgdepojson='kubecolor get deployment -o=json'              # Get JSON output for deployments
alias ksysgdepojson='kubecolor --namespace=kube-system get deployment -o=json' # Get kube-system deployments JSON output
alias kgstsojson='kubecolor get statefulset -o=json'             # Get JSON output for statefulsets
alias ksysgstsojson='kubecolor --namespace=kube-system get statefulset -o=json' # Get kube-system statefulsets JSON output
alias kgsvcojson='kubecolor get service -o=json'                 # Get JSON output for services
alias ksysgsvcojson='kubecolor --namespace=kube-system get service -o=json' # Get kube-system services JSON output
alias kgingojson='kubecolor get ingress -o=json'                 # Get JSON output for ingresses
alias ksysgingojson='kubecolor --namespace=kube-system get ingress -o=json' # Get kube-system ingresses JSON output
alias kgcmojson='kubecolor get configmap -o=json'                # Get JSON output for configmaps
alias ksysgcmojson='kubecolor --namespace=kube-system get configmap -o=json' # Get kube-system configmaps JSON output
alias kgsecojson='kubecolor get secret -o=json'                  # Get JSON output for secrets
alias ksysgsecojson='kubecolor --namespace=kube-system get secret -o=json' # Get kube-system secrets JSON output
alias kgnoojson='kubecolor get nodes -o=json'                    # Get JSON output for nodes
alias kgnsojson='kubecolor get namespaces -o=json'               # Get JSON output for namespaces

# All namespaces operations
alias kgall='kubecolor get --all-namespaces'                     # List all namespaces resources
alias kdall='kubecolor describe --all-namespaces'                # Describe all namespaces resources
alias kgpoall='kubecolor get pods --all-namespaces'              # List all namespaces pods
alias kdpoall='kubecolor describe pods --all-namespaces'         # Describe all namespaces pods
alias kgdepall='kubecolor get deployment --all-namespaces'       # List all namespaces deployments
alias kddepall='kubecolor describe deployment --all-namespaces'   # Describe all namespaces deployments
alias kgstsall='kubecolor get statefulset --all-namespaces'      # List all namespaces statefulsets
alias kdstsall='kubecolor describe statefulset --all-namespaces'  # Describe all namespaces statefulsets
alias kgsvcall='kubecolor get service --all-namespaces'          # List all namespaces services
alias kdsvcall='kubecolor describe service --all-namespaces'      # Describe all namespaces services
alias kgingall='kubecolor get ingress --all-namespaces'          # List all namespaces ingresses
alias kdingall='kubecolor describe ingress --all-namespaces'      # Describe all namespaces ingresses
alias kgcmall='kubecolor get configmap --all-namespaces'         # List all namespaces configmaps
alias kdcmall='kubecolor describe configmap --all-namespaces'     # Describe all namespaces configmaps
alias kgsecall='kubecolor get secret --all-namespaces'           # List all namespaces secrets
alias kdsecall='kubecolor describe secret --all-namespaces'       # Describe all namespaces secrets