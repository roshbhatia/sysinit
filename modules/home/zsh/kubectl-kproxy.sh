#!/usr/bin/env bash
# kubectl-kproxy: Advanced Kubernetes Service Port Forwarding with Caddy
# Install in PATH as 'kubectl-kproxy' to use as 'kubectl kproxy'

# 888      .d888                  888 
# 888     d88P"                   888 
# 888     888                     888 
# 888  888888888888  888  888 .d88888 
# 888 .88P888   888  888  888d88" 888 
# 888888K 888   888  888  888888  888 
# 888 "88b888   Y88b 888 d88PY88b 888 
# 888  888888    "Y8888888P"  "Y88888

# Default options
VERSION="1.0.0"
CACHE_DIR="$HOME/.kproxy"
CADDY_FILE="$CACHE_DIR/Caddyfile"
FORWARDED_SERVICES_FILE="$CACHE_DIR/forwarded_services.json"
CADDY_PID_FILE="$CACHE_DIR/caddy.pid"
PROXY_PORT_START=10000
DEBUG=false

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

# Check for jq and set USE_JQ flag
if command -v jq >/dev/null 2>&1; then
    USE_JQ=true
else
    USE_JQ=false
fi

# Check for caddy and set USE_CADDY flag
if command -v caddy >/dev/null 2>&1; then
    USE_CADDY=true
else
    USE_CADDY=false
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
        gum spin --spinner dot --title "$1" -- bash -c "$2"
    else
        echo -e "${BLUE}⏳ $1${RESET}"
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
888      .d888                  888 
888     d88P\"                   888 
888     888                     888 
888  888888888888  888  888 .d88888 
888 .88P888   888  888  888d88\" 888 
888888K 888   888  888  888888  888 
888 \"88b888   Y88b 888 d88PY88b 888 
888  888888    \"Y8888888P\"  \"Y88888 "
    else
        echo -e "${CYAN}
888      .d888                  888 
888     d88P\"                   888 
888     888                     888 
888  888888888888  888  888 .d88888 
888 .88P888   888  888  888d88\" 888 
888888K 888   888  888  888888  888 
888 \"88b888   Y88b 888 d88PY88b 888 
888  888888    \"Y8888888P\"  \"Y88888 ${RESET}"
    fi
}

