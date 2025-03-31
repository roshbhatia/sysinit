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

# Check dependencies
check_dependencies() {
    for cmd in stern kubectl jq gum fzf; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            styled_error "$cmd is required but not installed."
            exit 1
        fi
    done
    
    # Create cache directory if needed
    mkdir -p "$CACHE_DIR"
}

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

# Check for gum and set USE_GUM flag
if command -v gum >/dev/null 2>&1; then
    USE_GUM=true
else
    USE_GUM=false
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
                              \"Y88P\"   "
    else
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
    fi
}

# Helper functions
show_help() {
    styled_logo
    
    if [[ "$USE_GUM" == "true" ]]; then
        echo
        gum style --bold "kubectl-klog v${VERSION}" -- "Advanced Kubernetes log viewer"
        echo
        gum style --bold "Usage:"
        echo "  kubectl klog [options] [PATTERN]"
        echo
        gum style --bold "Arguments:"
        echo "  PATTERN                  Log selector pattern (glob/regex supported)"
        echo "                          Examples: "
        echo "                          - \"provider-nrf\" (exact match)"
        echo "                          - \"provider-nrf*\" (all pods starting with provider-nrf)"
        echo "                          - \"provider-nrf-[^r]\" (all provider-nrf- pods except those with 'r')"
        echo
        gum style --bold "Options:"
        gum style "  -h, --help               Show this help message"
        gum style "  -n, --namespace NAME     Specify namespace (default: current namespace)"
        gum style "  -A, --all-namespaces     Search in all namespaces"
        gum style "  -c, --container NAME     Specify container name"
        gum style "  -l, --selector SELECTOR  Kubernetes selector"
        gum style "  -t, --tail LINES         Number of lines to show (default: ${TAIL})"
        gum style "  -s, --since DURATION     Show logs since duration (default: ${SINCE})"
        gum style "  -p, --previous           Show logs from previous container instance"
        gum style "  -T, --timestamps         Show timestamps in logs"
        gum style "  -H, --highlight PATTERN  Highlight pattern in logs (regexp supported)"
        gum style "  -x, --exclude PATTERN    Exclude pattern from logs (regexp supported)"
        gum style "  -C, --context NAME       Kubernetes context to use"
        gum style "  -k, --kubeconfig FILE    Path to kubeconfig file"
        gum style "  -i, --interactive        Interactive pod/deployment selection with gum/fzf"
        gum style "  -m, --minimal            Minimal output (no pod/container prefix)"
        gum style "  -d, --debug              Enable debug mode"
        gum style "  -v, --version            Show version information"
        echo
        gum style --bold "Examples:"
        gum style "  kubectl klog                          # Interactive pod selection"
        gum style "  kubectl klog provider-nrf             # Logs from provider-nrf pods"
        gum style "  kubectl klog \"provider-nrf*\"          # Logs from all pods starting with provider-nrf"
        gum style "  kubectl klog -n crossplane-system     # All logs in crossplane-system namespace"
        gum style "  kubectl klog -n kube-system \"coredns\" # CoreDNS logs in kube-system"
        gum style "  kubectl klog -H \"error|Error|ERROR\"   # All logs, highlighting errors"
        gum style "  kubectl klog -x \"health|liveness\"     # All logs, excluding health checks"
        echo
        gum style --bold "Notes:"
        gum style "  * Wildcards must be quoted to prevent shell expansion"
        gum style "  * Requires stern to be installed (https://github.com/stern/stern)"
        if [[ "$USE_GUM" == "true" ]]; then
            gum style "  * Gum is installed, enabling enhanced UI features"
        else
            gum style "  * Gum is not installed. Install for enhanced UI: https://github.com/charmbracelet/gum"
        fi
    else
        cat <<EOF
${BOLD}kubectl-klog v${VERSION}${RESET} - Advanced Kubernetes log viewer

${BOLD}Usage:${RESET}
  kubectl klog [options] [PATTERN]

${BOLD}Arguments:${RESET}
  PATTERN                  Log selector pattern (glob/regex supported)
                          Examples: 
                          - "provider-nrf" (exact match)
                          - "provider-nrf*" (all pods starting with provider-nrf)
                          - "provider-nrf-[^r]" (all provider-nrf- pods except those with 'r')

${BOLD}Options:${RESET}
  -h, --help               Show this help message
  -n, --namespace NAME     Specify namespace (default: current namespace)
  -A, --all-namespaces     Search in all namespaces
  -c, --container NAME     Specify container name
  -l, --selector SELECTOR  Kubernetes selector
  -t, --tail LINES         Number of lines to show (default: ${TAIL})
  -s, --since DURATION     Show logs since duration (default: ${SINCE})
  -p, --previous           Show logs from previous container instance
  -T, --timestamps         Show timestamps in logs
  -H, --highlight PATTERN  Highlight pattern in logs (regexp supported)
  -x, --exclude PATTERN    Exclude pattern from logs (regexp supported)
  -C, --context NAME       Kubernetes context to use
  -k, --kubeconfig FILE    Path to kubeconfig file
  -i, --interactive        Interactive pod/deployment selection with fzf
  -m, --minimal            Minimal output (no pod/container prefix)
  -d, --debug              Enable debug mode
  -v, --version            Show version information

${BOLD}Examples:${RESET}
  kubectl klog                          # Interactive pod selection
  kubectl klog provider-nrf             # Logs from provider-nrf pods
  kubectl klog "provider-nrf*"          # Logs from all pods starting with provider-nrf
  kubectl klog -n crossplane-system     # All logs in crossplane-system namespace
  kubectl klog -n kube-system "coredns" # CoreDNS logs in kube-system
  kubectl klog -H "error|Error|ERROR"   # All logs, highlighting errors
  kubectl klog -x "health|liveness"     # All logs, excluding health checks

${BOLD}Notes:${RESET}
  * Wildcards must be quoted to prevent shell expansion
  * Requires stern to be installed (https://github.com/stern/stern)
  * Gum is not installed. Install for enhanced UI: https://github.com/charmbracelet/gum
EOF
    fi
}

show_version() {
    if [[ "$USE_GUM" == "true" ]]; then
        gum style --bold --foreground 6 "kubectl-klog v${VERSION}"
    else
        echo -e "${CYAN}kubectl-klog v${VERSION}${RESET}"
    fi
}

# Check dependencies
check_dependencies() {
    # Check for stern
    if ! command -v stern >/dev/null 2>&1; then
        styled_error "stern is required but not installed."
        styled_info "Please install stern: https://github.com/stern/stern"
        exit 1
    fi
    
    # Check for fzf if gum is not available and interactive mode is enabled
    if [[ "$USE_GUM" == "false" && "$INTERACTIVE" == "true" ]]; then
        if ! command -v fzf >/dev/null 2>&1; then
            styled_warning "fzf is required for interactive mode when gum is not available."
            styled_info "Please install fzf: https://github.com/junegunn/fzf"
            styled_info "Or install gum: https://github.com/charmbracelet/gum"
            INTERACTIVE=false
        fi
    fi
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

# Get available resources (pods/deployments)
get_resources() {
    local cmd
    
    if [[ -n "$NAMESPACE" ]]; then
        cmd="kubectl get pods,deployments -n $NAMESPACE -o custom-columns=KIND:.kind,NAME:.metadata.name,NAMESPACE:.metadata.namespace --no-headers"
    else
        cmd="kubectl get pods,deployments --all-namespaces -o custom-columns=KIND:.kind,NAME:.metadata.name,NAMESPACE:.metadata.namespace --no-headers"
    fi
    
    if [[ "$USE_GUM" == "true" ]]; then
        gum spin --spinner dot --title "Fetching resources..." -- bash -c "$cmd"
    else
        styled_info "Fetching resources..."
        eval "$cmd"
    fi
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
        
        if [[ "$USE_GUM" == "true" ]]; then
            echo "$name ($ns) - $kind"
        else
            if [[ "$kind" == "Pod" ]]; then
                echo -e "${GREEN}$name${RESET} (${BLUE}$ns${RESET}) - ${YELLOW}$kind${RESET}"
            else
                echo -e "${MAGENTA}$name${RESET} (${BLUE}$ns${RESET}) - ${YELLOW}$kind${RESET}"
            fi
        fi
    done)
    
    # Let user select resources
    local selection
    if [[ "$USE_GUM" == "true" ]]; then
        selection=$(echo "$formatted_resources" | gum choose --no-limit --height 20 --header "Select resources (space to select, enter to confirm)")
    else
        selection=$(echo "$formatted_resources" | fzf --ansi --multi --height=40% --border --header="Select resources (tab to multi-select)")
    fi
    
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
    
    # If no args and not interactive, show interactive mode
    if [[ -z "$PATTERN" && "$INTERACTIVE" == "false" ]]; then
        INTERACTIVE=true
    fi
    
    # Interactive selection
    if [[ "$INTERACTIVE" == "true" ]]; then
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
    if [[ "$USE_GUM" == "true" ]]; then
        gum style --foreground 6 --border normal --padding "0 1" "🔍 Tailing logs for: $PATTERN"
    else
        echo -e "${CYAN}🔍 Tailing logs for: $PATTERN${RESET}"
    fi
    
    # Execute
    eval "$STERN_CMD"
}

# Execute main
main "$@"