#!/usr/bin/env bash
# kubectl-klog: Advanced Kubernetes log viewer with Gum styling
# Install in PATH as 'kubectl-klog' to use as 'kubectl klog'

# 888             888                   
# 888             888                   
# 888             888                   
# 888  888 888    888 .d88b.   .d88b.   
# 888 .88P 888    888d88""88b d88P"88b  
# 888888K  888    888888  888 888  888  
# 888 "88b Y88b.  888Y88..88P Y88b 888  
# 888  888  "Y888 888 "Y88P"   "Y88888  
#                                  888  
#                             Y8b d88P  
#                              "Y88P"   

# Support for xterm-256color
export TERM=xterm-256color

# Default options
VERSION="1.0.0"
NAMESPACE=""
NAMESPACE_OPTION=""
CONTAINER=""
CONTAINER_OPTION=""
CONTEXT=""
CONTEXT_OPTION=""
TAIL="-1"
TAIL_OPTION=""
SELECTOR=""
SELECTOR_OPTION=""
SINCE="1m"
SINCE_OPTION=""
TIMESTAMPS=false
PREVIOUS=false
HIGHLIGHT=""
HIGHLIGHT_OPTION=""
EXCLUDE=""
EXCLUDE_OPTION=""
KUBECONFIG=""
KUBECONFIG_OPTION=""
INTERACTIVE=false
MINIMAL=false
DEBUG=false

# Cache directory
CACHE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/klog"

# Check dependencies (defined below)

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

# This script requires kubectl, stern, jq, and fzf to be installed

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
888             888                   
888             888                   
888             888                   
888  888 888    888 .d88b.   .d88b.   
888 .88P 888    888d88\"\"88b d88P\"88b  
888888K  888    888888  888 888  888  
888 \"88b Y88b.  888Y88..88P Y88b 888  
888  888  \"Y888 888 \"Y88P\"   \"Y88888  
                                  888  
                             Y8b d88P  
                              \"Y88P\"   ${RESET}"
}

# Helper functions
show_help() {
    styled_logo
    
    echo
    echo -e "${BOLD}kubectl-klog v${VERSION}${RESET} - Advanced Kubernetes log viewer"
    echo
    echo -e "${BOLD}Usage:${RESET}"
    echo "  kubectl klog [options] [PATTERN]"
    echo
    echo -e "${BOLD}Arguments:${RESET}"
    echo "  PATTERN                  Log selector pattern (glob/regex supported)"
    echo "                          Examples: "
    echo "                          - \"provider-nrf\" (exact match)"
    echo "                          - \"provider-nrf*\" (all pods starting with provider-nrf)"
    echo "                          - \"provider-nrf-[^r]\" (all provider-nrf- pods except those with 'r')"
    echo
    echo -e "${BOLD}Options:${RESET}"
    echo "  -h, --help               Show this help message"
    echo "  -n, --namespace NAME     Specify namespace (default: current namespace)"
    echo "  -A, --all-namespaces     Search in all namespaces"
    echo "  -c, --container NAME     Specify container name"
    echo "  -l, --selector SELECTOR  Kubernetes selector"
    echo "  -t, --tail LINES         Number of lines to show (default: ${TAIL})"
    echo "  -s, --since DURATION     Show logs since duration (default: ${SINCE})"
    echo "  -p, --previous           Show logs from previous container instance"
    echo "  -T, --timestamps         Show timestamps in logs"
    echo "  -H, --highlight PATTERN  Highlight pattern in logs (regexp supported)"
    echo "  -x, --exclude PATTERN    Exclude pattern from logs (regexp supported)"
    echo "  -C, --context NAME       Kubernetes context to use"
    echo "  -k, --kubeconfig FILE    Path to kubeconfig file"
    echo "  -i, --interactive        Interactive pod/deployment selection"
    echo "  -m, --minimal            Minimal output (no pod/container prefix)"
    echo "  -d, --debug              Enable debug mode"
    echo "  -v, --version            Show version information"
    echo
    echo -e "${BOLD}Examples:${RESET}"
    echo "  kubectl klog                          # Interactive pod selection"
    echo "  kubectl klog provider-nrf             # Logs from provider-nrf pods"
    echo "  kubectl klog \"provider-nrf*\"          # Logs from all pods starting with provider-nrf"
    echo "  kubectl klog -n crossplane-system     # All logs in crossplane-system namespace"
    echo "  kubectl klog -n kube-system \"coredns\" # CoreDNS logs in kube-system"
    echo "  kubectl klog -H \"error|Error|ERROR\"   # All logs, highlighting errors"
    echo "  kubectl klog -x \"health|liveness\"     # All logs, excluding health checks"
    echo
    echo -e "${BOLD}Notes:${RESET}"
    echo "  * Wildcards must be quoted to prevent shell expansion"
    echo "  * Requires stern to be installed (https://github.com/stern/stern)"
}