show_help() {
    styled_logo
    
    if [[ "$USE_GUM" == "true" ]]; then
        echo
        gum style --bold "kubectl-kproxy v${VERSION}" -- "Advanced Kubernetes Service Port Forwarding with Caddy"
        echo
        gum style --bold "Usage:"
        echo "  kubectl kproxy [command] [options]"
        echo
        gum style --bold "Commands:"
        gum style "  list, ls            List all services and select one to forward"
        gum style "  forward, fwd        Forward a specific service"
        gum style "  status, st          Show status of currently forwarded services"
        gum style "  stop                Stop a specific port forward"
        gum style "  stopall             Stop all port forwards"
        gum style "  restart             Restart Caddy proxy server"
        gum style "  help                Show this help message"
        echo
        gum style --bold "Options:"
        gum style "  -n, --namespace     Namespace of the service (for forward command)"
        gum style "  -s, --service       Service name (for forward command)"
        gum style "  -p, --port          Service port (for forward command)"
        gum style "  -l, --local-port    Local port to use (default: auto-assigned)"
        gum style "  -d, --domain        Custom domain for HTTPS access"
        gum style "  --no-https          Disable HTTPS (use HTTP only)"
        gum style "  --debug             Enable debug output"
        echo
        gum style --bold "Examples:"
        gum style "  kubectl kproxy                    # Interactive service selection"
        gum style "  kubectl kproxy list               # List services and select one"
        gum style "  kubectl kproxy fwd -n default -s my-service -p 8080  # Forward specific service"
        gum style "  kubectl kproxy status             # Show forwarded services"
        gum style "  kubectl kproxy stop my-service    # Stop forwarding my-service"
        echo
        gum style --bold "Notes:"
        if [[ "$USE_CADDY" == "true" ]]; then
            gum style "  * Caddy is installed for HTTPS proxy with auto TLS"
        else
            gum style "  * Caddy is not installed. Install for HTTPS: https://caddyserver.com/docs/install"
        fi
        if [[ "$USE_GUM" == "true" ]]; then
            gum style "  * Gum is installed, enabling enhanced UI features"
        else
            gum style "  * Gum is not installed. Install for enhanced UI: https://github.com/charmbracelet/gum"
        fi
    else
        cat <<EOF
${BOLD}kubectl-kproxy v${VERSION}${RESET} - Advanced Kubernetes Service Port Forwarding with Caddy

${BOLD}Usage:${RESET}
  kubectl kproxy [command] [options]

${BOLD}Commands:${RESET}
  list, ls            List all services and select one to forward
  forward, fwd        Forward a specific service
  status, st          Show status of currently forwarded services
  stop                Stop a specific port forward
  stopall             Stop all port forwards
  restart             Restart Caddy proxy server
  help                Show this help message

${BOLD}Options:${RESET}
  -n, --namespace     Namespace of the service (for forward command)
  -s, --service       Service name (for forward command)
  -p, --port          Service port (for forward command)
  -l, --local-port    Local port to use (default: auto-assigned)
  -d, --domain        Custom domain for HTTPS access
  --no-https          Disable HTTPS (use HTTP only)
  --debug             Enable debug output

${BOLD}Examples:${RESET}
  kubectl kproxy                    # Interactive service selection
  kubectl kproxy list               # List services and select one
  kubectl kproxy fwd -n default -s my-service -p 8080  # Forward specific service
  kubectl kproxy status             # Show forwarded services
  kubectl kproxy stop my-service    # Stop forwarding my-service

${BOLD}Notes:${RESET}
  * Requires kubectl, fzf, and jq
EOF
        if [[ "$USE_CADDY" == "true" ]]; then
            echo "  * Caddy is installed for HTTPS proxy with auto TLS"
        else
            echo "  * Caddy is not installed. Install for HTTPS: https://caddyserver.com/docs/install"
        fi
    fi
}

# Check dependencies
check_dependencies() {
    if ! command -v kubectl >/dev/null 2>&1; then
        styled_error "kubectl is required but not installed."
        exit 1
    fi
    
    if ! command -v fzf >/dev/null 2>&1; then
        styled_warning "fzf is not installed. This tool works best with fzf for interactive selection."
        styled_info "Please install fzf: https://github.com/junegunn/fzf"
    fi
    
    if [[ "$USE_JQ" == "false" ]]; then
        styled_warning "jq is not installed. Some features may not work correctly."
        styled_info "Please install jq: https://stedolan.github.io/jq/download/"
    fi
    
    if [[ "$USE_CADDY" == "false" ]]; then
        styled_warning "Caddy is not installed. HTTPS features will be disabled."
        styled_info "Please install Caddy for HTTPS with auto TLS: https://caddyserver.com/docs/install"
    fi
    
    # Create cache directory
    if [[ ! -d "$CACHE_DIR" ]]; then
        mkdir -p "$CACHE_DIR"
    fi
    
    # Initialize forwarded services file
    if [[ ! -f "$FORWARDED_SERVICES_FILE" ]]; then
        echo "[]" > "$FORWARDED_SERVICES_FILE"
    fi
}

# Get all services from all namespaces
get_services() {
    local cmd="kubectl get services --all-namespaces -o json"
    local services
    
    if [[ "$USE_GUM" == "true" ]]; then
        services=$(gum spin --spinner dot --title "Fetching services..." -- bash -c "$cmd")
    else
        styled_info "Fetching services..."
        services=$(eval "$cmd")
    fi
    
    echo "$services"
}

