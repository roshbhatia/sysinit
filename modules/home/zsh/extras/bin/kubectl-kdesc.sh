#!/usr/bin/env bash
# kubectl-kdesc: Advanced Kubernetes Resource Browser
# Install in PATH as 'kubectl-kdesc' to use as 'kubectl kdesc'
# shellcheck disable=all

# 888      .d888         .d888 
# 888     d88P"         d88P"  
# 888     888           888    
# 888  88888888888888888888888 
# 888 .88P888      d88P 888    
# 888888K 888     d88P  888    
# 888 "88b888    d88P   888    
# 888  888888   88888888888

# Default options
CACHE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/kdesc"
DEBUG=false
VERSION="1.0.0"
OUTPUT_FORMAT="yaml"
OUTPUT_OPTION="-oyaml"

# Color definitions
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Resource emoji mappings for visual identification
declare -A RESOURCE_EMOJIS
RESOURCE_EMOJIS=(
  ["pod"]="🔮"
  ["deployment"]="🚀"
  ["statefulset"]="📊"
  ["service"]="🔌"
  ["configmap"]="⚙️"
  ["secret"]="🔒"
  ["job"]="📋"
  ["cronjob"]="🕒"
  ["daemonset"]="👾"
  ["persistentvolumeclaim"]="💾"
  ["ingress"]="🌐"
  ["namespace"]="🏠"
  ["node"]="💻"
  ["replicaset"]="📦"
  ["endpoints"]="🔚"
  ["horizontalpodautoscaler"]="⚖️"
  ["role"]="👑"
  ["rolebinding"]="🔗"
  ["clusterrole"]="👑"
  ["clusterrolebinding"]="🔗"
  ["serviceaccount"]="🧩"
  ["persistentvolume"]="📀"
  ["storageclass"]="💿"
  ["networkpolicy"]="🕸️"
  ["poddisruptionbudget"]="🛡️"
  ["resourcequota"]="📏"
  
  # Also include capitalized versions for compatibility
  ["Pod"]="🔮"
  ["Deployment"]="🚀"
  ["StatefulSet"]="📊"
  ["Service"]="🔌"
  ["ConfigMap"]="⚙️"
  ["Secret"]="🔒"
  ["Job"]="📋"
  ["CronJob"]="🕒"
  ["DaemonSet"]="👾"
  ["PersistentVolumeClaim"]="💾"
  ["Ingress"]="🌐"
  ["Namespace"]="🏠"
  ["Node"]="💻"
  ["ReplicaSet"]="📦"
  ["Endpoints"]="🔚"
  ["HorizontalPodAutoscaler"]="⚖️"
  ["Role"]="👑"
  ["RoleBinding"]="🔗"
  ["ClusterRole"]="👑"
  ["ClusterRoleBinding"]="🔗"
  ["ServiceAccount"]="🧩"
  ["PersistentVolume"]="📀"
  ["StorageClass"]="💿"
  ["NetworkPolicy"]="🕸️"
  ["PodDisruptionBudget"]="🛡️"
  ["ResourceQuota"]="📏"
)

# This script requires kubectl, jq, and fzf to be installed

# Styled output functions
styled_print() {
    echo -e "${!1}$2${RESET}"
}

styled_header() {
    echo -e "\n${CYAN}=== $* ===${RESET}\n"
}

styled_error() {
    echo -e "${RED}❌ $*${RESET}"
}

styled_success() {
    echo -e "${GREEN}✅ $*${RESET}"
}

styled_warning() {
    echo -e "${YELLOW}⚠️ $*${RESET}"
}

styled_info() {
    echo -e "${BLUE}ℹ️ $*${RESET}"
}

styled_spinner() {
    echo -e "${CYAN}$1...${RESET}"
    eval "$2"
}

styled_confirm() {
    echo -e "${YELLOW}$* (y/n)${RESET}"
    read -r answer
    [[ "$answer" =~ ^[Yy] ]]
    return $?
}

styled_choose() {
    select opt in "$@"; do
        echo "$opt"
        break
    done
}

styled_filter() {
    echo -e "${CYAN}$1${RESET}"
    if command -v fzf >/dev/null 2>&1; then
        fzf
    else
        cat | head -20
    fi
}

styled_input() {
    echo -e "${CYAN}$*${RESET}"
    read -r input
    echo "$input"
}