show_version() {
    echo -e "${CYAN}kubectl-klog v${VERSION}${RESET}"
}

# Check dependencies
check_dependencies() {
    # Required dependencies
    for cmd in kubectl stern jq fzf; do
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
                shift 2
                ;;
            -A|--all-namespaces)
                NAMESPACE_OPTION="--all-namespaces"
                shift
                ;;
            -c|--container)
                CONTAINER="$2"
                CONTAINER_OPTION="--container $2"
                shift 2
                ;;
            -l|--selector)
                SELECTOR="$2"
                SELECTOR_OPTION="--selector $2"
                shift 2
                ;;
            -t|--tail)
                TAIL="$2"
                TAIL_OPTION="--tail $2"
                shift 2
                ;;
            -s|--since)
                SINCE="$2"
                SINCE_OPTION="--since $2"
                shift 2
                ;;
            -p|--previous)
                PREVIOUS=true
                shift
                ;;
            -T|--timestamps)
                TIMESTAMPS=true
                shift
                ;;
            -H|--highlight)
                HIGHLIGHT="$2"
                HIGHLIGHT_OPTION="--highlight '$2'"
                shift 2
                ;;
            -x|--exclude)
                EXCLUDE="$2"
                EXCLUDE_OPTION="--exclude '$2'"
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
            -i|--interactive)
                INTERACTIVE=true
                shift
                ;;
            -m|--minimal)
                MINIMAL=true
                shift
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
                PATTERN="$1"
                shift
                ;;
        esac
    done
}

