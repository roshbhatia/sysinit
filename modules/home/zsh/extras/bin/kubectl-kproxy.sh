#!/usr/bin/env bash
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all

# Default options
VERSION="1.0.0"
CACHE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/kproxy"
CADDY_FILE="$CACHE_DIR/Caddyfile"
FORWARDED_SERVICES_FILE="$CACHE_DIR/forwarded_services.json"
CADDY_PID_FILE="$CACHE_DIR/caddy.pid"
PROXY_PORT_START=10000
DEBUG=false

# Color definitions
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
RESET='\033[0m'

# This script requires kubectl, jq, caddy, and fzf to be installed

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

styled_filter() {
    echo -e "${CYAN}$1${RESET}"
    if command -v fzf >/dev/null 2>&1; then
        fzf
    else
        cat | head -20
    fi
}

styled_choose() {
    select opt in "$@"; do
        echo "$opt"
        break
    done
}

styled_input() {
    echo -e "${CYAN}$*${RESET}"
    read -r input
    echo "$input"
}

styled_logo() {
    echo -e "${CYAN}
888      .d888                  888 
888     d88P\"                   888 
888     888                     888 
888  888888888888  888  888 .d88888 
888 .88P888   888  888  888d88\" 888 
888888K 888   888  888  888888  888 
888 \"88b888   Y88b 888 d88PY88b 888 
888  888888    \"Y8888888P\"  \"Y88888 ${RESET}"
}

show_version() {
    echo -e "${CYAN}kubectl-kproxy v${VERSION}${RESET}"
}

show_help() {
    styled_logo
    
    echo
    echo -e "${BOLD}kubectl-kproxy v${VERSION}${RESET} - Advanced Kubernetes Service Port Forwarding with Caddy"
    echo
    echo -e "${BOLD}Usage:${RESET}"
    echo "  kubectl kproxy [command] [options]"
    echo
    echo -e "${BOLD}Commands:${RESET}"
    echo "  list, ls            List all services and select one to forward"
    echo "  forward, fwd        Forward a specific service"
    echo "  status, st          Show status of currently forwarded services"
    echo "  stop                Stop a specific port forward"
    echo "  stopall             Stop all port forwards"
    echo "  restart             Restart Caddy proxy server"
    echo "  help                Show this help message"
    echo
    echo -e "${BOLD}Options:${RESET}"
    echo "  -n, --namespace     Namespace of the service (for forward command)"
    echo "  -s, --service       Service name (for forward command)"
    echo "  -p, --port          Service port (for forward command)"
    echo "  -l, --local-port    Local port to use (default: auto-assigned)"
    echo "  -d, --domain        Custom domain for HTTPS access"
    echo "  --no-https          Disable HTTPS (use HTTP only)"
    echo "  --debug             Enable debug output"
    echo
    echo -e "${BOLD}Examples:${RESET}"
    echo "  kubectl kproxy                    # Interactive service selection"
    echo "  kubectl kproxy list               # List services and select one"
    echo "  kubectl kproxy fwd -n default -s my-service -p 8080  # Forward specific service"
    echo "  kubectl kproxy fwd -n default -s my-pod -p 8080 --type pod  # Forward specific pod"
    echo "  kubectl kproxy status             # Show forwarded services"
    echo "  kubectl kproxy stop my-service    # Stop forwarding my-service"
    echo
    echo -e "${BOLD}Notes:${RESET}"
    echo "  * Caddy is installed for HTTPS proxy with auto TLS"
}

# Check dependencies
check_dependencies() {
    # Required dependencies
    for cmd in kubectl jq caddy fzf; do
        if ! command -v $cmd >/dev/null 2>&1; then
            styled_error "$cmd is required but not installed."
            exit 1
        fi
    done
    
    # Create cache directory
    mkdir -p "$CACHE_DIR"
    
    # Initialize forwarded services file
    if [[ ! -f "$FORWARDED_SERVICES_FILE" ]]; then
        echo "[]" > "$FORWARDED_SERVICES_FILE"
    fi
}

# Find an available port starting from PROXY_PORT_START
find_available_port() {
    local port=$PROXY_PORT_START
    
    while nc -z localhost $port 2>/dev/null; do
        port=$((port + 1))
    done
    
    echo $port
}