styled_logo() {
    echo -e "${CYAN}
888      .d888         .d888 
888     d88P\"         d88P\"  
888     888           888    
888  88888888888888888888888 
888 .88P888      d88P 888    
888888K 888     d88P  888    
888 \"88b888    d88P   888    
888  888888   88888888888    ${RESET}"
}

# Helper functions
show_help() {
    styled_logo
    
    echo
    echo -e "${BOLD}kubectl-kdesc v${VERSION}${RESET} - Advanced Kubernetes Resource Browser"
    echo
    echo -e "${BOLD}Usage:${RESET}"
    echo "  kubectl kdesc [options] [RESOURCE_TYPES] [NAMESPACE]"
    echo
    echo -e "${BOLD}Options:${RESET}"
    echo "  -h, --help               Show this help message"
    echo "  -n, --namespace NAME     Specify namespace (default: current namespace)"
    echo "  -A, --all-namespaces     Search in all namespaces"
    echo "  -o, --output FORMAT      Output format (describe, yaml, json, wide) - Default: yaml"
    echo "  --kind KIND              Filter resources by kind (e.g. pod, deployment)"
    echo "  -l, --selector SELECTOR  Label selector"
    echo "  -f, --field SELECTOR     Field selector"
    echo "  -C, --context NAME       Kubernetes context to use"
    echo "  -k, --kubeconfig FILE    Path to kubeconfig file"
    echo "  -d, --debug              Enable debug mode"
    echo "  -v, --version            Show version information"
    echo
    echo -e "${BOLD}Examples:${RESET}"
    echo "  kubectl kdesc                          # Interactive resource browser"
    echo "  kubectl kdesc -n kube-system           # Browse resources in kube-system namespace"
    echo "  kubectl kdesc pods -n default -o yaml  # Browse pods in default namespace with YAML output"
    echo "  kubectl kdesc services,configmaps      # Browse only services and configmaps"
    echo "  kubectl kdesc --kind Deployment        # Browse only deployments"
    echo "  kubectl kdesc -A --kind Pod -o yaml    # Browse pods in all namespaces with YAML output"
    echo
    echo -e "${BOLD}Notes:${RESET}"
    echo "  * Requires fzf for basic usage"
}

show_version() {
    echo -e "${CYAN}kubectl-kdesc v${VERSION}${RESET}"
}

# Check dependencies
check_dependencies() {
    # Required dependencies
    for cmd in kubectl jq fzf; do
        if ! command -v $cmd >/dev/null 2>&1; then
            styled_error "$cmd is required but not installed."
            exit 1
        fi
    done
    
    # Create cache directory if needed
    mkdir -p "$CACHE_DIR"
}

# Parse command line arguments
parse_args() {
    local resource_specified=false
    local namespace_specified=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -n|--namespace)
                NAMESPACE="$2"
                NAMESPACE_OPTION="--namespace $2"
                namespace_specified=true
                shift 2
                ;;
            -A|--all-namespaces)
                NAMESPACE_OPTION="--all-namespaces"
                namespace_specified=true
                shift
                ;;
            -o|--output)
                case "$2" in
                    yaml|yml)
                        OUTPUT_FORMAT="yaml"
                        OUTPUT_OPTION="-oyaml"
                        ;;
                    json)
                        OUTPUT_FORMAT="json"
                        OUTPUT_OPTION="-ojson"
                        ;;
                    wide)
                        OUTPUT_FORMAT="wide"
                        OUTPUT_OPTION="-owide"
                        ;;
                    describe|desc)
                        OUTPUT_FORMAT="describe"
                        OUTPUT_OPTION=""
                        ;;
                    *)
                        styled_error "Invalid output format: $2"
                        show_help
                        exit 1
                        ;;
                esac
                shift 2
                ;;
            --kind)
                # Filter by specific kind
                RESOURCE_KIND_FILTER="$2"
                shift 2
                ;;
            -l|--selector)
                LABEL_SELECTOR="$2"
                LABEL_SELECTOR_OPTION="--selector $2"
                shift 2
                ;;
            -f|--field)
                FIELD_SELECTOR="$2"
                FIELD_SELECTOR_OPTION="--field-selector $2"
                shift 2
                ;;
            -C|--context)
                CONTEXT="$2"
                CONTEXT_OPTION="--context $2"
                shift 2
                ;;
            -k|--kubeconfig)
                KUBECONFIG="$2"
                KUBECONFIG_OPTION="--kubeconfig $2"
                shift 2
                ;;
            -d|--debug)
                DEBUG=true
                shift
                ;;
            -*)
                styled_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                if [[ "$resource_specified" == "false" ]]; then
                    RESOURCE_TYPE="$1"
                    resource_specified=true
                elif [[ "$namespace_specified" == "false" ]]; then
                    NAMESPACE="$1"
                    NAMESPACE_OPTION="--namespace $1"
                    namespace_specified=true
                else
                    styled_error "Unexpected argument: $1"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Set defaults if not specified
    if [[ -z "$RESOURCE_TYPE" ]]; then
        RESOURCE_TYPE="$RESOURCE_TYPES"
    fi
}

