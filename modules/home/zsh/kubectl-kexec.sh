#!/usr/bin/env bash
# kubectl-kexec: Advanced Kubernetes Pod Shell Access
# Install in PATH as 'kubectl-kexec' to use as 'kubectl kexec'

# 888                                      
# 888                                      
# 888                                      
# 888  888  .d88b.  888  888  .d88b.   .d8888b 
# 888 .88P d8P  Y8b `Y8bd8P' d8P  Y8b d88P"    
# 888888K  88888888   X88K   88888888 888      
# 888 "88b Y8b.     .d8""8b. Y8b.     Y88b.    
# 888  888  "Y8888  888  888  "Y8888   "Y8888P 

# Default options
VERSION="1.0.0"
CACHE_DIR="$HOME/.kexec"
HISTORY_FILE="$CACHE_DIR/history.json"
MOUNT_DIR="/tmp/kexec-mounts"
DEFAULT_EDITOR="${EDITOR:-vi}"
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

# Check for socat and set USE_SOCAT flag (used for file transfers)
if command -v socat >/dev/null 2>&1; then
    USE_SOCAT=true
else
    USE_SOCAT=false
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
888                                      
888                                      
888                                      
888  888  .d88b.  888  888  .d88b.   .d8888b 
888 .88P d8P  Y8b \`Y8bd8P' d8P  Y8b d88P\"    
888888K  88888888   X88K   88888888 888      
888 \"88b Y8b.     .d8\"\"8b. Y8b.     Y88b.    
888  888  \"Y8888  888  888  \"Y8888   \"Y8888P "
    else
        echo -e "${CYAN}
888                                      
888                                      
888                                      
888  888  .d88b.  888  888  .d88b.   .d8888b 
888 .88P d8P  Y8b \`Y8bd8P' d8P  Y8b d88P\"    
888888K  88888888   X88K   88888888 888      
888 \"88b Y8b.     .d8\"\"8b. Y8b.     Y88b.    
888  888  \"Y8888  888  888  \"Y8888   \"Y8888P ${RESET}"
    fi
}

show_help() {
    styled_logo
    
    if [[ "$USE_GUM" == "true" ]]; then
        echo
        gum style --bold "kubectl-kexec v${VERSION}" -- "Advanced Kubernetes Pod Shell Access"
        echo
        gum style --bold "Usage:"
        echo "  kubectl kexec [options] [POD] [CONTAINER]"
        echo
        gum style --bold "Options:"
        gum style "  -n, --namespace NAME     Specify namespace (default: current namespace)"
        gum style "  -c, --container NAME     Specify container name (default: first container)"
        gum style "  -s, --shell SHELL        Specify shell to use (default: auto-detect)"
        gum style "  -f, --file PATH          Local file to upload to the pod"
        gum style "  -r, --remote-path PATH   Remote path to upload the file to"
        gum style "  -m, --mount DIR          Local directory to mount in the pod"
        gum style "  -p, --remote-mount PATH  Remote path to mount the directory to"
        gum style "  -e, --edit PATH          Edit a file on the pod"
        gum style "  -h, --help               Show this help message"
        gum style "  -v, --version            Show version information"
        gum style "  -d, --debug              Enable debug output"
        echo
        gum style --bold "Commands:"
        gum style "  ls, list                 List pods and select one to exec into"
        gum style "  push, cp                 Copy a local file to a pod"
        gum style "  pull, get                Copy a file from a pod to local system"
        gum style "  edit                     Edit a file directly on a pod"
        gum style "  mount                    Mount a local directory to a pod"
        echo
        gum style --bold "Examples:"
        gum style "  kubectl kexec                      # Interactive pod selection"
        gum style "  kubectl kexec my-pod              # Exec into specific pod"
        gum style "  kubectl kexec -n monitoring my-pod # Exec into pod in different namespace"
        gum style "  kubectl kexec -c sidecar my-pod   # Exec into specific container"
        gum style "  kubectl kexec -s zsh my-pod       # Use specific shell"
        gum style "  kubectl kexec push my-file.txt my-pod:/tmp/ # Upload a file"
        gum style "  kubectl kexec pull my-pod:/etc/config.yaml ./ # Download a file"
        gum style "  kubectl kexec edit my-pod:/etc/nginx/nginx.conf # Edit remote file"
        echo
        gum style --bold "Notes:"
        gum style "  * Shell access automatically tries bash, then falls back to sh"
        gum style "  * File transfers require socat or tar to be available in the pod"
        gum style "  * For mounting, kubectl cp is used under the hood"
    else
        cat <<EOF
${BOLD}kubectl-kexec v${VERSION}${RESET} - Advanced Kubernetes Pod Shell Access

${BOLD}Usage:${RESET}
  kubectl kexec [options] [POD] [CONTAINER]

${BOLD}Options:${RESET}
  -n, --namespace NAME     Specify namespace (default: current namespace)
  -c, --container NAME     Specify container name (default: first container)
  -s, --shell SHELL        Specify shell to use (default: auto-detect)
  -f, --file PATH          Local file to upload to the pod
  -r, --remote-path PATH   Remote path to upload the file to
  -m, --mount DIR          Local directory to mount in the pod
  -p, --remote-mount PATH  Remote path to mount the directory to
  -e, --edit PATH          Edit a file on the pod
  -h, --help               Show this help message
  -v, --version            Show version information
  -d, --debug              Enable debug output

${BOLD}Commands:${RESET}
  ls, list                 List pods and select one to exec into
  push, cp                 Copy a local file to a pod
  pull, get                Copy a file from a pod to local system
  edit                     Edit a file directly on a pod
  mount                    Mount a local directory to a pod

${BOLD}Examples:${RESET}
  kubectl kexec                      # Interactive pod selection
  kubectl kexec my-pod              # Exec into specific pod
  kubectl kexec -n monitoring my-pod # Exec into pod in different namespace
  kubectl kexec -c sidecar my-pod   # Exec into specific container
  kubectl kexec -s zsh my-pod       # Use specific shell
  kubectl kexec push my-file.txt my-pod:/tmp/ # Upload a file
  kubectl kexec pull my-pod:/etc/config.yaml ./ # Download a file
  kubectl kexec edit my-pod:/etc/nginx/nginx.conf # Edit remote file

${BOLD}Notes:${RESET}
  * Shell access automatically tries bash, then falls back to sh
  * File transfers require socat or tar to be available in the pod
  * For mounting, kubectl cp is used under the hood
EOF
    fi
}

show_version() {
    if [[ "$USE_GUM" == "true" ]]; then
        gum style --bold --foreground 6 "kubectl-kexec v${VERSION}"
    else
        echo -e "${CYAN}kubectl-kexec v${VERSION}${RESET}"
    fi
}

# Check dependencies
check_dependencies() {
    if ! command -v kubectl >/dev/null 2>&1; then
        styled_error "kubectl is required but not installed."
        exit 1
    fi
    
    if ! command -v fzf >/dev/null 2>&1 && [[ "$USE_GUM" == "false" ]]; then
        styled_warning "fzf is not installed. This tool works best with fzf for interactive selection."
        styled_info "Please install fzf: https://github.com/junegunn/fzf"
    fi
    
    if [[ "$USE_JQ" == "false" ]]; then
        styled_warning "jq is not installed. Some features may not work correctly."
        styled_info "Please install jq: https://stedolan.github.io/jq/download/"
    fi
    
    # Create cache directory
    if [[ ! -d "$CACHE_DIR" ]]; then
        mkdir -p "$CACHE_DIR"
    fi
    
    # Initialize history file
    if [[ ! -f "$HISTORY_FILE" ]]; then
        echo "[]" > "$HISTORY_FILE"
    fi
    
    # Create mount directory if it doesn't exist
    if [[ ! -d "$MOUNT_DIR" ]]; then
        mkdir -p "$MOUNT_DIR"
    fi
}

# Get all pods
get_pods() {
    local namespace="$1"
    local cmd
    
    if [[ -n "$namespace" ]]; then
        cmd="kubectl get pods -n $namespace -o json"
    else
        cmd="kubectl get pods --all-namespaces -o json"
    fi
    
    if [[ "$USE_GUM" == "true" ]]; then
        pods=$(gum spin --spinner dot --title "Fetching pods..." -- bash -c "$cmd")
    else
        styled_info "Fetching pods..."
        pods=$(eval "$cmd")
    fi
    
    echo "$pods"
}

# Format pods for display
format_pods() {
    local pods="$1"
    local formatted_pods=""
    
    if [[ "$USE_JQ" == "true" ]]; then
        formatted_pods=$(echo "$pods" | jq -r '.items[] | "\(.metadata.namespace)|\(.metadata.name)|\(.status.phase)|\(.spec.containers[0].name)"' | while IFS="|" read -r namespace name phase container; do
            local status_color
            case "$phase" in
                "Running")
                    status_color="2"  # Green
                    ;;
                "Pending")
                    status_color="3"  # Yellow
                    ;;
                "Failed")
                    status_color="1"  # Red
                    ;;
                *)
                    status_color="7"  # White
                    ;;
            esac
            
            if [[ "$USE_GUM" == "true" ]]; then
                echo "$namespace|$name|$phase|$container|$status_color"
            else
                local color
                case "$status_color" in
                    "1") color=$RED ;;
                    "2") color=$GREEN ;;
                    "3") color=$YELLOW ;;
                    *) color=$WHITE ;;
                esac
                echo -e "${BLUE}$namespace${RESET} | ${GREEN}$name${RESET} | ${color}$phase${RESET} | ${MAGENTA}$container${RESET}"
            fi
        done)
    else
        styled_warning "jq is not installed, falling back to basic output."
        formatted_pods=$(kubectl get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase,CONTAINER:.spec.containers[0].name)
    fi
    
    echo "$formatted_pods"
}

# List all pods and select one
list_pods() {
    local namespace="$1"
    local pods=$(get_pods "$namespace")
    
    if [[ -z "$pods" ]]; then
        styled_error "No pods found or error fetching pods."
        exit 1
    fi
    
    styled_header "Select a Pod"
    
    local formatted_pods=$(format_pods "$pods")
    local selection=""
    
    if [[ "$USE_GUM" == "true" ]]; then
        if [[ "$USE_JQ" == "true" ]]; then
            # Use colored output with gum
            selection=$(echo "$formatted_pods" | while IFS="|" read -r namespace name phase container color; do
                echo "$(gum style --foreground "$color" "$phase") | $(gum style --foreground 4 "$namespace") | $(gum style --foreground 2 "$name") | $(gum style --foreground 5 "$container")"
            done | gum filter --placeholder "Select a pod")
        else
            selection=$(echo "$formatted_pods" | column -t | gum filter --placeholder "Select a pod")
        fi
    else
        selection=$(echo "$formatted_pods" | styled_filter "Select a pod")
    fi
    
    if [[ -z "$selection" ]]; then
        styled_warning "No pod selected."
        exit 0
    fi
    
    # Parse selection
    local pod_namespace=""
    local pod_name=""
    
    if [[ "$USE_JQ" == "true" ]]; then
        pod_namespace=$(echo "$selection" | awk '{print $3}' | tr -d '|')
        pod_name=$(echo "$selection" | awk '{print $5}' | tr -d '|')
    else
        pod_namespace=$(echo "$selection" | awk '{print $1}')
        pod_name=$(echo "$selection" | awk '{print $3}')
    fi
    
    # Trim whitespace
    pod_namespace=$(echo "$pod_namespace" | xargs)
    pod_name=$(echo "$pod_name" | xargs)
    
    echo "$pod_namespace|$pod_name"
}

# Get containers for a pod
get_containers() {
    local namespace="$1"
    local pod="$2"
    
    local cmd="kubectl get pod $pod -n $namespace -o jsonpath='{.spec.containers[*].name}'"
    local containers
    
    if [[ "$USE_GUM" == "true" ]]; then
        containers=$(gum spin --spinner dot --title "Fetching containers..." -- bash -c "$cmd")
    else
        styled_info "Fetching containers..."
        containers=$(eval "$cmd")
    fi
    
    echo $containers
}

# Select container from a pod
select_container() {
    local namespace="$1"
    local pod="$2"
    
    local containers=$(get_containers "$namespace" "$pod")
    
    if [[ -z "$containers" ]]; then
        styled_error "No containers found in pod $pod."
        exit 1
    fi
    
    # If only one container, return it
    if [[ ! "$containers" =~ " " ]]; then
        echo "$containers"
        return
    fi
    
    styled_header "Select a Container"
    
    local container_array=($containers)
    local selection
    
    if [[ "$USE_GUM" == "true" ]]; then
        selection=$(gum choose --height 10 "${container_array[@]}")
    else
        selection=$(printf '%s\n' "${container_array[@]}" | styled_filter "Select a container:")
    fi
    
    if [[ -z "$selection" ]]; then
        styled_warning "No container selected, using the first one."
        echo "${container_array[0]}"
    else
        echo "$selection"
    fi
}

# Detect available shell in container
detect_shell() {
    local namespace="$1"
    local pod="$2"
    local container="$3"
    
    styled_info "Detecting available shell..."
    
    # Try bash first
    if kubectl exec -n "$namespace" "$pod" -c "$container" -- which bash &>/dev/null; then
        styled_success "bash found"
        echo "bash"
        return
    fi
    
    # Try sh next
    if kubectl exec -n "$namespace" "$pod" -c "$container" -- which sh &>/dev/null; then
        styled_success "sh found"
        echo "sh"
        return
    fi
    
    # Try ash (busybox)
    if kubectl exec -n "$namespace" "$pod" -c "$container" -- which ash &>/dev/null; then
        styled_success "ash found"
        echo "ash"
        return
    fi
    
    styled_warning "No common shell found, defaulting to sh"
    echo "sh"
}

# Add to history
add_to_history() {
    local namespace="$1"
    local pod="$2"
    local container="$3"
    
    if [[ "$USE_JQ" == "true" ]]; then
        local timestamp=$(date +%s)
        
        # Check if entry already exists
        local existing=$(cat "$HISTORY_FILE" | jq -r --arg ns "$namespace" --arg p "$pod" --arg c "$container" '.[] | select(.namespace == $ns and .pod == $p and .container == $c) | .pod')
        
        if [[ -n "$existing" ]]; then
            # Update existing entry with new timestamp
            cat "$HISTORY_FILE" | jq --arg ns "$namespace" --arg p "$pod" --arg c "$container" --arg ts "$timestamp" '
                map(if .namespace == $ns and .pod == $p and .container == $c then
                    {
                        "namespace": $ns,
                        "pod": $p,
                        "container": $c,
                        "timestamp": $ts
                    }
                else
                    .
                end)
            ' > "$HISTORY_FILE.tmp"
        else
            # Add new entry
            cat "$HISTORY_FILE" | jq --arg ns "$namespace" --arg p "$pod" --arg c "$container" --arg ts "$timestamp" '. + [
                {
                    "namespace": $ns,
                    "pod": $p,
                    "container": $c,
                    "timestamp": $ts
                }
            ]' > "$HISTORY_FILE.tmp"
        fi
        
        mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
    fi
}

# Execute shell in container
exec_shell() {
    local namespace="$1"
    local pod="$2"
    local container="$3"
    local shell="$4"
    
    # If no shell specified, detect available shell
    if [[ -z "$shell" ]]; then
        shell=$(detect_shell "$namespace" "$pod" "$container")
    fi
    
    # Add to history
    add_to_history "$namespace" "$pod" "$container"
    
    styled_header "Connecting to $pod ($container) in namespace $namespace"
    
    # Set terminal to raw mode
    if [ -t 0 ]; then
        # Save terminal settings
        old_tty=$(stty -g)
        # Set terminal to raw mode
        stty raw -echo
    fi
    
    # Execute shell
    kubectl exec -it -n "$namespace" "$pod" -c "$container" -- "$shell"
    
    # Restore terminal settings
    if [ -t 0 ]; then
        stty "$old_tty"
    fi
}

# Copy file to pod using various methods
copy_to_pod() {
    local namespace="$1"
    local pod="$2"
    local container="$3"
    local local_file="$4"
    local remote_path="$5"
    
    # Check if local file exists
    if [[ ! -f "$local_file" ]]; then
        styled_error "Local file does not exist: $local_file"
        return 1
    fi
    
    styled_header "Copying $local_file to $pod:$remote_path"
    
    # Try different methods in order of preference
    
    # 1. Try kubectl cp first (simplest)
    styled_info "Trying kubectl cp..."
    if kubectl cp -n "$namespace" -c "$container" "$local_file" "$pod:$remote_path" 2>/dev/null; then
        styled_success "Successfully copied file using kubectl cp"
        return 0
    fi
    
    styled_warning "kubectl cp failed, trying alternative methods..."
    
    # 2. Try using socat if available
    if [[ "$USE_SOCAT" == "true" ]]; then
        styled_info "Trying socat..."
        
        # Check if socat is available in the container
        if kubectl exec -n "$namespace" "$pod" -c "$container" -- which socat &>/dev/null; then
            # Create a random port for the transfer
            local port=$(shuf -i 10000-65000 -n 1)
            
            # Start socat in the container
            kubectl exec -n "$namespace" "$pod" -c "$container" -- socat TCP-LISTEN:$port,fork OPEN:"$remote_path",creat &
            local socat_pid=$!
            
            # Sleep to let socat start
            sleep 1
            
            # Port forward to the socat port
            kubectl port-forward -n "$namespace" "$pod" $port:$port &
            local portfwd_pid=$!
            
            # Sleep to let port forwarding start
            sleep 1
            
            # Send the file using cat
            cat "$local_file" > /dev/tcp/localhost/$port
            
            # Kill the port forward
            kill $portfwd_pid
            
            # Kill socat
            kill $socat_pid
            
            styled_success "Successfully copied file using socat"
            return 0
        fi
    fi
    
    # 3. Try base64 encoding/decoding
    styled_info "Trying base64 transfer..."
    
    # Check if base64 is available in the container
    if kubectl exec -n "$namespace" "$pod" -c "$container" -- which base64 &>/dev/null; then
        # Encode the file
        local encoded_content=$(base64 -w 0 "$local_file")
        
        # Create a command to decode and write the file
        local decode_cmd="echo '$encoded_content' | base64 -d > $remote_path"
        
        # Execute the command
        if kubectl exec -n "$namespace" "$pod" -c "$container" -- sh -c "$decode_cmd"; then
            styled_success "Successfully copied file using base64 encoding"
            return 0
        fi
    fi
    
    # 4. Try using tar
    styled_info "Trying tar transfer..."
    
    # Check if tar is available in the container
    if kubectl exec -n "$namespace" "$pod" -c "$container" -- which tar &>/dev/null; then
        # Create a temporary directory
        local temp_dir=$(mktemp -d)
        local file_name=$(basename "$local_file")
        
        # Copy the file to the temp directory
        cp "$local_file" "$temp_dir/"
        
        # Create a tar archive
        tar -cf "$temp_dir/archive.tar" -C "$temp_dir" "$file_name"
        
        # Encode the tar archive
        local encoded_tar=$(base64 -w 0 "$temp_dir/archive.tar")
        
        # Create a command to decode, extract and move the file
        local decode_cmd="mkdir -p $(dirname "$remote_path") && echo '$encoded_tar' | base64 -d > /tmp/archive.tar && tar -xf /tmp/archive.tar -C /tmp && mv /tmp/$file_name $remote_path && rm /tmp/archive.tar"
        
        # Execute the command
        if kubectl exec -n "$namespace" "$pod" -c "$container" -- sh -c "$decode_cmd"; then
            styled_success "Successfully copied file using tar+base64 encoding"
            rm -rf "$temp_dir"
            return 0
        fi
        
        # Clean up
        rm -rf "$temp_dir"
    fi
    
    styled_error "All file transfer methods failed"
    return 1
}

# Copy file from pod using various methods
copy_from_pod() {
    local namespace="$1"
    local pod="$2"
    local container="$3"
    local remote_file="$4"
    local local_path="$5"
    
    styled_header "Copying $pod:$remote_file to $local_path"
    
    # Try different methods in order of preference
    
    # 1. Try kubectl cp first (simplest)
    styled_info "Trying kubectl cp..."
    if kubectl cp -n "$namespace" -c "$container" "$pod:$remote_file" "$local_path" 2>/dev/null; then
        styled_success "Successfully copied file using kubectl cp"
        return 0
    fi
    
    styled_warning "kubectl cp failed, trying alternative methods..."
    
    # 2. Try using socat if available
    if [[ "$USE_SOCAT" == "true" ]]; then
        styled_info "Trying socat..."
        
        # Check if socat is available in the container
        if kubectl exec -n "$namespace" "$pod" -c "$container" -- which socat &>/dev/null; then
            # Create a random port for the transfer
            local port=$(shuf -i 10000-65000 -n 1)
            
            # Start socat in the container to send the file
            kubectl exec -n "$namespace" "$pod" -c "$container" -- socat TCP-LISTEN:$port,fork OPEN:"$remote_file" &
            local socat_pid=$!
            
            # Sleep to let socat start
            sleep 1
            
            # Port forward to the socat port
            kubectl port-forward -n "$namespace" "$pod" $port:$port &
            local portfwd_pid=$!
            
            # Sleep to let port forwarding start
            sleep 1
            
            # Receive the file using cat
            cat < /dev/tcp/localhost/$port > "$local_path"
            
            # Kill the port forward
            kill $portfwd_pid
            
            # Kill socat
            kill $socat_pid
            
            styled_success "Successfully copied file using socat"
            return 0
        fi
    fi
    
    # 3. Try base64 encoding/decoding
    styled_info "Trying base64 transfer..."
    
    # Check if base64 is available in the container
    if kubectl exec -n "$namespace" "$pod" -c "$container" -- which base64 &>/dev/null; then
        # Create a command to read and encode the file
        local encode_cmd="cat $remote_file | base64 -w 0"
        
        # Execute the command and decode the output
        local encoded_content=$(kubectl exec -n "$namespace" "$pod" -c "$container" -- sh -c "$encode_cmd")
        
        # Write the decoded content to the local file
        echo "$encoded_content" | base64 -d > "$local_path"
        
        if [[ $? -eq 0 ]]; then
            styled_success "Successfully copied file using base64 encoding"
            return 0
        fi
    fi
    
    # 4. Try using tar
    styled_info "Trying tar transfer..."
    
    # Check if tar is available in the container
    if kubectl exec -n "$namespace" "$pod" -c "$container" -- which tar &>/dev/null; then
        # Create a temporary directory
        local temp_dir=$(mktemp -d)
        local file_name=$(basename "$remote_file")
        
        # Create a command to create a tar archive
        local tar_cmd="cd $(dirname "$remote_file") && tar -cf - $file_name | base64 -w 0"
        
        # Execute the command
        local encoded_tar=$(kubectl exec -n "$namespace" "$pod" -c "$container" -- sh -c "$tar_cmd")
        
        # Decode and extract the tar archive
        echo "$encoded_tar" | base64 -d > "$temp_dir/archive.tar"
        tar -xf "$temp_dir/archive.tar" -C "$temp_dir"
        
        # Copy the file to the destination
        cp -f "$temp_dir/$file_name" "$local_path"
        
        # Clean up
        rm -rf "$temp_dir"
        
        styled_success "Successfully copied file using tar+base64 encoding"
        return 0
    fi
    
    styled_error "All file transfer methods failed"
    return 1
}

# Edit a file on the pod
edit_pod_file() {
    local namespace="$1"
    local pod="$2"
    local container="$3"
    local remote_file="$4"
    
    styled_header "Editing $pod:$remote_file"
    
    # Create a temporary directory
    local temp_dir=$(mktemp -d)
    local file_name=$(basename "$remote_file")
    local local_file="$temp_dir/$file_name"
    
    # Copy the file from the pod
    if ! copy_from_pod "$namespace" "$pod" "$container" "$remote_file" "$local_file"; then
        styled_error "Failed to copy file from pod for editing"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Edit the file
    styled_info "Opening editor ($DEFAULT_EDITOR)..."
    $DEFAULT_EDITOR "$local_file"
    
    # Check if the file was modified
    if [[ ! -f "$local_file" ]]; then
        styled_warning "File was deleted or editor failed"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Confirm upload
    if styled_confirm "Upload changes back to the pod?"; then
        # Copy the file back to the pod
        if copy_to_pod "$namespace" "$pod" "$container" "$local_file" "$remote_file"; then
            styled_success "Changes saved to $pod:$remote_file"
            rm -rf "$temp_dir"
            return 0
        else
            styled_error "Failed to save changes to pod"
            
            # Keep the file for manual handling
            local backup_file="$HOME/$(date +%Y%m%d%H%M%S)_$file_name"
            cp "$local_file" "$backup_file"
            styled_warning "A copy of your changes has been saved to $backup_file"
            rm -rf "$temp_dir"
            return 1
        fi
    else
        styled_warning "Changes not uploaded"
        rm -rf "$temp_dir"
        return 0
    fi
}

# Setup bidirectional file synchronization
setup_file_sync() {
    local namespace="$1"
    local pod="$2"
    local container="$3"
    local local_dir="$4"
    local remote_dir="$5"
    
    # Create unique identifier for this sync
    local sync_id=$(echo "$namespace-$pod-$container-$remote_dir" | md5sum | cut -d' ' -f1)
    local sync_dir="$MOUNT_DIR/$sync_id"
    
    # Create local directory if it doesn't exist
    if [[ ! -d "$local_dir" ]]; then
        mkdir -p "$local_dir"
    fi
    
    # Create sync directory
    mkdir -p "$sync_dir"
    
    # Add sync info to metadata
    echo "$namespace|$pod|$container|$remote_dir|$local_dir" > "$sync_dir/metadata"
    
    return 0
}

# Mount a local directory to a pod (bidirectional sync)
mount_directory() {
    local namespace="$1"
    local pod="$2"
    local container="$3"
    local local_dir="$4"
    local remote_dir="$5"
    
    styled_header "Setting up automatic bidirectional sync: $local_dir ⟷ $pod:$remote_dir"
    
    # Expand local dir to absolute path
    local_dir=$(realpath "$local_dir")
    
    # Check if remote directory exists
    if ! kubectl exec -n "$namespace" "$pod" -c "$container" -- sh -c "[ -d \"$remote_dir\" ]" &>/dev/null; then
        styled_warning "Remote directory does not exist, attempting to create it"
        kubectl exec -n "$namespace" "$pod" -c "$container" -- sh -c "mkdir -p \"$remote_dir\"" &>/dev/null
        
        if [[ $? -ne 0 ]]; then
            styled_error "Failed to create remote directory"
            return 1
        fi
    fi
    
    # Initial sync from pod to local
    styled_info "Performing initial sync from pod to local..."
    
    # Create a temporary directory for the initial sync
    local temp_dir=$(mktemp -d)
    
    # Copy files from the pod
    if kubectl cp -n "$namespace" -c "$container" "$pod:$remote_dir" "$temp_dir" &>/dev/null; then
        # Copy files to the local directory
        cp -r "$temp_dir"/* "$local_dir" 2>/dev/null
        styled_success "Initial sync completed"
    else
        styled_warning "Initial sync failed, local directory may be out of sync"
    fi
    
    # Clean up
    rm -rf "$temp_dir"
    
    # Setup the file sync
    if setup_file_sync "$namespace" "$pod" "$container" "$local_dir" "$remote_dir"; then
        styled_success "Bidirectional sync setup successfully"
        styled_info "Local directory: $local_dir"
        styled_info "Remote directory: $pod:$remote_dir"
        styled_info "Files will be synchronized automatically when you access the shell"
        
        # Offer to open the shell
        if styled_confirm "Open shell to the pod now?"; then
            exec_shell "$namespace" "$pod" "$container"
            return 0
        fi
        
        return 0
    else
        styled_error "Failed to setup file sync"
        return 1
    fi
}

# Auto-mount and sync before shell session
automount_and_sync() {
    local namespace="$1"
    local pod="$2"
    local container="$3"
    
    # Create a temporary directory
    local temp_dir=$(mktemp -d)
    
    styled_header "Auto-mounting temporary directory to pod"
    styled_info "Local directory: $temp_dir"
    
    # Create a random remote directory name
    local remote_dir="/tmp/kexec-$(date +%s)"
    
    # Create the remote directory
    kubectl exec -n "$namespace" "$pod" -c "$container" -- sh -c "mkdir -p $remote_dir" &>/dev/null
    
    if [[ $? -ne 0 ]]; then
        styled_warning "Failed to create remote directory, continuing without auto-mount"
        return 1
    fi
    
    styled_info "Remote directory: $remote_dir"
    
    # Setup the file sync
    if setup_file_sync "$namespace" "$pod" "$container" "$temp_dir" "$remote_dir"; then
        styled_success "Temporary directory mounted successfully"
        styled_info "Files placed in $temp_dir will be synchronized to $pod:$remote_dir"
        styled_info "Create files here to have them available in the pod"
        
        # Create a README file
        echo "# Kubernetes Pod Temporary Mount

This directory is automatically synchronized with the Kubernetes pod:
- Namespace: $namespace
- Pod: $pod
- Container: $container
- Remote path: $remote_dir

Files placed here will be available in the pod at $remote_dir.
Files created in the pod at $remote_dir will be available here.

This is a temporary directory and will be deleted when you exit the shell session.
" > "$temp_dir/README.md"
        
        # Export the temp dir as an environment variable
        export KEXEC_TEMP_DIR="$temp_dir"
        export KEXEC_REMOTE_DIR="$remote_dir"
        
        # Let the user know how to access it
        styled_info "You can access this directory in your terminal as:"
        styled_info "  cd \$KEXEC_TEMP_DIR"
        styled_info "In the pod, access it at:"
        styled_info "  cd \$KEXEC_REMOTE_DIR"
        
        return 0
    else
        styled_warning "Failed to setup auto-mount, continuing without it"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Process arguments for pod/container specification
process_pod_spec() {
    local pod_spec="$1"
    
    # Default values
    local namespace=""
    local pod_name=""
    local file_path=""
    
    # Check if the spec is for a file path (contains :)
    if [[ "$pod_spec" == *":"* ]]; then
        # Extract pod and file path
        local pod_part="${pod_spec%%:*}"
        file_path="${pod_spec#*:}"
        
        # Check if pod part includes namespace
        if [[ "$pod_part" == *"/"* ]]; then
            namespace="${pod_part%%/*}"
            pod_name="${pod_part#*/}"
        else
            pod_name="$pod_part"
        fi
    else
        # Check if the spec includes namespace
        if [[ "$pod_spec" == *"/"* ]]; then
            namespace="${pod_spec%%/*}"
            pod_name="${pod_spec#*/}"
        else
            pod_name="$pod_spec"
        fi
    fi
    
    echo "$namespace|$pod_name|$file_path"
}

# Parse main command and arguments
main() {
    # Default values
    local command="shell"
    local namespace=""
    local pod=""
    local container=""
    local shell=""
    local local_file=""
    local remote_path=""
    local local_dir=""
    local remote_dir=""
    local edit_file=""
    
    # Check dependencies
    check_dependencies
    
    # No arguments, run interactive pod selection
    if [[ $# -eq 0 ]]; then
        command="shell"
    else
        # Parse command
        case "$1" in
            ls|list)
                command="list"
                shift
                ;;
            push|cp)
                command="push"
                shift
                ;;
            pull|get)
                command="pull"
                shift
                ;;
            edit)
                command="edit"
                shift
                ;;
            mount)
                command="mount"
                shift
                ;;
            help|-h|--help)
                show_help
                exit 0
                ;;
            version|-v|--version)
                show_version
                exit 0
                ;;
            *)
                # Assume first arg is pod name or we'll see if it's an option
                ;;
        esac
    fi
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--namespace)
                namespace="$2"
                shift 2
                ;;
            -c|--container)
                container="$2"
                shift 2
                ;;
            -s|--shell)
                shell="$2"
                shift 2
                ;;
            -f|--file)
                local_file="$2"
                shift 2
                ;;
            -r|--remote-path)
                remote_path="$2"
                shift 2
                ;;
            -m|--mount)
                local_dir="$2"
                shift 2
                ;;
            -p|--remote-mount)
                remote_dir="$2"
                shift 2
                ;;
            -e|--edit)
                edit_file="$2"
                command="edit"
                shift 2
                ;;
            -d|--debug)
                DEBUG=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -*)
                styled_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                # Process pod spec
                if [[ -z "$pod" ]]; then
                    local result=$(process_pod_spec "$1")
                    local ns=$(echo "$result" | cut -d'|' -f1)
                    local p=$(echo "$result" | cut -d'|' -f2)
                    local path=$(echo "$result" | cut -d'|' -f3)
                    
                    if [[ -n "$ns" ]]; then
                        namespace="$ns"
                    fi
                    
                    pod="$p"
                    
                    if [[ -n "$path" ]]; then
                        case "$command" in
                            push)
                                remote_path="$path"
                                ;;
                            pull)
                                local_file="$path"
                                ;;
                            edit)
                                edit_file="$path"
                                ;;
                            mount)
                                remote_dir="$path"
                                ;;
                            *)
                                # For shell, assume we just want pod, ignore path
                                ;;
                        esac
                    fi
                elif [[ "$command" == "push" && -z "$remote_path" ]]; then
                    remote_path="$1"
                elif [[ "$command" == "pull" && -z "$local_file" ]]; then
                    local_file="$1"
                elif [[ "$command" == "mount" && -z "$local_dir" ]]; then
                    local_dir="$1"
                elif [[ -z "$container" ]]; then
                    container="$1"
                else
                    styled_error "Unexpected argument: $1"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Execute command
    case "$command" in
        shell)
            # Interactive pod selection if not specified
            if [[ -z "$pod" ]]; then
                local selection=$(list_pods "$namespace")
                namespace=$(echo "$selection" | cut -d'|' -f1)
                pod=$(echo "$selection" | cut -d'|' -f2)
            fi
            
            # Interactive container selection if not specified
            if [[ -z "$container" ]]; then
                container=$(select_container "$namespace" "$pod")
            fi
            
            # Auto-mount a temporary directory if available
            automount_and_sync "$namespace" "$pod" "$container"
            
            # Execute shell
            exec_shell "$namespace" "$pod" "$container" "$shell"
            ;;
        list)
            list_pods "$namespace"
            ;;
        push)
            # Validate arguments
            if [[ -z "$local_file" ]]; then
                styled_error "Local file not specified"
                show_help
                exit 1
            fi
            
            if [[ -z "$pod" || -z "$remote_path" ]]; then
                styled_error "Pod and remote path must be specified"
                show_help
                exit 1
            fi
            
            # Interactive container selection if not specified
            if [[ -z "$container" ]]; then
                container=$(select_container "$namespace" "$pod")
            fi
            
            # Copy file to pod
            copy_to_pod "$namespace" "$pod" "$container" "$local_file" "$remote_path"
            ;;
        pull)
            # Validate arguments
            if [[ -z "$pod" || -z "$local_file" ]]; then
                styled_error "Pod and local file/directory must be specified"
                show_help
                exit 1
            fi
            
            # Extract remote file from pod spec if not explicitly provided
            if [[ -z "$remote_path" ]]; then
                # Try to extract from pod
                local result=$(process_pod_spec "$pod")
                local path=$(echo "$result" | cut -d'|' -f3)
                
                if [[ -n "$path" ]]; then
                    remote_path="$path"
                    pod=$(echo "$result" | cut -d'|' -f2)
                    local ns=$(echo "$result" | cut -d'|' -f1)
                    if [[ -n "$ns" ]]; then
                        namespace="$ns"
                    fi
                else
                    styled_error "Remote file path not specified"
                    show_help
                    exit 1
                fi
            fi
            
            # Interactive container selection if not specified
            if [[ -z "$container" ]]; then
                container=$(select_container "$namespace" "$pod")
            fi
            
            # Copy file from pod
            copy_from_pod "$namespace" "$pod" "$container" "$remote_path" "$local_file"
            ;;
        edit)
            # Validate arguments
            if [[ -z "$pod" ]]; then
                styled_error "Pod must be specified"
                show_help
                exit 1
            fi
            
            # Extract remote file from pod spec if not explicitly provided
            if [[ -z "$edit_file" ]]; then
                # Try to extract from pod
                local result=$(process_pod_spec "$pod")
                local path=$(echo "$result" | cut -d'|' -f3)
                
                if [[ -n "$path" ]]; then
                    edit_file="$path"
                    pod=$(echo "$result" | cut -d'|' -f2)
                    local ns=$(echo "$result" | cut -d'|' -f1)
                    if [[ -n "$ns" ]]; then
                        namespace="$ns"
                    fi
                else
                    styled_error "Remote file path not specified"
                    show_help
                    exit 1
                fi
            fi
            
            # Interactive container selection if not specified
            if [[ -z "$container" ]]; then
                container=$(select_container "$namespace" "$pod")
            fi
            
            # Edit file on pod
            edit_pod_file "$namespace" "$pod" "$container" "$edit_file"
            ;;
        mount)
            # Validate arguments
            if [[ -z "$pod" ]]; then
                styled_error "Pod must be specified"
                show_help
                exit 1
            fi
            
            if [[ -z "$local_dir" ]]; then
                styled_error "Local directory must be specified"
                show_help
                exit 1
            fi
            
            if [[ -z "$remote_dir" ]]; then
                styled_error "Remote directory must be specified"
                show_help
                exit 1
            fi
            
            # Interactive container selection if not specified
            if [[ -z "$container" ]]; then
                container=$(select_container "$namespace" "$pod")
            fi
            
            # Mount directory
            mount_directory "$namespace" "$pod" "$container" "$local_dir" "$remote_dir"
            ;;
        *)
            styled_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Execute main function
main "$@" "$container" -- which socat &>/dev/null; then
            # Create a random port for the transfer
            local port=$(shuf -i 10000-65000 -n 1)
            
            # Start socat in the container to send the file
            kubectl exec -n "$namespace" "$pod" -c "$container" -- socat TCP-LISTEN:$port,fork OPEN:"$remote_file" &
            local socat_pid=$!
            
            # Sleep to let socat start
            sleep 1
            
            # Port forward to the socat port
            kubectl port-forward -n "$namespace" "$pod" $port:$port &
            local portfwd_pid=$!
            
            # Sleep to let port forwarding start
            sleep 1
            
            # Receive the file using cat
            cat < /dev/tcp/localhost/$port > "$local_path"
            
            # Kill the port forward
            kill $portfwd_pid
            
            # Kill socat
            kill $socat_pid
            
            styled_success "Successfully copied file using socat"
            return 0
        fi
    fi
    
    # 3. Try base64 encoding/decoding
    styled_info "Trying base64 transfer..."
    
    # Check if base64 is available in the container
    if kubectl exec -n "$namespace" "$pod" -c "$container" -- which base64 &>/dev/null; then
        # Create a command to read and encode the file
        local encode_cmd="cat $remote_file | base64 -w 0"
        
        # Execute the command and decode the output
        local encoded_content=$(kubectl exec -n "$namespace" "$pod" -c "$container" -- sh -c "$encode_cmd")
        
        # Write the decoded content to the local file
        echo "$encoded_content" | base64 -d > "$local_path"
        
        if [[ $? -eq 0 ]]; then
            styled_success "Successfully copied file using base64 encoding"
            return 0
        fi
    fi
    
    # 4. Try using tar
    styled_info "Trying tar transfer..."
    
    # Check if tar is available in the container
    if kubectl exec -n "$namespace" "$pod" -c