# Format services for display
format_services() {
    local services="$1"
    local formatted_services=""
    
    if [[ "$USE_JQ" == "true" ]]; then
        formatted_services=$(echo "$services" | jq -r '.items[] | select(.spec.type != "ExternalName") | "\(.metadata.namespace)|\(.metadata.name)|\(.spec.ports[0].port)|\(.spec.ports[0].targetPort)|\(.spec.type)"' | while IFS="|" read -r namespace name port targetPort type; do
            if [[ "$USE_GUM" == "true" ]]; then
                echo "$namespace|$name|$port|$targetPort|$type"
            else
                echo -e "${BLUE}$namespace${RESET} | ${GREEN}$name${RESET} | ${YELLOW}$port${RESET} | $targetPort | ${MAGENTA}$type${RESET}"
            fi
        done)
    else
        styled_warning "jq is not installed, falling back to basic output."
        formatted_services=$(kubectl get services --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,PORT:.spec.ports[0].port,TARGET:.spec.ports[0].targetPort,TYPE:.spec.type)
    fi
    
    echo "$formatted_services"
}

# List all services and select one to forward
list_services() {
    local services=$(get_services)
    
    if [[ -z "$services" ]]; then
        styled_error "No services found or error fetching services."
        exit 1
    fi
    
    styled_header "Select a Service to Forward"
    
    local formatted_services=$(format_services "$services")
    local selection=""
    
    if [[ "$USE_GUM" == "true" ]]; then
        selection=$(echo "$formatted_services" | column -t -s "|" | styled_filter "Select a service to forward:")
    else
        selection=$(echo "$formatted_services" | styled_filter "Select a service to forward:")
    fi
    
    if [[ -z "$selection" ]]; then
        styled_warning "No service selected."
        exit 0
    fi
    
    # Parse selection
    local namespace=""
    local service=""
    local port=""
    
    if [[ "$USE_JQ" == "true" ]]; then
        namespace=$(echo "$selection" | awk -F'|' '{print $1}')
        service=$(echo "$selection" | awk -F'|' '{print $2}')
        port=$(echo "$selection" | awk -F'|' '{print $3}')
    else
        namespace=$(echo "$selection" | awk '{print $1}')
        service=$(echo "$selection" | awk '{print $2}')
        port=$(echo "$selection" | awk '{print $3}')
    fi
    
    # Trim whitespace
    namespace=$(echo "$namespace" | xargs)
    service=$(echo "$service" | xargs)
    port=$(echo "$port" | xargs)
    
    # Ask for custom domain (optional)
    local domain=""
    if styled_confirm "Do you want to use a custom domain for this service?"; then
        domain=$(styled_input "Enter domain (e.g., myapp.local):")
    fi
    
    # Set default local port if not specified
    local local_port=""
    if styled_confirm "Do you want to specify a local port? (default: auto-assigned)"; then
        local_port=$(styled_input "Enter local port:")
    fi
    
    # Forward the service
    forward_service "$namespace" "$service" "$port" "$local_port" "$domain"
}

# Find available local port
find_available_port() {
    local start_port=${1:-$PROXY_PORT_START}
    local port=$start_port
    
    while netstat -tuln | grep -q ":$port "; do
        port=$((port + 1))
    done
    
    echo $port
}

