#!/usr/bin/env bash
# kubectl-kdesc: Advanced Kubernetes Resource Browser
# Install in PATH as 'kubectl-kdesc' to use as 'kubectl kdesc'

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

# Color definitions (fallback if gum not available)
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
RESET='\033[0m'

# Resource emoji mappings for visual identification
declare -A RESOURCE_EMOJIS
RESOURCE_EMOJIS=(
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

# Check for gum and set USE_GUM flag
if command -v gum >/dev/null 2>&1; then
    USE_GUM=true
else
    USE_GUM=false
fi

# Check for bat and set USE_BAT flag
if command -v bat >/dev/null 2>&1; then
    USE_BAT=true
else
    USE_BAT=false
fi

# Styled output functions
styled_print() {
    if [[ "$USE_GUM" == "true" ]]; then
        gum style --foreground "$1" "${@:2}"
    else
        local color
        case "$1" in
            "1") color=$RED ;;
            "2") color=$GREEN ;;
            "3") color=$YELLOW ;;
            "4") color=$BLUE ;;
            "5") color=$MAGENTA ;;
            "6") color=$CYAN ;;
            "7") color=$WHITE ;;
            *) color=$RESET ;;
        esac
        echo -e "${color}${*:2}${RESET}"
    fi
}

styled_header() {
    if [[ "$USE_GUM" == "true" ]]; then
        gum style --border normal --margin "1" --padding "1 2" --border-foreground 6 "$@"
    else
        echo -e "${CYAN}╭───────────────────────────────────────────────╮${RESET}"
        echo -e "${CYAN}│${RESET} $* ${CYAN}│${RESET}"
        echo -e "${CYAN}╰───────────────────────────────────────────────╯${RESET}"
    fi
}

styled_error() {
    if [[ "$USE_GUM" == "true" ]]; then
        gum style --foreground 1 --bold "❌ $*"
    else
        echo -e "${RED}❌ $*${RESET}"
    fi
}

styled_success() {
    if [[ "$USE_GUM" == "true" ]]; then
        gum style --foreground 2 --bold "✅ $*"
    else
        echo -e "${GREEN}✅ $*${RESET}"
    fi
}

styled_warning() {
    if [[ "$USE_GUM" == "true" ]]; then
        gum style --foreground 3 --bold "⚠️ $*"
    else
        echo -e "${YELLOW}⚠️ $*${RESET}"
    fi
}

styled_info() {
    if [[ "$USE_GUM" == "true" ]]; then
        gum style --foreground 4 --bold "ℹ️ $*"
    else
        echo -e "${BLUE}ℹ️ $*${RESET}"
    fi
}

styled_spinner() {
    if [[ "$USE_GUM" == "true" ]]; then
        gum spin --spinner dot --title "$*" -- "$2"
    else
        echo -e "${BLUE}⏳ $*${RESET}"
        eval "$2"
    fi
}

styled_confirm() {
    if [[ "$USE_GUM" == "true" ]]; then
        gum confirm "$*"
        return $?
    else
        read -p "$* (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            return 0
        else
            return 1
        fi
    fi
}

styled_choose() {
    if [[ "$USE_GUM" == "true" ]]; then
        gum choose --height 20 "$@"
    else
        if command -v fzf >/dev/null 2>&1; then
            fzf --height 20 --ansi --header "Select one:" <<< "$(printf '%s\n' "$@")"
        else
            select opt in "$@"; do
                echo "$opt"
                break
            done
        fi
    fi
}

styled_filter() {
    if [[ "$USE_GUM" == "true" ]]; then
        gum filter --placeholder "$1" --height 20
    else
        if command -v fzf >/dev/null 2>&1; then
            fzf --height 20 --ansi --header "$1"
        else
            cat
        fi
    fi
}

styled_input() {
    if [[ "$USE_GUM" == "true" ]]; then
        gum input --placeholder "$*"
    else
        read -p "$* " input
        echo "$input"
    fi
}

styled_logo() {
    if [[ "$USE_GUM" == "true" ]]; then
        gum style --foreground 6 --bold "
888      .d888         .d888 
888     d88P\"         d88P\"  
888     888           888    
888  88888888888888888888888 
888 .88P888      d88P 888    
888888K 888     d88P  888    
888 \"88b888    d88P   888    
888  888888   88888888888    "
    else
        echo -e "${CYAN}
888      .d888         .d888 
888     d88P\"         d88P\"  
888     888           888    
888  88888888888888888888888 
888 .88P888      d88P 888    
888888K 888     d88P  888    
888 \"88b888    d88P   888    
888  888888   88888888888    ${RESET}"
    fi
}