# Generate a Caddyfile based on forwarded services
generate_caddyfile() {
    if command -v jq >/dev/null 2>&1; then
        # Start with an empty Caddyfile
        echo "" > "$CADDY_FILE"
        
        # Add an entry for each forwarded service with a domain
        jq -c '.[]' "$FORWARDED_SERVICES_FILE" | while read -r service; do
            local domain=$(echo "$service" | jq -r '.domain')
            local local_port=$(echo "$service" | jq -r '.local_port')
            local service_name=$(echo "$service" | jq -r '.service')
            
            if [[ -n "$domain" && "$domain" != "null" ]]; then
                echo "$domain {" >> "$CADDY_FILE"
                echo "  reverse_proxy localhost:$local_port" >> "$CADDY_FILE"
                echo "  log {" >> "$CADDY_FILE"
                echo "    output file $CACHE_DIR/$service_name.log" >> "$CADDY_FILE"
                echo "  }" >> "$CADDY_FILE"
                echo "}" >> "$CADDY_FILE"
                echo "" >> "$CADDY_FILE"
            fi
        done
    fi
}

# Start or restart Caddy
start_caddy() {
    # Only start Caddy if there's content in the Caddyfile
    if [[ -s "$CADDY_FILE" ]]; then
        # Stop existing Caddy if running
        if [[ -f "$CADDY_PID_FILE" ]]; then
            local pid=$(cat "$CADDY_PID_FILE")
            if ps -p "$pid" > /dev/null; then
                kill "$pid" 2>/dev/null || true
            fi
        fi
        
        # Start Caddy
        caddy run --config "$CADDY_FILE" --watch &
        local caddy_pid=$!
        
        # Save the PID
        echo "$caddy_pid" > "$CADDY_PID_FILE"
        
        styled_success "Caddy proxy server started"
    fi
}

# Show status of forwarded services
show_status() {
    styled_header "Current Port Forwards"
    
    if command -v jq >/dev/null 2>&1; then
        if [[ "$(jq 'length' "$FORWARDED_SERVICES_FILE")" == "0" ]]; then
            styled_info "No active port forwards."
            return 0
        fi
        
        echo -e "${BOLD}Service${RESET}\t${BOLD}Namespace${RESET}\t${BOLD}Type${RESET}\t${BOLD}Port${RESET}\t${BOLD}Local Port${RESET}\t${BOLD}Domain${RESET}\t${BOLD}Status${RESET}"
        
        jq -c '.[]' "$FORWARDED_SERVICES_FILE" | while read -r service; do
            local service_name=$(echo "$service" | jq -r '.service')
            local namespace=$(echo "$service" | jq -r '.namespace')
            local port=$(echo "$service" | jq -r '.port')
            local local_port=$(echo "$service" | jq -r '.local_port')
            local domain=$(echo "$service" | jq -r '.domain')
            local pid=$(echo "$service" | jq -r '.pid')
            local type=$(echo "$service" | jq -r '.type // "service"')
            
            # Check if the port-forward is still running
            local status="Running"
            if ! ps -p "$pid" > /dev/null; then
                status="Stopped"
            fi
            
            # Format for output
            domain=${domain:-"-"}
            
            echo -e "${GREEN}$service_name${RESET}\t${BLUE}$namespace${RESET}\t${YELLOW}$type${RESET}\t$port\t$local_port\t$domain\t$(status_color "$status")"
        done | column -t
    else
        styled_warning "jq is not installed, cannot show detailed status."
        styled_info "Running kubectl port-forwards:"
        ps aux | grep "kubectl port-forward" | grep -v grep
    fi
}

# Color status based on state
status_color() {
    local status="$1"
    
    if [[ "$status" == "Running" ]]; then
        echo -e "${GREEN}$status${RESET}"
    else
        echo -e "${RED}$status${RESET}"
    fi
}