# Get available namespaces
get_namespaces() {
    local cmd="kubectl get namespaces -o jsonpath='{.items[*].metadata.name}'"
    
    styled_info "Fetching namespaces..."
    local namespaces=$(eval "$cmd")
    
    echo "$namespaces"
}

# Interactive namespace selection
select_namespace() {
    local namespaces=$(get_namespaces)
    local ns_array=($namespaces)
    
    # Add "All Namespaces" option
    ns_array=("All Namespaces" "${ns_array[@]}")
    
    styled_header "Select Namespace"
    
    NAMESPACE=$(printf '%s\n' "${ns_array[@]}" | styled_filter "Select namespace:")
    
    if [[ -n "$NAMESPACE" ]]; then
        if [[ "$NAMESPACE" == "All Namespaces" ]]; then
            NAMESPACE=""
            NAMESPACE_OPTION="--all-namespaces"
            styled_success "Using all namespaces"
        else
            NAMESPACE_OPTION="--namespace $NAMESPACE"
            styled_success "Selected namespace: $NAMESPACE"
        fi
    else
        NAMESPACE=""
        NAMESPACE_OPTION="--all-namespaces"
        styled_warning "No namespace selected. Using all namespaces."
    fi
}

# Get available resource types
get_resource_types() {
    # Try to get from API first
    if kubectl api-resources --verbs=get -o name &>/dev/null; then
        local cmd="kubectl api-resources --verbs=get -o name | sort | uniq"
        styled_info "Fetching resource types from API..."
        local api_resources=$(eval "$cmd" 2>/dev/null)
        
        if [[ -n "$api_resources" ]]; then
            echo "$api_resources"
            return
        fi
    fi
    
    # Fallback to predefined list if API method fails
    styled_info "Using predefined resource types list..."
    local resource_types=(
        "pods"
        "deployments"
        "services"
        "statefulsets"
        "replicasets"
        "daemonsets"
        "jobs"
        "cronjobs"
        "configmaps"
        "secrets"
        "persistentvolumeclaims"
        "persistentvolumes"
        "ingresses"
        "endpoints"
        "namespaces"
        "nodes"
        "serviceaccounts"
        "roles"
        "rolebindings"
        "clusterroles"
        "clusterrolebindings"
        "horizontalpodautoscalers"
        "poddisruptionbudgets"
        "networkpolicies"
        "resourcequotas"
        "customresourcedefinitions"
    )
    
    echo "${resource_types[@]}"
}

# Interactive resource type selection
select_resource_type() {
    # Common resource combinations and individual resources
    local rt_array=(
        "All Common Resources" 
        "pods,deployments,services,configmaps" 
        "pods" 
        "deployments" 
        "services" 
        "configmaps" 
        "secrets"
    )
    
    # Add individual resource types from the predefined list
    local individual_types=$(get_resource_types)
    for type in $individual_types; do
        # Check if this type is already in the array to avoid duplicates
        if ! [[ " ${rt_array[@]} " =~ " $type " ]]; then
            rt_array+=("$type")
        fi
    done
    
    styled_header "Select Resource Type"
    
    RESOURCE_TYPE=$(printf '%s\n' "${rt_array[@]}" | styled_filter "Select resource type:")
    
    if [[ -n "$RESOURCE_TYPE" ]]; then
        if [[ "$RESOURCE_TYPE" == "All Common Resources" ]]; then
            RESOURCE_TYPE="$RESOURCE_TYPES"
        fi
        styled_success "Selected resource type: $RESOURCE_TYPE"
    else
        RESOURCE_TYPE="$RESOURCE_TYPES"
        styled_warning "No resource type selected. Using common resources."
    fi
}