# Generate Caddyfile
generate_caddyfile() {
    if [[ "$USE_CADDY" == "false" ]]; then
        return
    fi
    
    if [[ ! -f "$FORWARDED_SERVICES_FILE" ]]; then
        echo "[]" > "$FORWARDED_SERVICES_FILE"
    fi
    
    local services=$(cat "$FORWARDED_SERVICES_FILE")
    
    # Start with empty Caddyfile
    echo "# Generated by kubectl-kproxy" > "$CADDY_FILE"
    echo "{" >> "$CADDY_FILE"
    echo "  admin off" >> "$CADDY_FILE"
    echo "  local_certs" >> "$CADDY_FILE"
    echo "}" >> "$CADDY_FILE"
    echo "" >> "$CADDY_FILE"
    
    # Add each service to the Caddyfile
    if [[ "$USE_JQ" == "true" ]]; then
        echo "$services" | jq -c '.[]' | while read -r service_json; do
            local namespace=$(echo "$service_json" | jq -r '.namespace')
            local service_name=$(echo "$service_json" | jq -r '.service')
            local port=$(echo "$service_json" | jq -r '.port')
            local local_port=$(echo "$service_json" | jq -r '.localPort')
            local domain=$(echo "$service_json" | jq -r '.domain')
            local use_https=$(echo "$service_json" | jq -r '.useHttps')
            
            if [[ -n "$domain" && "$domain" != "null" && "$use_https" == "true" ]]; then
                # Domain with HTTPS
                echo "$domain {" >> "$CADDY_FILE"
                echo "  reverse_proxy localhost:$local_port" >> "$CADDY_FILE"
                echo "}" >> "$CADDY_FILE"
                echo "" >> "$CADDY_FILE"
            fi
            
            # Always add HTTP version at specific port
            echo "http://localhost:$local_port {" >> "$CADDY_FILE"
            echo "  respond \"kubectl-kproxy: $service_name.$namespace is available at this URL without a reverse proxy\"" >> "$CADDY_FILE"
            echo "}" >> "$CADDY_FILE"
            echo "" >> "$CADDY_FILE"
        done
    else
        styled_warning "jq is not installed. Caddyfile generation relies on jq. Install jq for full functionality."
    fi
}

# Start or restart Caddy
start_caddy() {
    if [[ "$USE_CADDY" == "false" ]]; then
        return
    fi
    
    # Stop existing Caddy process if running
    if [[ -f "$CADDY_PID_FILE" ]]; then
        local pid=$(cat "$CADDY_PID_FILE")
        if ps -p $pid > /dev/null; then
            kill $pid 2>/dev/null || true
        fi
        rm "$CADDY_PID_FILE"
    fi
    
    # Start Caddy if we have a Caddyfile
    if [[ -f "$CADDY_FILE" ]]; then
        caddy run --config "$CADDY_FILE" --adapter caddyfile &>/dev/null &
        echo $! > "$CADDY_PID_FILE"
        styled_success "Caddy proxy server started"
    fi
}

# Add service to forwarded services
add_forwarded_service() {
    local namespace="$1"
    local service="$2"
    local port="$3"
    local local_port="$4"
    local domain="$5"
    local use_https="${6:-true}"
    local pid="$7"
    
    if [[ "$USE_JQ" == "true" ]]; then
        # Check if service already exists
        local existing=$(cat "$FORWARDED_SERVICES_FILE" | jq -r --arg ns "$namespace" --arg svc "$service" '.[] | select(.namespace == $ns and .service == $svc) | .service')
        
        if [[ -n "$existing" ]]; then
            # Update existing service
            cat "$FORWARDED_SERVICES_FILE" | jq --arg ns "$namespace" --arg svc "$service" --arg port "$port" --arg lport "$local_port" --arg domain "$domain" --arg https "$use_https" --arg pid "$pid" '
                map(if .namespace == $ns and .service == $svc then
                    {
                        "namespace": $ns,
                        "service": $svc,
                        "port": $port,
                        "localPort": $lport,
                        "domain": $domain,
                        "useHttps": $https,
                        "pid": $pid
                    }
                else
                    .
                end)
            ' > "$FORWARDED_SERVICES_FILE.tmp"
        else
            # Add new service
            cat "$FORWARDED_SERVICES_FILE" | jq --arg ns "$namespace" --arg svc "$service" --arg port "$port" --arg lport "$local_port" --arg domain "$domain" --arg https "$use_https" --arg pid "$pid" '. + [
                {
                    "namespace": $ns,
                    "service": $svc,
                    "port": $port,
                    "localPort": $lport,
                    "domain": $domain,
                    "useHttps": $https,
                    "pid": $pid
                }
            ]' > "$FORWARDED_SERVICES_FILE.tmp"
        fi
        
        mv "$FORWARDED_SERVICES_FILE.tmp" "$FORWARDED_SERVICES_FILE"
    else
        styled_warning "jq is not installed. Service status tracking is limited."
    fi
}