# Remove a service from the forwarded services file
remove_forwarded_service() {
    local service="$1"
    
    if command -v jq >/dev/null 2>&1; then
        # Find the service PID to kill it
        local pid=$(jq -r --arg svc "$service" '.[] | select(.service == $svc) | .pid' "$FORWARDED_SERVICES_FILE")
        
        if [[ -n "$pid" && "$pid" != "null" ]]; then
            # Kill the port-forward process
            kill "$pid" 2>/dev/null || true
            styled_success "Stopped port-forward for $service"
        fi
        
        # Remove the service from the tracking file
        jq --arg svc "$service" 'map(select(.service != $svc))' "$FORWARDED_SERVICES_FILE" > "$FORWARDED_SERVICES_FILE.tmp"
        mv "$FORWARDED_SERVICES_FILE.tmp" "$FORWARDED_SERVICES_FILE"
    else
        styled_warning "jq is not installed, trying generic process killing."
        pkill -f "kubectl port-forward (service|pod)/$service" || true
    fi
}

# Stop a specific service
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
    generate_caddyfile
    start_caddy
    
    styled_success "Port forward for $service stopped."
}

# Restart Caddy
restart_caddy() {
    styled_header "Restarting Caddy Proxy Server"
    
    # Regenerate Caddyfile
    generate_caddyfile
    
    # Restart Caddy
    start_caddy
    
    styled_success "Caddy proxy server restarted."
}

# Get all services and pods from all namespaces
get_resources() {
    local cmd_services="kubectl get services --all-namespaces -o json"
    local cmd_pods="kubectl get pods --all-namespaces -o json"
    local services_json=""
    local pods_json=""
    
    styled_info "Fetching services..."
    services_json=$(eval "$cmd_services") || return 1
    
    styled_info "Fetching pods..."
    pods_json=$(eval "$cmd_pods") || return 1
    
    echo '{"services": '"$services_json"', "pods": '"$pods_json"'}'
}

# Format resources for display
format_resources() {
    local resources="$1"
    local formatted=""
    
    if command -v jq >/dev/null 2>&1; then
        # Format services
        local services=$(echo "$resources" | jq -r '.services.items[] | select(.spec.type != "ExternalName") | "service|\(.metadata.namespace)|\(.metadata.name)|\(.spec.ports[0].port)|\(.spec.ports[0].targetPort)|\(.spec.type)"')
        
        # Format pods
        local pods=$(echo "$resources" | jq -r '.pods.items[] | select(.status.phase == "Running") | "pod|\(.metadata.namespace)|\(.metadata.name)|-|-|\(.status.phase)"')
        
        # Combine and format both
        formatted=$(echo -e "${services}\n${pods}" | while IFS="|" read -r type namespace name port targetPort status; do
            if [[ "$type" == "service" ]]; then
                echo -e "${BLUE}Service${RESET}|${GREEN}$namespace${RESET}|${YELLOW}$name${RESET}|$port|$targetPort|${MAGENTA}$status${RESET}"
            else
                echo -e "${BLUE}Pod${RESET}|${GREEN}$namespace${RESET}|${YELLOW}$name${RESET}|-|-|${MAGENTA}$status${RESET}"
            fi
        done)
    else
        styled_warning "jq is not installed, falling back to basic output."
        formatted=$(kubectl get services,pods --all-namespaces -o custom-columns=TYPE:.kind,NAMESPACE:.metadata.namespace,NAME:.metadata.name,PORT:.spec.ports[0].port,TARGET:.spec.ports[0].targetPort,STATUS:.status.phase)
    fi
    
    echo "$formatted"
}

