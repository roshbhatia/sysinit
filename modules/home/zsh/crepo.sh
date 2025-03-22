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

# crepo - Navigate git repositories
function crepo() {
    REPO_BASE=~/github

    function list_repos() {
        log_debug "Listing repositories" base_dir="$REPO_BASE"
        repos=$(find "$REPO_BASE" -mindepth 2 -maxdepth 2 -type d ! -name ".*" | sort)
        selected_repo=$(echo "$repos" | while read -r repo; do
            org=$(basename "$(dirname "$repo")")
            name=$(basename "$repo")
            # Store the full path as hidden data that can be parsed later
            echo -e "$name ($org)\t$repo"
        done | column -t -s $'\t' | fzf --ansi --height=20)

        if [[ -n "$selected_repo" ]]; then
            # Extract the full path from the selected entry
            target_path=$(echo "$selected_repo" | awk '{print $NF}')
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

    function change_dir() {
        target_repo=$1
        # If an exact repo name is provided, check if there are multiple matches
        log_debug "Searching for repository" name="$target_repo" base_dir="$REPO_BASE"
        repos=$(find "$REPO_BASE" -mindepth 2 -maxdepth 2 -type d -name "$target_repo" ! -name ".*")
        repo_count=$(echo "$repos" | wc -l | tr -d ' ')
        
        if [[ "$repo_count" -gt 1 ]]; then
            log_info "Multiple repositories found with the same name" count="$repo_count" name="$target_repo"
            # Multiple repos with the same name found - let the user choose
            selected_repo=$(echo "$repos" | while read -r repo; do
                org=$(basename "$(dirname "$repo")")
                name=$(basename "$repo")
                echo -e "$name ($org)\t$repo"
            done | column -t -s $'\t' | fzf --ansi --height=20)
            
            if [[ -n "$selected_repo" ]]; then
                target_path=$(echo "$selected_repo" | awk '{print $NF}')
                log_debug "User selected repository" path="$target_path"
            else
                log_warn "Selection cancelled by user"
                return
            fi
        else
            target_path=$(echo "$repos" | head -n 1)
            log_debug "Single repository match found" path="$target_path"
        fi
        
        if [[ -d "$target_path" ]]; then
            pushd "$target_path" || return
            log_success "Changed directory to repository" path="$target_path" org="$(basename "$(dirname "$target_path")")" repo="$(basename "$target_path")"
        else
            log_error "Repository not found" name="$target_repo"
        fi
    }

    function show_help() {
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

    case "$1" in
        list|l)
            list_repos
            ;;
        d|cd)
            if [[ -z "$2" ]]; then
                log_error "Missing repository name"
                echo "Please provide a repository name."
            else
                change_dir "$2"
            fi
            ;;
        h|help)
            show_help
            ;;
        *)
            list_repos
            ;;
    esac
}