# Remove service from forwarded services
remove_forwarded_service() {
    local service="$1"
    
    if [[ "$USE_JQ" == "true" ]]; then
        # Find PIDs to kill
        local pids=$(cat "$FORWARDED_SERVICES_FILE" | jq -r --arg svc "$service" '.[] | select(.service == $svc) | .pid')
        
        # Kill processes
        for pid in $pids; do
            if [[ -n "$pid" && "$pid" != "null" ]]; then
                kill $pid 2>/dev/null || true
            fi
        done
        
        # Remove service from JSON
        cat "$FORWARDED_SERVICES_FILE" | jq --arg svc "$service" '. | map(select(.service != $svc))' > "$FORWARDED_SERVICES_FILE.tmp"
        mv "$FORWARDED_SERVICES_FILE.tmp" "$FORWARDED_SERVICES_FILE"
    else
        styled_warning "jq is not installed. Cannot remove forwarded service from list."
        # Try to kill process based on port-forward pattern
        pkill -f "kubectl port-forward.*service/$service" || true
    fi
}

# Show status of forwarded services
show_status() {
    styled_header "Forwarded Services"
    
    if [[ "$USE_JQ" == "true" ]]; then
        local services=$(cat "$FORWARDED_SERVICES_FILE")
        local count=$(echo "$services" | jq 'length')
        
        if [[ "$count" -eq 0 ]]; then
            styled_info "No services are currently being forwarded."
            return
        fi
        
        local formatted_status=$(echo "$services" | jq -r '.[] | "\(.namespace)|\(.service)|\(.port)|\(.localPort)|\(.domain // "-")|\(.useHttps)"' | while IFS="|" read -r namespace service port local_port domain use_https; do
            local https_text="HTTP Only"
            if [[ "$use_https" == "true" && -n "$domain" && "$domain" != "-" ]]; then
                https_text="HTTPS Enabled"
            fi
            
            local urls=""
            if [[ -n "$domain" && "$domain" != "-" && "$use_https" == "true" ]]; then
                urls="https://$domain"
            else
                urls="http://localhost:$local_port"
            fi
            
            echo "$namespace|$service|$port|$local_port|$urls|$https_text"
        done)
        
        if [[ "$USE_GUM" == "true" ]]; then
            echo "$formatted_status" | column -t -s "|" | gum table
        else
            echo -e "${BOLD}NAMESPACE | SERVICE | PORT | LOCAL PORT | URLS | HTTPS${RESET}"
            echo "$formatted_status" | column -t -s "|"
        fi
    else
        styled_warning "jq is not installed. Cannot show detailed status."
        styled_info "Current port-forwards:"
        ps aux | grep "kubectl port-forward" | grep -v grep
    fi
}