# Get available namespaces
get_namespaces() {
    local cmd="kubectl get namespaces -o jsonpath='{.items[*].metadata.name}'"
    local namespaces
    
    styled_info "Fetching namespaces..."
    namespaces=$(eval "$cmd")
    
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

# Get available resources (pods/deployments)
get_resources() {
    local cmd
    
    if [[ -n "$NAMESPACE" ]]; then
        cmd="kubectl get pods,deployments -n $NAMESPACE -o custom-columns=KIND:.kind,NAME:.metadata.name,NAMESPACE:.metadata.namespace --no-headers"
    else
        cmd="kubectl get pods,deployments --all-namespaces -o custom-columns=KIND:.kind,NAME:.metadata.name,NAMESPACE:.metadata.namespace --no-headers"
    fi
    
    styled_info "Fetching resources..."
    eval "$cmd"
}

# List and select pods/deployments interactively
interactive_select() {
    local resources
    
    # Set all namespaces by default for interactive mode
    if [[ -z "$NAMESPACE" && -z "$NAMESPACE_OPTION" ]]; then
        styled_info "Using resources from all namespaces by default"
        NAMESPACE_OPTION="--all-namespaces"
        
        # Optional namespace selection
        if styled_confirm "Do you want to filter by a specific namespace?"; then
            select_namespace
        fi
    fi
    
    # Get resources and format for selection
    resources=$(get_resources | sort)
    
    # Add a header
    styled_header "Select Resources"
    
    # Filter resources by pattern if provided
    if [[ -n "$PATTERN" ]]; then
        resources=$(echo "$resources" | grep -i "$PATTERN")
    fi
    
    # Prepare data for selection
    formatted_resources=$(echo "$resources" | while read -r line; do
        local kind=$(echo "$line" | awk '{print $1}')
        local name=$(echo "$line" | awk '{print $2}')
        local ns=$(echo "$line" | awk '{print $3}')
        
        if [[ "$kind" == "Pod" ]]; then
            echo -e "${GREEN}$name${RESET} (${BLUE}$ns${RESET}) - ${YELLOW}$kind${RESET}"
        else
            echo -e "${MAGENTA}$name${RESET} (${BLUE}$ns${RESET}) - ${YELLOW}$kind${RESET}"
        fi
    done)
    
    # Let user select resources
    local selection
    selection=$(echo "$formatted_resources" | fzf --ansi --multi --height=40% --border --header="Select resources (tab to multi-select)")
    
    if [[ -z "$selection" ]]; then
        styled_warning "No resources selected."
        exit 0
    fi
    
    # Process selection for stern
    local patterns=""
    local first_ns=""
    
    echo "$selection" | while read -r line; do
        local name=$(echo "$line" | awk -F ' \\(' '{print $1}')
        local ns=$(echo "$line" | awk -F '[()]' '{print $2}')
        
        # Store first namespace for consistent use
        if [[ -z "$first_ns" ]]; then
            first_ns="$ns"
            NAMESPACE="$ns"
            NAMESPACE_OPTION="--namespace $ns"
        fi
        
        # Add to pattern
        if [[ -n "$patterns" ]]; then
            patterns="$patterns|$name"
        else
            patterns="$name"
        fi
    done
    
    PATTERN="$patterns"
    
    styled_success "Selected pattern: $PATTERN"
    styled_success "Using namespace: $NAMESPACE"
}

# Main function
main() {
    # Parse arguments
    parse_args "$@"
    
    # Check dependencies
    check_dependencies
    
    # Always use interactive mode if no pattern is provided
    if [[ -z "$PATTERN" ]]; then
        INTERACTIVE=true
    fi
    
    # Use interactive selection by default if pattern not specified
    if [[ -z "$PATTERN" ]]; then
        interactive_select
    fi
    
    # Ensure pattern is set
    if [[ -z "$PATTERN" ]]; then
        styled_error "No pattern specified."
        show_help
        exit 1
    fi
    
    # Debug info
    if [[ "$DEBUG" == "true" ]]; then
        styled_info "Debug: Pattern = $PATTERN"
        styled_info "Debug: Namespace = $NAMESPACE"
        styled_info "Debug: Container = $CONTAINER"
    fi
    
    # Build stern command
    STERN_CMD="stern"
    
    # Add options
    [[ -n "$NAMESPACE_OPTION" ]] && STERN_CMD="$STERN_CMD $NAMESPACE_OPTION"
    [[ -n "$CONTAINER_OPTION" ]] && STERN_CMD="$STERN_CMD $CONTAINER_OPTION"
    [[ -n "$CONTEXT_OPTION" ]] && STERN_CMD="$STERN_CMD $CONTEXT_OPTION"
    [[ -n "$TAIL_OPTION" ]] && STERN_CMD="$STERN_CMD $TAIL_OPTION"
    [[ -n "$SELECTOR_OPTION" ]] && STERN_CMD="$STERN_CMD $SELECTOR_OPTION"
    [[ -n "$SINCE_OPTION" ]] && STERN_CMD="$STERN_CMD $SINCE_OPTION"
    [[ "$PREVIOUS" == "true" ]] && STERN_CMD="$STERN_CMD --previous"
    [[ "$TIMESTAMPS" == "true" ]] && STERN_CMD="$STERN_CMD --timestamps"
    [[ -n "$HIGHLIGHT_OPTION" ]] && STERN_CMD="$STERN_CMD $HIGHLIGHT_OPTION"
    [[ -n "$EXCLUDE_OPTION" ]] && STERN_CMD="$STERN_CMD $EXCLUDE_OPTION"
    [[ -n "$KUBECONFIG_OPTION" ]] && STERN_CMD="$STERN_CMD $KUBECONFIG_OPTION"
    
    # Set color mode
    STERN_CMD="$STERN_CMD --color always"
    
    # Set output format
    if [[ "$MINIMAL" == "true" ]]; then
        STERN_CMD="$STERN_CMD --template '{{.Message}}{{\"\\n\"}}'"
    fi
    
    # Add pattern
    STERN_CMD="$STERN_CMD \"$PATTERN\""
    
    # Debug output
    if [[ "$DEBUG" == "true" ]]; then
        styled_info "Debug: Command = $STERN_CMD"
    fi
    
    # Add a nice info message before executing
    echo -e "${CYAN}🔍 Tailing logs for: $PATTERN${RESET}"
    
    # Execute
    eval "$STERN_CMD"
}

# Execute main
main "$@"