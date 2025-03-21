#!/usr/bin/env zsh
# shellcheck disable=all

# kfwd - Forward k8s service ports
function kfwd() {
    function list_services() {
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
            forward_service "$namespace" "$service" "$port"
        else
            echo "No service selected."
        fi
    }

    function forward_service() {
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

    function show_help() {
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

    case "$1" in
        list|l)
            list_services
            ;;
        f|forward)
            shift
            forward_service "$@"
            ;;
        h|help)
            show_help
            ;;
        *)
            list_services
            ;;
    esac
}