# Forward a Kubernetes service
forward_service() {
    local namespace="$1"
    local service="$2"
    local port="$3"
    local local_port="$4"
    local domain="$5"
    local use_https="true"
    
    # Check required parameters
    if [[ -z "$namespace" || -z "$service" || -z "$port" ]]; then
        styled_error "Missing required parameters. Namespace, service, and port are required."
        show_help
        exit 1
    fi
    
    # Find available local port if not specified
    if [[ -z "$local_port" ]]; then
        local_port=$(find_available_port)
    fi
    
    styled_header "Forwarding Service: $service.$namespace"
    styled_info "Service: $service"
    styled_info "Namespace: $namespace"
    styled_info "Port: $port → $local_port"
    
    if [[ -n "$domain" ]]; then
        styled_info "Domain: $domain"
    fi
    
    # Kill existing forwarding for this service if any
    if [[ "$USE_JQ" == "true" ]]; then
        local existing_pid=$(cat "$FORWARDED_SERVICES_FILE" | jq -r --arg ns "$namespace" --arg svc "$service" '.[] | select(.namespace == $ns and .service == $svc) | .pid')
        
        if [[ -n "$existing_pid" && "$existing_pid" != "null" ]]; then
            kill $existing_pid 2>/dev/null || true
            styled_info "Stopped existing port-forward for $service.$namespace"
        fi
    else
        pkill -f "kubectl port-forward.*service/$service.*namespace=$namespace" || true
    fi
    
    # Start port-forward
    styled_spinner "Starting port-forward..." "kubectl port-forward service/$service -n $namespace $local_port:$port &"
    local port_forward_pid=$!
    
    if [[ "$?" -ne 0 ]]; then
        styled_error "Failed to start port-forward."
        return 1
    fi
    
    # Add service to tracked services
    add_forwarded_service "$namespace" "$service" "$port" "$local_port" "$domain" "$use_https" "$port_forward_pid"
    
    # Setup monitor to detect if port-forward dies
    setup_monitor "$namespace" "$service" "$port" "$local_port" "$port_forward_pid"
    
    # Generate Caddyfile and restart Caddy if needed
    if [[ "$USE_CADDY" == "true" ]]; then
        generate_caddyfile
        start_caddy
    fi
    
    # Display access URLs
    styled_header "Service Access URLs"
    
    if [[ -n "$domain" && "$USE_CADDY" == "true" ]]; then
        styled_success "HTTPS URL: https://$domain"
    fi
    
    styled_success "HTTP URL: http://localhost:$local_port"
    
    # Offer to open browser
    if styled_confirm "Open in browser now?"; then
        if [[ -n "$domain" && "$USE_CADDY" == "true" ]]; then
            xdg-open "https://$domain" 2>/dev/null || open "https://$domain" 2>/dev/null || start "https://$domain" 2>/dev/null
        else
            xdg-open "http://localhost:$local_port" 2>/dev/null || open "http://localhost:$local_port" 2>/dev/null || start "http://localhost:$local_port" 2>/dev/null
        fi
    fi
}

# Stop all port forwards
stop_all() {
    styled_header "Stopping All Port Forwards"
    
    if [[ "$USE_JQ" == "true" ]]; then
        local pids=$(cat "$FORWARDED_SERVICES_FILE" | jq -r '.[].pid')
        
        for pid in $pids; do
            if [[ -n "$pid" && "$pid" != "null" ]]; then
                kill $pid 2>/dev/null || true
            fi
        done
        
        # Clear services file
        echo "[]" > "$FORWARDED_SERVICES_FILE"
    else
        pkill -f "kubectl port-forward service/" || true
    fi
    
    # Stop Caddy
    if [[ -f "$CADDY_PID_FILE" ]]; then
        local pid=$(cat "$CADDY_PID_FILE")
        if ps -p $pid > /dev/null; then
            kill $pid 2>/dev/null || true
        fi
        rm "$CADDY_PID_FILE"
    fi
    
    styled_success "All port forwards stopped."
}

# Stop port forward for a specific service
stop_service() {
    local service="$1"
    
    if [[ -z "$service" ]]; then
        styled_error "No service specified."
        show_help
        exit 1
    fi
    
    styled_header "Stopping Port Forward for: $service"
    
    remove_forwarded_service "$service"
    
    # Regenerate Caddyfile and restart Caddy
    if [[ "$USE_CADDY" == "true" ]]; then
        generate_caddyfile
        start_caddy
    fi
    
    styled_success "Port forward for $service stopped."
}

