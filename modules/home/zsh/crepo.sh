#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
#                                        
#                                        
#                                        
# .d8888b888d888 .d88b. 88888b.  .d88b.  
# d88P"   888P"  d8P  Y8b888 "88bd88""88b 
# 888     888    88888888888  888888  888 
# Y88b.   888    Y8b.    888 d88PY88..88P 
# "Y8888P888     "Y8888 88888P"  "Y88P"  
#                       888              
#                       888              
#                       888

# Ensure logging library is loaded
[ -f "$HOME/.config/zsh/loglib.sh" ] && source "$HOME/.config/zsh/loglib.sh"

# Helper functions defined outside the main function to avoid nesting
crepo_list_repos() {
    local REPO_BASE="$1"
    log_debug "Listing repositories" base_dir="$REPO_BASE"
    local repos=$(find "$REPO_BASE" -mindepth 2 -maxdepth 2 -type d ! -name ".*" | sort)
    local selected_repo=$(echo "$repos" | while read -r repo; do
        local org=$(basename "$(dirname "$repo")")
        local name=$(basename "$repo")
        echo -e "$name ($org)\t$repo"
    done | column -t -s $'\t' | fzf --ansi --height=20)

    if [[ -n "$selected_repo" ]]; then
        local target_path=$(echo "$selected_repo" | awk '{print $NF}')
        if [[ -d "$target_path" ]]; then
            log_debug "Selected repository" path="$target_path"
            pushd "$target_path" || return
            log_success "Changed directory to repository" path="$target_path" org="$(basename "$(dirname "$target_path")")" repo="$(basename "$target_path")"
        else
            log_error "Selected directory does not exist" path="$target_path"
        fi
    else
        log_debug "No repository selected"
    fi
}

crepo_change_dir() {
    local REPO_BASE="$1"
    local target_repo="$2"
    log_debug "Searching for repository" name="$target_repo" base_dir="$REPO_BASE"
    local repos=$(find "$REPO_BASE" -mindepth 2 -maxdepth 2 -type d -name "$target_repo" ! -name ".*")
    local repo_count=$(echo "$repos" | wc -l | tr -d ' ')
    
    if [[ "$repo_count" -gt 1 ]]; then
        log_info "Multiple repositories found with the same name" count="$repo_count" name="$target_repo"
        local selected_repo=$(echo "$repos" | while read -r repo; do
            local org=$(basename "$(dirname "$repo")")
            local name=$(basename "$repo")
            echo -e "$name ($org)\t$repo"
        done | column -t -s $'\t' | fzf --ansi --height=20)
        
        if [[ -n "$selected_repo" ]]; then
            local target_path=$(echo "$selected_repo" | awk '{print $NF}')
            log_debug "User selected repository" path="$target_path"
        else
            log_warn "Selection cancelled by user"
            return
        fi
    else
        local target_path=$(echo "$repos" | head -n 1)
        log_debug "Single repository match found" path="$target_path"
    fi
    
    if [[ -d "$target_path" ]]; then
        pushd "$target_path" || return
        log_success "Changed directory to repository" path="$target_path" org="$(basename "$(dirname "$target_path")")" repo="$(basename "$target_path")"
    else
        log_error "Repository not found" name="$target_repo"
    fi
}

crepo_show_help() {
    echo "                                        "
    echo "                                        "
    echo "                                        "
    echo " .d8888b888d888 .d88b. 88888b.  .d88b.  "
    echo " d88P\"   888P\"  d8P  Y8b888 \"88bd88\"\"88b "
    echo " 888     888    88888888888  888888  888 "
    echo " Y88b.   888    Y8b.    888 d88PY88..88P "
    echo " \"Y8888P888     \"Y8888 88888P\"  \"Y88P\"  "
    echo "                       888              "
    echo "                       888              "
    echo "                       888              "
    echo
    echo "Usage: crepo {list|l|d|cd|h|help} [REPO_NAME]"
    echo
    echo "Commands:"
    echo "  list, l          List all repositories and their organizations"
    echo "  d, cd [REPO_NAME] Change directory to the specified repository"
    echo "  h, help          Show this help message"
}

# crepo - Navigate git repositories
function crepo() {
    local REPO_BASE=~/github

    case "$1" in
        list|l)
            crepo_list_repos "$REPO_BASE"
            ;;
        d|cd)
            if [[ -z "$2" ]]; then
                log_error "Missing repository name"
                echo "Please provide a repository name."
            else
                crepo_change_dir "$REPO_BASE" "$2"
            fi
            ;;
        h|help)
            crepo_show_help
            ;;
        *)
            crepo_list_repos "$REPO_BASE"
            ;;
    esac
}