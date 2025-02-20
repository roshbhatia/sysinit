#!/usr/bin/env zsh
# shellcheck disable=all

list_services() {
    services=$(kubectl get services --all-namespaces -o json | jq -r '.items[] | .metadata.namespace + " > " + .metadata.name + ":" + (.spec.ports[] | .port | tostring)')
    selected_service=$(echo "$services" | fzf --ansi --height=20)

    if [[ -n "$selected_service" ]]; then
        namespace=$(echo "$selected_service" | awk -F' > ' '{print $1}')
        service=$(echo "$selected_service" | awk -F' > ' '{print $2}' | awk -F':' '{print $1}')
        port=$(echo "$selected_service" | awk -F':' '{print $2}')
        forward_service "$namespace" "$service" "$port"
    fi
}

forward_service() {
    local namespace=$1
    local service=$2
    local port=$3
    local kill_flag=false
    local restart_flag=false

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
        pkill -f "kubectl port-forward service/$service -n $namespace"
    fi

    if $restart_flag || ! $kill_flag; then
        kubectl port-forward service/$service -n $namespace $port:$port &> /dev/null &
        sleep 4  # Give port-forwarding some time to establish
        open http://localhost:$port
    fi
}

show_help() {
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

kfwd() {
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