# Select output format
select_output_format() {
    local formats=("describe" "yaml" "json" "wide")
    
    styled_header "Select Output Format"
    
    OUTPUT_FORMAT=$(printf '%s\n' "${formats[@]}" | styled_filter "Select output format:")
    
    if [[ -n "$OUTPUT_FORMAT" ]]; then
        case "$OUTPUT_FORMAT" in
            yaml|yml)
                OUTPUT_OPTION="-oyaml"
                ;;
            json)
                OUTPUT_OPTION="-ojson"
                ;;
            wide)
                OUTPUT_OPTION="-owide"
                ;;
            describe|desc)
                OUTPUT_FORMAT="describe"
                OUTPUT_OPTION=""
                ;;
        esac
        styled_success "Selected output format: $OUTPUT_FORMAT"
    else
        OUTPUT_FORMAT="describe"
        OUTPUT_OPTION=""
        styled_warning "No output format selected. Using describe."
    fi
}

# Get resources of specified type in specified namespace
get_resources() {
    local cmd
    
    if [[ -n "$NAMESPACE" && "$NAMESPACE_OPTION" != "--all-namespaces" ]]; then
        cmd="kubectl get $RESOURCE_TYPE -n $NAMESPACE $LABEL_SELECTOR_OPTION $FIELD_SELECTOR_OPTION $CONTEXT_OPTION $KUBECONFIG_OPTION -o custom-columns=NAMESPACE:.metadata.namespace,KIND:.kind,NAME:.metadata.name --no-headers"
    else
        cmd="kubectl get $RESOURCE_TYPE --all-namespaces $LABEL_SELECTOR_OPTION $FIELD_SELECTOR_OPTION $CONTEXT_OPTION $KUBECONFIG_OPTION -o custom-columns=NAMESPACE:.metadata.namespace,KIND:.kind,NAME:.metadata.name --no-headers"
    fi
    
    if [[ "$DEBUG" == "true" ]]; then
        styled_info "Debug: Command = $cmd"
    fi
    
    styled_info "Fetching resources..."
    eval "$cmd"
}

# Display resource details
display_resource() {
    local namespace="$1"
    local kind="$2"
    local name="$3"
    local cmd
    
    # Convert kind to singular form for kubectl
    local resource_type=$(echo "$kind" | tr '[:upper:]' '[:lower:]')
    
    # Handle special cases
    if [[ "$resource_type" == "endpoints" ]]; then
        resource_type="endpoints"
    else
        # Remove trailing 's' for most resources
        resource_type=${resource_type%s}
    fi
    
    if [[ "$OUTPUT_FORMAT" == "describe" ]]; then
        cmd="kubectl describe $resource_type $name -n $namespace $CONTEXT_OPTION $KUBECONFIG_OPTION"
    else
        cmd="kubectl get $resource_type $name -n $namespace $OUTPUT_OPTION $CONTEXT_OPTION $KUBECONFIG_OPTION"
    fi
    
    if [[ "$DEBUG" == "true" ]]; then
        styled_info "Debug: Command = $cmd"
    fi
    
    eval "$cmd" | less -R
}