# List all resources and select one to forward
list_services() {
    local resources=$(get_resources)
    
    if [[ $? -ne 0 || -z "$resources" ]]; then
        styled_error "Error fetching resources. Please check your cluster connection."
        return 1
    fi
    
    styled_header "Select a Resource to Forward"
    
    local formatted_resources=$(format_resources "$resources")
    local selection=$(echo "$formatted_resources" | column -t -s "|" | styled_filter "Select a resource to forward:")
    
    if [[ -z "$selection" ]]; then
        styled_warning "No resource selected."
        return 0
    fi
    
    # Parse selection
    local type=""
    local namespace=""
    local name=""
    local port=""
    
    type=$(echo "$selection" | awk '{print $1}' | tr '[:upper:]' '[:lower:]')
    namespace=$(echo "$selection" | awk '{print $2}')
    name=$(echo "$selection" | awk '{print $3}')
    port=$(echo "$selection" | awk '{print $4}')
    
    # Trim whitespace
    type=$(echo "$type" | xargs)
    namespace=$(echo "$namespace" | xargs)
    name=$(echo "$name" | xargs)
    port=$(echo "$port" | xargs)
    
    if [[ "$type" == "pod" ]]; then
        # For pods, ask for the port
        if [[ -z "$port" || "$port" == "-" ]]; then
            port=$(styled_input "Enter port to forward for pod:")
            if [[ -z "$port" ]]; then
                styled_error "Port is required for pod forwarding."
                return 1
            fi
        fi
    fi
    
    # Ask for custom domain (optional)
    local domain=""
    if styled_confirm "Do you want to use a custom domain for this resource?"; then
        domain=$(styled_input "Enter domain (e.g., myapp.local):")
    fi
    
    # Set default local port if not specified
    local local_port=""
    if styled_confirm "Do you want to specify a local port? (default: auto-assigned)"; then
        local_port=$(styled_input "Enter local port:")
    fi
    
    # Forward the resource
    if [[ "$type" == "pod" ]]; then
        forward_pod "$namespace" "$name" "$port" "$local_port" "$domain"
    else
        forward_service "$namespace" "$name" "$port" "$local_port" "$domain"
    fi
}

# Forward a Kubernetes pod
forward_pod() {
    local namespace="$1"
    local pod="$2"
    local port="$3"
    local local_port="$4"
    local domain="$5"
    local use_https="true"
    
    # Check required parameters
    if [[ -z "$namespace" || -z "$pod" || -z "$port" ]]; then
        styled_error "Missing required parameters. Namespace, pod, and port are required."
        show_help
        exit 1
    fi
    
    # Find available local port if not specified
    if [[ -z "$local_port" ]]; then
        local_port=$(find_available_port)
    fi
    
    styled_header "Forwarding Pod: $pod.$namespace"
    styled_info "Pod: $pod"
    styled_info "Namespace: $namespace"
    styled_info "Port: $port → $local_port"
    
    if [[ -n "$domain" ]]; then
        styled_info "Domain: $domain"
    fi
    
    # Kill existing forwarding for this pod if any
    local existing_pid=$(jq -r --arg ns "$namespace" --arg pod "$pod" '.[] | select(.namespace == $ns and .service == $pod) | .pid' "$FORWARDED_SERVICES_FILE")
    
    if [[ -n "$existing_pid" && "$existing_pid" != "null" ]]; then
        kill "$existing_pid" 2>/dev/null || true
        styled_info "Stopped existing port-forward for $pod.$namespace"
    fi
    
    # Start port-forward
    kubectl port-forward "pod/$pod" -n "$namespace" "$local_port:$port" &
    local port_forward_pid=$!
    
    if [[ "$?" -ne 0 ]]; then
        styled_error "Failed to start port-forward."
        return 1
    fi
    
    # Add pod to tracked services
    add_forwarded_service "$namespace" "$pod" "$port" "$local_port" "$domain" "$use_https" "$port_forward_pid" "pod"
    
    # Setup monitor to detect if port-forward dies
    setup_monitor "$namespace" "$pod" "$port" "$local_port" "$port_forward_pid" "pod"
    
    # Generate Caddyfile and restart Caddy
    generate_caddyfile
    start_caddy
    
    # Display access URLs
    styled_header "Pod Access URLs"
    
    if [[ -n "$domain" ]]; then
        styled_success "HTTPS URL: https://$domain"
    fi
    
    styled_success "HTTP URL: http://localhost:$local_port"
    
    # Offer to open browser
    if styled_confirm "Open in browser now?"; then
        if [[ -n "$domain" ]]; then
            xdg-open "https://$domain" 2>/dev/null || open "https://$domain" 2>/dev/null || start "https://$domain" 2>/dev/null
        else
            xdg-open "http://localhost:$local_port" 2>/dev/null || open "http://localhost:$local_port" 2>/dev/null || start "http://localhost:$local_port" 2>/dev/null
        fi
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
    local existing_pid=$(jq -r --arg ns "$namespace" --arg svc "$service" '.[] | select(.namespace == $ns and .service == $svc) | .pid' "$FORWARDED_SERVICES_FILE")
    
    if [[ -n "$existing_pid" && "$existing_pid" != "null" ]]; then
        kill "$existing_pid" 2>/dev/null || true
        styled_info "Stopped existing port-forward for $service.$namespace"
    fi
    
    # Start port-forward (using service type)
    kubectl port-forward "service/$service" -n "$namespace" "$local_port:$port" &
    local port_forward_pid=$!
    
    if [[ "$?" -ne 0 ]]; then
        styled_error "Failed to start port-forward."
        return 1
    fi
    
    # Add service to tracked services
    add_forwarded_service "$namespace" "$service" "$port" "$local_port" "$domain" "$use_https" "$port_forward_pid" "service"
    
    # Setup monitor to detect if port-forward dies
    setup_monitor "$namespace" "$service" "$port" "$local_port" "$port_forward_pid" "service"
    
    # Generate Caddyfile and restart Caddy if needed
    generate_caddyfile
    start_caddy
    
    # Display access URLs
    styled_header "Service Access URLs"
    
    if [[ -n "$domain" ]]; then
        styled_success "HTTPS URL: https://$domain"
    fi
    
    styled_success "HTTP URL: http://localhost:$local_port"
    
    # Offer to open browser
    if styled_confirm "Open in browser now?"; then
        if [[ -n "$domain" ]]; then
            xdg-open "https://$domain" 2>/dev/null || open "https://$domain" 2>/dev/null || start "https://$domain" 2>/dev/null
        else
            xdg-open "http://localhost:$local_port" 2>/dev/null || open "http://localhost:$local_port" 2>/dev/null || start "http://localhost:$local_port" 2>/dev/null
        fi
    fi
}

