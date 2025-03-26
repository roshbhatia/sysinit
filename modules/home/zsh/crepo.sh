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

    # Find all repositories
    local repos=$(find "$REPO_BASE" -mindepth 3 -maxdepth 3 -type d ! -name ".*" 2>/dev/null | sort)

    if [[ -z "$repos" ]]; then
        gum style --foreground 196 "No repositories found in $REPO_BASE"
        return 1
    fi

    # Get total repo count
    local repo_count=$(echo "$repos" | wc -l | tr -d '[:space:]')
    
    # Process repository list before fzf to improve performance
    local processed_repos=$(echo "$repos" | while read -r repo; do
        local scope=$(basename "$(dirname "$(dirname "$repo")")")
        local org=$(basename "$(dirname "$repo")")
        local name=$(basename "$repo")
        printf "%s|%s|%s|%s\n" "$name" "$scope" "$org" "$repo"
    done)

    # Create a preview function for fzf that uses eza
    preview_cmd='
        repo_path=$(echo {} | cut -d"|" -f4)
        eza -la --icons --git --color=always "$repo_path"
    '

    # Display repositories with enhanced fzf interface
    local header="$(gum style --foreground 212 "Found $repo_count repositories") - $(gum style --foreground 99 "Select a repository") (Use / to filter, CTRL-/ to toggle preview)"
    local selected_repo=$(echo "$processed_repos" | while read -r line; do
        local name=$(echo "$line" | cut -d"|" -f1)
        local scope=$(echo "$line" | cut -d"|" -f2)
        local org=$(echo "$line" | cut -d"|" -f3)
        local path=$(echo "$line" | cut -d"|" -f4)
        printf "%s\n" "$(gum style --foreground 255 "$name") $(gum style --foreground 212 "[$scope/") $(gum style --foreground 99 "$org]") $(gum style --foreground 240 "$path")"
    done | column -t | fzf --ansi \
        --preview="$preview_cmd" \
        --preview-window=right:25%:wrap:border-rounded \
        --height=80% \
        --border=rounded \
        --header="$header" \
        --bind="ctrl-/:toggle-preview")

    if [[ -n "$selected_repo" ]]; then
        local target_path=$(echo "$selected_repo" | awk '{print $NF}')
        if [[ -d "$target_path" ]]; then
            pushd "$target_path" || return
            local scope=$(basename "$(dirname "$(dirname "$target_path")")")
            local org=$(basename "$(dirname "$target_path")")
            local repo_name=$(basename "$target_path")
            gum style \
                --foreground 212 --border-foreground 212 --border double \
                --align center --width 50 --margin "1 2" --padding "1 2" \
                "Changed to repository:" \
                "$(gum style --foreground 99 "$scope/$org/$repo_name")"
        else
            gum style --foreground 196 "Selected directory does not exist: $target_path"
        fi
    fi
}

crepo_change_dir() {
    local REPO_BASE="$1"
    local target_repo="$2"
    log_debug "Searching for repository" name="$target_repo" base_dir="$REPO_BASE"
    
    # Find all matching repositories
    local repos=$(find "$REPO_BASE" -mindepth 3 -maxdepth 3 -type d -name "$target_repo" ! -name ".*" 2>/dev/null | sort)
    
    if [[ -z "$repos" ]]; then
        gum style --foreground 196 "No repositories found matching '$target_repo'"
        return 1
    fi

    local repo_count=$(echo "$repos" | wc -l | tr -d '[:space:]')
    local target_path=""
    
    if [[ "$repo_count" -gt 1 ]]; then
        gum style --foreground 212 "Multiple repositories found with the same name: $repo_count matches"
        
        # Process repository list before fzf
        local processed_repos=$(echo "$repos" | while read -r repo; do
            local scope=$(basename "$(dirname "$(dirname "$repo")")")
            local org=$(basename "$(dirname "$repo")")
            local name=$(basename "$repo")
            printf "%s|%s|%s|%s\n" "$name" "$scope" "$org" "$repo"
        done)

        # Create preview command
        preview_cmd='
            repo_path=$(echo {} | cut -d"|" -f4)
            eza -la --icons --git --color=always "$repo_path"
        '

        local selected_repo=$(echo "$processed_repos" | while read -r line; do
            local name=$(echo "$line" | cut -d"|" -f1)
            local scope=$(echo "$line" | cut -d"|" -f2)
            local org=$(echo "$line" | cut -d"|" -f3)
            local path=$(echo "$line" | cut -d"|" -f4)
            printf "%s\n" "$(gum style --foreground 255 "$name") $(gum style --foreground 212 "[$scope/") $(gum style --foreground 99 "$org]") $(gum style --foreground 240 "$path")"
        done | column -t | fzf --ansi \
            --preview="$preview_cmd" \
            --preview-window=right:25%:wrap:border-rounded \
            --height=20 \
            --border=rounded \
            --header="$(gum style --foreground 212 "Select a repository")")
        
        if [[ -n "$selected_repo" ]]; then
            target_path=$(echo "$selected_repo" | awk '{print $NF}')
            log_debug "User selected repository" path="$target_path"
        fi
    else
        target_path=$(echo "$repos" | head -n1)
    fi
    
    if [[ -d "$target_path" ]]; then
        pushd "$target_path" || return
        local scope=$(basename "$(dirname "$(dirname "$target_path")")")
        local org=$(basename "$(dirname "$target_path")")
        local repo_name=$(basename "$target_path")
        gum style \
            --foreground 212 --border-foreground 212 --border double \
            --align center --width 50 --margin "1 2" --padding "1 2" \
            "Changed to repository:" \
            "$(gum style --foreground 99 "$scope/$org/$repo_name")"
    else
        gum style --foreground 196 "Repository not found: $target_repo"
    fi
}

crepo_show_help() {
    gum style --foreground 212 "                                        
                                        
                                        
 .d8888b888d888 .d88b. 88888b.  .d88b.  
 d88P\"   888P\"  d8P  Y8b888 \"88bd88\"\"88b 
 888     888    88888888888  888888  888 
 Y88b.   888    Y8b.    888 d88PY88..88P 
 \"Y8888P888     \"Y8888 88888P\"  \"Y88P\"  
                       888              
                       888              
                       888              "
    echo
    gum style --foreground 99 --bold "Usage:" && gum style "crepo {list|l|d|cd|h|help} [REPO_NAME]"
    echo
    gum style --foreground 99 --bold "Commands:"
    echo "$(gum style --foreground 212 "  list, l")          $(gum style "List all repositories and their organizations")"
    echo "$(gum style --foreground 212 "  d, cd [REPO_NAME]") $(gum style "Change directory to the specified repository")"
    echo "$(gum style --foreground 212 "  h, help")          $(gum style "Show this help message")"
}

# crepo - Navigate git repositories
function crepo() {
    local REPO_BASE=~/github

    # Check if REPO_BASE exists
    if [[ ! -d "$REPO_BASE" ]]; then
        log_error "Repository base directory does not exist" path="$REPO_BASE"
        return 1
    fi

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