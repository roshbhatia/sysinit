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
    
    # Find repositories in both personal and work directories
    local personal_path="$REPO_BASE/personal"
    local work_path="$REPO_BASE/work"
    
    # Check if the personal and work directories exist
    local personal_exists=0
    local work_exists=0
    [[ -d "$personal_path" ]] && personal_exists=1
    [[ -d "$work_path" ]] && work_exists=1
    
    # Find all repositories
    local repos=""
    if [[ $personal_exists -eq 1 ]]; then
        local personal_repos=$(find "$personal_path" -mindepth 3 -maxdepth 3 -type d ! -name ".*" 2>/dev/null | sort)
        [[ -n "$personal_repos" ]] && repos="$personal_repos"
    fi
    
    if [[ $work_exists -eq 1 ]]; then
        local work_repos=$(find "$work_path" -mindepth 3 -maxdepth 3 -type d ! -name ".*" 2>/dev/null | sort)
        if [[ -n "$repos" && -n "$work_repos" ]]; then
            repos=$(printf "%s\n%s" "$repos" "$work_repos")
        elif [[ -n "$work_repos" ]]; then
            repos="$work_repos"
        fi
    fi
    
    # If neither personal nor work directories exist or no repos found, fall back to old structure
    if [[ -z "$repos" ]]; then
        repos=$(find "$REPO_BASE" -mindepth 3 -maxdepth 3 -type d ! -name ".*" 2>/dev/null | sort)
    fi

    if [[ -z "$repos" ]]; then
        log_warn "No repositories found in $REPO_BASE"
        return 1
    fi

    # Get total repo count (properly trimmed)
    local repo_count=$(echo "$repos" | wc -l | tr -d '[:space:]')
    
    # Create a preview function for fzf
    preview_cmd='
        repo_path={}
        echo "Repository Details:"
        echo "==================="
        echo "Path: $repo_path"
        echo
        if [ -d "$repo_path/.git" ]; then
            echo "Git Status:"
            echo "==========="
            git -C "$repo_path" status -s
            echo
            echo "Recent Commits:"
            echo "=============="
            git -C "$repo_path" log --oneline -n 5
        fi
    '

    # Display repositories with enhanced fzf interface
    local header="Found $repo_count repositories - Select a repository (Use / to filter, CTRL-/ to toggle preview)"
    local selected_repo=$(echo "$repos" | while read -r repo; do
        local scope=$(basename "$(dirname "$(dirname "$repo")")")
        local org=$(basename "$(dirname "$repo")")
        local name=$(basename "$repo")
        printf "\x1b[1m%s\x1b[0m [\x1b[36m%s\x1b[0m/\x1b[35m%s\x1b[0m]\t%s\n" "$name" "$scope" "$org" "$repo"
    done | column -t -s $'\t' | fzf --ansi \
        --preview="$preview_cmd" \
        --preview-window=right:50%:wrap \
        --height=80% \
        --border=rounded \
        --header="$header" \
        --bind="ctrl-/:toggle-preview")

    if [[ -n "$selected_repo" ]]; then
        local target_path=$(echo "$selected_repo" | awk '{print $NF}')
        if [[ -d "$target_path" ]]; then
            log_debug "Selected repository" path="$target_path"
            pushd "$target_path" || return
            local scope=$(basename "$(dirname "$(dirname "$target_path")")")
            local org=$(basename "$(dirname "$target_path")")
            local repo_name=$(basename "$target_path")
            log_success "Changed directory to repository" path="$target_path" scope="$scope" org="$org" repo="$repo_name"
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
    
    # Find repositories in both personal and work directories
    local personal_path="$REPO_BASE/personal"
    local work_path="$REPO_BASE/work"
    
    # Check if the personal and work directories exist
    local personal_exists=0
    local work_exists=0
    [[ -d "$personal_path" ]] && personal_exists=1
    [[ -d "$work_path" ]] && work_exists=1
    
    # Find matching repositories
    local repos=""
    if [[ $personal_exists -eq 1 ]]; then
        local personal_repos=$(find "$personal_path" -mindepth 3 -maxdepth 3 -type d -name "$target_repo" ! -name ".*")
        repos="$personal_repos"
    fi
    
    if [[ $work_exists -eq 1 ]]; then
        local work_repos=$(find "$work_path" -mindepth 3 -maxdepth 3 -type d -name "$target_repo" ! -name ".*")
        if [[ -n "$repos" && -n "$work_repos" ]]; then
            repos=$(printf "%s\n%s" "$repos" "$work_repos")
        elif [[ -n "$work_repos" ]]; then
            repos="$work_repos"
        fi
    fi
    
    # If neither personal nor work directories exist, fall back to old structure
    if [[ -z "$repos" ]]; then
        repos=$(find "$REPO_BASE" -mindepth 3 -maxdepth 3 -type d -name "$target_repo" ! -name ".*")
    fi
    
    if [[ -z "$repos" ]]; then
        log_error "No repositories found matching '$target_repo'"
        return 1
    fi

    local repo_count=$(echo "$repos" | wc -l | tr -d '[:space:]')
    local target_path=""
    
    if [[ "$repo_count" -gt 1 ]]; then
        log_info "Multiple repositories found with the same name" count="$repo_count" name="$target_repo"
        local selected_repo=$(echo "$repos" | while read -r repo; do
            local scope=$(basename "$(dirname "$(dirname "$repo")")")
            local org=$(basename "$(dirname "$repo")")
            local name=$(basename "$repo")
            echo -e "$name ($scope/$org)\t$repo"
        done | column -t -s $'\t' | fzf --ansi --height=20)
        
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
        log_success "Changed directory to repository" path="$target_path" scope="$scope" org="$org" repo="$repo_name"
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