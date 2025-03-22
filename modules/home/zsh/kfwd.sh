#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all

# 888      .d888                  888 
# 888     d88P"                   888 
# 888     888                     888 
# 888  888888888888  888  888 .d88888 
# 888 .88P888   888  888  888d88" 888 
# 888888K 888   888  888  888888  888 
# 888 "88b888   Y88b 888 d88PY88b 888 
# 888  888888    "Y8888888P"  "Y88888

# Helper functions defined outside the main function to avoid nesting
kfwd_list_services() {
    echo "Listing services..."
    services=$(kubectl get services --all-namespaces -o json | jq -r '.items[] | .metadata.namespace + " > " + .metadata.name + ":" + (.spec.ports[] | .port | tostring)')
    if [[ $? -ne 0 ]]; then
        echo "Failed to list services"
        return 1
    fi

    selected_service=$(echo "$services" | fzf --ansi --height=20)
    if [[ $? -ne 0 ]]; then
        echo "Failed to select service"
        return 1
    fi

    if [[ -n "$selected_service" ]]; then
        echo "Selected service: $selected_service"
        namespace=$(echo "$selected_service" | awk -F' > ' '{print $1}')
        service=$(echo "$selected_service" | awk -F' > ' '{print $2}' | awk -F':' '{print $1}')
        port=$(echo "$selected_service" | awk -F':' '{print $2}')
        echo "Namespace: $namespace, Service: $service, Port: $port"
        kfwd_forward_service "$namespace" "$service" "$port"
    else
        echo "No service selected."
    fi
}

kfwd_forward_service() {
    local namespace=$1
    local service=$2
    local port=$3
    local kill_flag=false
    local restart_flag=false

    echo "Forwarding service: Namespace=$namespace, Service=$service, Port=$port"

    while getopts "kr" opt; do
        case $opt in
            k)
                kill_flag=true
                ;;
            r)
                restart_flag=true
                kill_flag=true
                ;;
            *)
                echo "Invalid option: -$OPTARG" >&2
                return 1
                ;;
        esac
    done

    if $kill_flag; then
        echo "Killing existing port-forward..."
        pkill -f "kubectl port-forward service/$service -n $namespace"
        if [[ $? -ne 0 ]]; then
            echo "Failed to kill existing port-forward"
            return 1
        fi
    fi

    if $restart_flag || ! $kill_flag; then
        echo "Starting port-forward..."
        kubectl port-forward service/$service -n $namespace $port:$port &> /dev/null &
        if [[ $? -ne 0 ]]; then
            echo "Failed to start port-forward"
            return 1
        fi
        sleep 4  # Give port-forwarding some time to establish
        echo "Opening http://localhost:$port"
        open http://localhost:$port
        if [[ $? -ne 0 ]]; then
            echo "Failed to open browser"
            return 1
        fi
    fi
}

kfwd_show_help() {
    echo "888      .d888                  888 "
    echo "888     d88P\"                   888 "
    echo "888     888                     888 "
    echo "888  888888888888  888  888 .d88888 "
    echo "888 .88P888   888  888  888d88\" 888 "
    echo "888888K 888   888  888  888888  888 "
    echo "888 \"88b888   Y88b 888 d88PY88b 888 "
    echo "888  888888    \"Y8888888P\"  \"Y88888 "
    echo
    echo "Usage: kfwd {list|l|f|forward|h|help} [OPTIONS]"
    echo
    echo "Commands:"
    echo "  list, l          List all services and their ports"
    echo "  f, forward       Forward the selected service"
    echo "  h, help          Show this help message"
    echo
    echo "Options:"
    echo "  -k               Kill the existing port-forward"
    echo "  -r               Restart the port-forward"
}

# kfwd - Forward k8s service ports
function kfwd() {
    case "$1" in
        list|l)
            kfwd_list_services
            ;;
        f|forward)
            shift
            kfwd_forward_service "$@"
            ;;
        h|help)
            kfwd_show_help
            ;;
        *)
            kfwd_list_services
            ;;
    esac
}