# Helper functions
show_help() {
    styled_logo
    
    if [[ "$USE_GUM" == "true" ]]; then
        echo
        gum style --bold "kubectl-kdesc v${VERSION}" -- "Advanced Kubernetes Resource Browser"
        echo
        gum style --bold "Usage:"
        echo "  kubectl kdesc [options] [RESOURCE_TYPES] [NAMESPACE]"
        echo
        gum style --bold "Options:"
        gum style "  -h, --help               Show this help message"
        gum style "  -n, --namespace NAME     Specify namespace (default: current namespace)"
        gum style "  -A, --all-namespaces     Search in all namespaces"
        gum style "  -o, --output FORMAT      Output format (describe, yaml, json)"
        gum style "  -l, --selector SELECTOR  Label selector"
        gum style "  -f, --field SELECTOR     Field selector"
        gum style "  -C, --context NAME       Kubernetes context to use"
        gum style "  -k, --kubeconfig FILE    Path to kubeconfig file"
        gum style "  -d, --debug              Enable debug mode"
        gum style "  -v, --version            Show version information"
        echo
        gum style --bold "Examples:"
        gum style "  kubectl kdesc                          # Interactive resource browser"
        gum style "  kubectl kdesc -n kube-system           # Browse resources in kube-system namespace"
        gum style "  kubectl kdesc pods -n default -o yaml  # Browse pods in default namespace with YAML output"
        gum style "  kubectl kdesc services,configmaps      # Browse only services and configmaps"
        echo
        gum style --bold "Notes:"
        gum style "  * Requires either fzf for basic usage, or"
        gum style "  * Gum + Bat for enhanced interactive experience"
        if [[ "$USE_GUM" == "true" ]]; then
            gum style "  * Gum is installed, enabling enhanced UI features"
        else
            gum style "  * Gum is not installed. Install for enhanced UI: https://github.com/charmbracelet/gum"
        fi
    else
        cat <<EOF
${BOLD}kubectl-kdesc v${VERSION}${RESET} - Advanced Kubernetes Resource Browser

${BOLD}Usage:${RESET}
  kubectl kdesc [options] [RESOURCE_TYPES] [NAMESPACE]

${BOLD}Options:${RESET}
  -h, --help               Show this help message
  -n, --namespace NAME     Specify namespace (default: current namespace)
  -A, --all-namespaces     Search in all namespaces
  -o, --output FORMAT      Output format (describe, yaml, json)
  -l, --selector SELECTOR  Label selector
  -f, --field SELECTOR     Field selector
  -C, --context NAME       Kubernetes context to use
  -k, --kubeconfig FILE    Path to kubeconfig file
  -d, --debug              Enable debug mode
  -v, --version            Show version information

${BOLD}Examples:${RESET}
  kubectl kdesc                          # Interactive resource browser
  kubectl kdesc -n kube-system           # Browse resources in kube-system namespace
  kubectl kdesc pods -n default -o yaml  # Browse pods in default namespace with YAML output
  kubectl kdesc services,configmaps      # Browse only services and configmaps

${BOLD}Notes:${RESET}
  * Requires either fzf for basic usage, or
  * Gum + Bat for enhanced interactive experience
EOF
    fi
}

show_version() {
    if [[ "$USE_GUM" == "true" ]]; then
        gum style --bold --foreground 6 "kubectl-kdesc v${VERSION}"
    else
        echo -e "${CYAN}kubectl-kdesc v${VERSION}${RESET}"
    fi
}

# Check dependencies
check_dependencies() {
    for cmd in kubectl jq gum bat fzf; do
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
    local namespaces
    
    if [[ "$USE_GUM" == "true" ]]; then
        namespaces=$(gum spin --spinner dot --title "Fetching namespaces..." -- bash -c "$cmd")
    else
        styled_info "Fetching namespaces..."
        namespaces=$(eval "$cmd")
    fi
    
    echo "$namespaces"
}

# Interactive namespace selection
select_namespace() {
    local namespaces=$(get_namespaces)
    local ns_array=($namespaces)
    
    # Add "All Namespaces" option
    ns_array=("All Namespaces" "${ns_array[@]}")
    
    styled_header "Select Namespace"
    
    if [[ "$USE_GUM" == "true" ]]; then
        NAMESPACE=$(gum choose --height 20 "${ns_array[@]}")
    else
        NAMESPACE=$(printf '%s\n' "${ns_array[@]}" | styled_filter "Select namespace:")
    fi
    
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
    local cmd="kubectl api-resources --verbs=get -o name | sort | uniq"
    local resource_types
    
    if [[ "$USE_GUM" == "true" ]]; then
        resource_types=$(gum spin --spinner dot --title "Fetching resource types..." -- bash -c "$cmd")
    else
        styled_info "Fetching resource types..."
        resource_types=$(eval "$cmd")
    fi
    
    echo "$resource_types"
}