# Add a forwarded service to the tracking file
add_forwarded_service() {
    local namespace="$1"
    local name="$2"
    local port="$3"
    local local_port="$4"
    local domain="$5"
    local use_https="$6"
    local pid="$7"
    local type="$8"
    
    cat "$FORWARDED_SERVICES_FILE" | jq --arg ns "$namespace" \
        --arg name "$name" \
        --arg port "$port" \
        --arg lport "$local_port" \
        --arg domain "$domain" \
        --arg https "$use_https" \
        --arg pid "$pid" \
        --arg type "$type" \
        '. + [{
            "namespace": $ns,
            "service": $name,
            "port": $port,
            "local_port": $lport,
            "domain": $domain,
            "use_https": $https,
            "pid": $pid,
            "type": $type
        }]' > "$FORWARDED_SERVICES_FILE.tmp"
    
    mv "$FORWARDED_SERVICES_FILE.tmp" "$FORWARDED_SERVICES_FILE"
}

# Stop all port forwards
stop_all() {
    styled_header "Stopping All Port Forwards"
    
    if command -v jq >/dev/null 2>&1; then
        local pids=$(cat "$FORWARDED_SERVICES_FILE" | jq -r '.[].pid')
        
        for pid in $pids; do
            if [[ -n "$pid" && "$pid" != "null" ]]; then
                kill "$pid" 2>/dev/null || true
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
        if ps -p "$pid" > /dev/null; then
            kill "$pid" 2>/dev/null || true
        fi
        rm "$CADDY_PID_FILE"
    fi
    
    styled_success "All port forwards stopped."
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
    local type="${6:-service}" # Default to service if not provided
    
    # Start a background monitor process
    (
        while true; do
            # Check if port-forward process is still running
            if ! ps -p "$pid" > /dev/null; then
                # Send notification about process termination
                send_notification "kubectl-kproxy" "Port forward for $service.$namespace stopped unexpectedly" "kubectl kproxy fwd -n $namespace -s $service -p $port -l $local_port"
                
                # Update service status
                if command -v jq >/dev/null 2>&1; then
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
    # Check dependencies first
    check_dependencies
    
    # If no arguments, run list_services
    if [[ $# -eq 0 ]]; then
        list_services
        exit $?
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
            --type)
                resource_type="$2"
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
            if [[ "$resource_type" == "pod" ]]; then
                forward_pod "$namespace" "$service" "$port" "$local_port" "$domain"
            else
                forward_service "$namespace" "$service" "$port" "$local_port" "$domain"
            fi
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
        version|-v|--version)
            show_version
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