# Restart Caddy
restart_caddy() {
    if [[ "$USE_CADDY" == "false" ]]; then
        styled_error "Caddy is not installed."
        return 1
    fi
    
    styled_header "Restarting Caddy Proxy Server"
    
    # Regenerate Caddyfile
    generate_caddyfile
    
    # Restart Caddy
    start_caddy
    
    styled_success "Caddy proxy server restarted."
}

# Check if terminal-notifier is available
has_terminal_notifier() {
    command -v terminal-notifier >/dev/null 2>&1
}

# Send a desktop notification
send_notification() {
    local title="$1"
    local message="$2"
    local command="$3"
    
    if has_terminal_notifier; then
        if [[ -n "$command" ]]; then
            terminal-notifier -title "$title" -message "$message" -execute "$command" -sound default
        else
            terminal-notifier -title "$title" -message "$message" -sound default
        fi
    elif command -v notify-send >/dev/null 2>&1; then
        # Linux fallback
        notify-send "$title" "$message"
    elif command -v osascript >/dev/null 2>&1; then
        # macOS fallback without terminal-notifier
        osascript -e "display notification \"$message\" with title \"$title\""
    fi
}

# Setup process monitoring
setup_monitor() {
    local namespace="$1"
    local service="$2"
    local port="$3"
    local local_port="$4"
    local pid="$5"
    
    # Start a background monitor process
    (
        while true; do
            # Check if port-forward process is still running
            if ! ps -p $pid > /dev/null; then
                # Send notification about process termination
                send_notification "kubectl-kproxy" "Port forward for $service.$namespace stopped unexpectedly" "kubectl kproxy fwd -n $namespace -s $service -p $port -l $local_port"
                
                # Update service status
                if [[ "$USE_JQ" == "true" ]]; then
                    # Mark service as stopped
                    cat "$FORWARDED_SERVICES_FILE" | jq --arg ns "$namespace" --arg svc "$service" '
                        map(if .namespace == $ns and .service == $svc then
                            .pid = "stopped"
                        else
                            .
                        end)
                    ' > "$FORWARDED_SERVICES_FILE.tmp"
                    mv "$FORWARDED_SERVICES_FILE.tmp" "$FORWARDED_SERVICES_FILE"
                fi
                
                break
            fi
            
            # Sleep for 5 seconds before checking again
            sleep 5
        done
    ) &
}

# Main function to parse arguments and handle commands
main() {
    # Parse command line arguments
    local command=""
    local namespace=""
    local service=""
    local port=""
    local local_port=""
    local domain=""
    local use_https=true
    
    # Check dependencies first
    check_dependencies
    
    # If no arguments, run list_services
    if [[ $# -eq 0 ]]; then
        list_services
        exit 0
    fi
    
    # Parse command
    command="$1"
    shift
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--namespace)
                namespace="$2"
                shift 2
                ;;
            -s|--service)
                service="$2"
                shift 2
                ;;
            -p|--port)
                port="$2"
                shift 2
                ;;
            -l|--local-port)
                local_port="$2"
                shift 2
                ;;
            -d|--domain)
                domain="$2"
                shift 2
                ;;
            --no-https)
                use_https=false
                shift
                ;;
            --debug)
                DEBUG=true
                shift
                ;;
            *)
                # Assume it's a service name for the stop command
                if [[ "$command" == "stop" && -z "$service" ]]; then
                    service="$1"
                else
                    styled_error "Unknown option: $1"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Execute command
    case "$command" in
        list|ls)
            list_services
            ;;
        forward|fwd)
            forward_service "$namespace" "$service" "$port" "$local_port" "$domain"
            ;;
        status|st)
            show_status
            ;;
        stop)
            stop_service "$service"
            ;;
        stopall)
            stop_all
            ;;
        restart)
            restart_caddy
            ;;
        help)
            show_help
            ;;
        *)
            styled_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"