# Interactive resource browser
browse_resources() {
    local resources=$(get_resources)
    
    # Exit if no resources found
    if [[ -z "$resources" ]]; then
        styled_warning "No resources found matching criteria."
        exit 0
    fi
    
    # Format resources for display with emojis and apply kind filter if specified
    local formatted_resources=$(echo "$resources" | while read -r line; do
        if [[ -z "$line" ]]; then
            continue
        fi
        
        local namespace=$(echo "$line" | awk '{print $1}')
        local kind=$(echo "$line" | awk '{print $2}')
        local name=$(echo "$line" | awk '{print $3}')
        
        # Apply kind filter if specified
        if [[ -n "$RESOURCE_KIND_FILTER" ]]; then
            local kind_lower=$(echo "$kind" | tr '[:upper:]' '[:lower:]')
            local filter_lower=$(echo "$RESOURCE_KIND_FILTER" | tr '[:upper:]' '[:lower:]')
            
            # Skip if doesn't match filter
            if [[ "$kind_lower" != "$filter_lower" && "$kind" != "$RESOURCE_KIND_FILTER" ]]; then
                continue
            fi
        fi
        
        local kind_lower=$(echo "$kind" | tr '[:upper:]' '[:lower:]')
        local emoji="${RESOURCE_EMOJIS[$kind_lower]:-${RESOURCE_EMOJIS[$kind]:-❓}}"
        
        echo "$name | $kind | $namespace | $emoji"
    done)
    
    # Show resource selection menu
    styled_header "Select Resource to View"
    
    # Define preview command with optional syntax highlighting using bat if available
    local bat_cmd=""
    if command -v bat >/dev/null 2>&1; then
        bat_cmd="| bat --color=always --language=yaml --style=plain"
    fi
    
    # For describe output
    local preview_cmd="echo {} | awk -F ' [|] ' '{print \$3, \$2, \$1}' | xargs -n 3 bash -c 'kubectl describe \$1 \$2 -n \$0 $CONTEXT_OPTION $KUBECONFIG_OPTION'"
    
    # For YAML, JSON, etc. outputs
    if [[ "$OUTPUT_FORMAT" != "describe" ]]; then
        preview_cmd="echo {} | awk -F ' [|] ' '{print \$3, \$2, \$1}' | xargs -n 3 bash -c 'kubectl get \$1 \$2 -n \$0 $OUTPUT_OPTION $CONTEXT_OPTION $KUBECONFIG_OPTION $bat_cmd'"
    fi
    
    local selection
    selection=$(echo "$formatted_resources" | fzf --ansi --height=60% \
        --preview "$preview_cmd" \
        --preview-window=right:70% \
        --header="Arrow keys to navigate, Enter to select, ? for help, Ctrl-C to exit" \
        --bind="ctrl-r:reload(kubectl get $RESOURCE_TYPE $NAMESPACE_OPTION -o custom-columns=NAMESPACE:.metadata.namespace,KIND:.kind,NAME:.metadata.name --no-headers | while read -r line; do
            if [[ -z \"\$line\" ]]; then continue; fi
            namespace=\$(echo \"\$line\" | awk '{print \$1}');
            kind=\$(echo \"\$line\" | awk '{print \$2}');
            name=\$(echo \"\$line\" | awk '{print \$3}');
            echo \"\$name | \$kind | \$namespace\";
        done)" \
        --bind="?:toggle-preview" \
        --no-info)
    
    if [[ -z "$selection" ]]; then
        styled_warning "No resource selected."
        exit 0
    fi
    
    # Parse selection to get resource details
    local sel_name=$(echo "$selection" | awk -F ' [|] ' '{print $1}' | sed 's/^ *//' | sed 's/ *$//')
    local sel_kind=$(echo "$selection" | awk -F ' [|] ' '{print $2}' | sed 's/^ *//' | sed 's/ *$//')
    local sel_namespace=$(echo "$selection" | awk -F ' [|] ' '{print $3}' | sed 's/^ *//' | sed 's/ *$//')
    
    # Display resource details
    display_resource "$sel_namespace" "$sel_kind" "$sel_name"
    
    # Return to browse mode automatically
    browse_resources
}

# Main function
main() {
    # Parse arguments
    parse_args "$@"
    
    # Check dependencies
    check_dependencies
    
    # Interactive namespace selection if not specified
    if [[ -z "$NAMESPACE" && -z "$NAMESPACE_OPTION" ]]; then
        if styled_confirm "Select a specific namespace?"; then
            select_namespace
        else
            styled_info "Using resources from all namespaces"
            NAMESPACE_OPTION="--all-namespaces"
        fi
    fi
    
    # Interactive resource type selection if needed
    if [[ "$RESOURCE_TYPE" == "$RESOURCE_TYPES" ]]; then
        if styled_confirm "Select specific resource types?"; then
            select_resource_type
        fi
    fi
    
    # Output format selection is now handled by command-line flags (-o/--output)
    # No interactive prompt for output format
    
    # Debug info
    if [[ "$DEBUG" == "true" ]]; then
        styled_info "Debug: Resource Type = $RESOURCE_TYPE"
        styled_info "Debug: Namespace = $NAMESPACE"
        styled_info "Debug: Output Format = $OUTPUT_FORMAT"
    fi
    
    # Browse resources
    browse_resources
}

# Execute main
main "$@"