# Interactive resource type selection
select_resource_type() {
    local resource_types=$(get_resource_types)
    local rt_array=($resource_types)
    
    # Add common resource combinations
    rt_array=("All Common Resources" "pods,deployments,services,configmaps" "pods" "deployments" "services" "configmaps" "secrets" "${rt_array[@]}")
    
    styled_header "Select Resource Type"
    
    if [[ "$USE_GUM" == "true" ]]; then
        RESOURCE_TYPE=$(gum choose --height 20 "${rt_array[@]}")
    else
        RESOURCE_TYPE=$(printf '%s\n' "${rt_array[@]}" | styled_filter "Select resource type:")
    fi
    
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
    
    if [[ "$USE_GUM" == "true" ]]; then
        OUTPUT_FORMAT=$(gum choose --height 10 "${formats[@]}")
    else
        OUTPUT_FORMAT=$(printf '%s\n' "${formats[@]}" | styled_filter "Select output format:")
    fi
    
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
    
    if [[ "$USE_GUM" == "true" ]]; then
        gum spin --spinner dot --title "Fetching resources..." -- bash -c "$cmd"
    else
        styled_info "Fetching resources..."
        eval "$cmd"
    fi
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
    
    if [[ "$USE_BAT" == "true" ]]; then
        eval "$cmd" | bat --style=plain --color=always --language="${OUTPUT_FORMAT}" --paging=always
    else
        eval "$cmd" | less -R
    fi
}

# Interactive resource browser
browse_resources() {
    local resources=$(get_resources)
    
    # Exit if no resources found
    if [[ -z "$resources" ]]; then
        styled_warning "No resources found matching criteria."
        exit 0
    fi
    
    # Format resources for display with emojis
    local formatted_resources=$(echo "$resources" | while read -r line; do
        if [[ -z "$line" ]]; then
            continue
        fi
        
        local namespace=$(echo "$line" | awk '{print $1}')
        local kind=$(echo "$line" | awk '{print $2}')
        local name=$(echo "$line" | awk '{print $3}')
        local emoji="${RESOURCE_EMOJIS[$kind]:-❓}"
        
        echo "$emoji $name | $kind | $namespace"
    done)
    
    # Show resource selection menu
    styled_header "Select Resource to View"
    
    local preview_cmd="echo {} | awk -F ' [|] ' '{print \$3, \$2, \$1}' | sed 's/^[^ ]* //' | xargs -n 3 bash -c 'kubectl describe \$1 \$2 -n \$0 $CONTEXT_OPTION $KUBECONFIG_OPTION'"
    if [[ "$OUTPUT_FORMAT" != "describe" ]]; then
        preview_cmd="echo {} | awk -F ' [|] ' '{print \$3, \$2, \$1}' | sed 's/^[^ ]* //' | xargs -n 3 bash -c 'kubectl get \$1 \$2 -n \$0 $OUTPUT_OPTION $CONTEXT_OPTION $KUBECONFIG_OPTION'"
    fi
    
    if [[ "$USE_BAT" == "true" ]]; then
        preview_cmd="$preview_cmd | bat --style=plain --color=always"
    fi
    
    local selection
    if command -v fzf >/dev/null 2>&1; then
        selection=$(echo "$formatted_resources" | fzf --ansi --height=60% \
            --preview "$preview_cmd" \
            --preview-window=right:70% \
            --header="Arrow keys to navigate, Enter to select, ? for help" \
            --bind="ctrl-r:reload(kubectl get $RESOURCE_TYPE $NAMESPACE_OPTION -o custom-columns=NAMESPACE:.metadata.namespace,KIND:.kind,NAME:.metadata.name --no-headers | sed 's/^//')" \
            --bind="?:toggle-preview")
    else
        selection=$(echo "$formatted_resources" | styled_filter "Select resource:")
    fi
    
    if [[ -z "$selection" ]]; then
        styled_warning "No resource selected."
        exit 0
    fi
    
    # Parse selection to get resource details
    local sel_name=$(echo "$selection" | awk -F ' [|] ' '{print $1}' | sed 's/^[^ ]* //')
    local sel_kind=$(echo "$selection" | awk -F ' [|] ' '{print $2}' | sed 's/^ *//' | sed 's/ *$//')
    local sel_namespace=$(echo "$selection" | awk -F ' [|] ' '{print $3}' | sed 's/^ *//' | sed 's/ *$//')
    
    # Display resource details
    display_resource "$sel_namespace" "$sel_kind" "$sel_name"
    
    # Ask if user wants to browse more resources
    if styled_confirm "View another resource?"; then
        browse_resources
    fi
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
    
    # Interactive output format selection if needed
    if [[ -z "$OUTPUT_OPTION" ]]; then
        if styled_confirm "Select output format?"; then
            select_output_format
        fi
    fi
    
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