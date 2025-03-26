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
    local CACHE_FILE="/tmp/crepo_cache"
    local CACHE_TIMEOUT=3600  # 1 hour in seconds

    # More reliable cache check for macOS
    if [[ -f "$CACHE_FILE" ]]; then
        local cache_time
        cache_time=$(stat -f %m "$CACHE_FILE" 2>/dev/null)
        local current_time
        current_time=$(date +%s)
        if (( current_time - cache_time < CACHE_TIMEOUT )); then
            local repos=$(<"$CACHE_FILE")
        else
            local repos=$(find "$REPO_BASE" -mindepth 3 -maxdepth 3 -type d ! -name ".*" -exec test -d "{}/.git" \; -print 2>/dev/null | sort)
            echo "$repos" > "$CACHE_FILE"
        fi
    else
        local repos=$(find "$REPO_BASE" -mindepth 3 -maxdepth 3 -type d ! -name ".*" -exec test -d "{}/.git" \; -print 2>/dev/null | sort)
        echo "$repos" > "$CACHE_FILE"
    fi

    [[ -z "$repos" ]] && { gum style --foreground 196 "No repositories found in $REPO_BASE"; return 1; }

    echo "$repos" | while read -r repo; do
        local name=$(basename "$repo")
        local org=$(basename "$(dirname "$repo")")
        printf "%s|%s %s\n" "$repo" "$(gum style --foreground 35 "$name")" "$(gum style --foreground 212 "($org)")"
    done | fzf --ansi \
        --preview='eza -l --icons --git --group-directories-first --color=always $(echo {} | cut -d"|" -f1)' \
        --preview-window=right:40%:wrap:border-rounded \
        --height=40% \
        --border=rounded \
        --header="$(gum style --foreground 212 'Select a repository')" \
        --bind="ctrl-/:toggle-preview" \
        --with-nth=2.. \
        --delimiter="|" | cut -d"|" -f1 | while read -r path; do
        [[ -d "$path" ]] && {
            cd "$path" || return
            local scope=$(basename "$(dirname "$(dirname "$path")")")
            local org=$(basename "$(dirname "$path")")
            local name=$(basename "$path")
            gum style \
                --foreground 212 --border-foreground 212 --border double \
                --align center --width 50 --margin "1 2" --padding "1 2" \
                "Changed to repository:" \
                "$(gum style --foreground 99 "$scope/$org/$name")"
        }
    done
}

crepo_change_dir() {
    local REPO_BASE="$1"
    local target_repo="$2"
    log_debug "Searching for repository" name="$target_repo" base_dir="$REPO_BASE"
    
    # Use cache if available
    local CACHE_FILE="/tmp/crepo_cache"
    if [[ -f "$CACHE_FILE" ]]; then
        local repos=$(grep "/$target_repo$" "$CACHE_FILE")
    else
        local repos=$(find "$REPO_BASE" -mindepth 3 -maxdepth 3 -type d -name "$target_repo" ! -name ".*" -exec test -d "{}/.git" \; -print 2>/dev/null | sort)
    fi
    
    [[ -z "$repos" ]] && { gum style --foreground 196 "No repositories found matching '$target_repo'"; return 1; }

    local repo_count=$(echo "$repos" | wc -l | tr -d '[:space:]')
    local target_path=""
    
    if [[ "$repo_count" -gt 1 ]]; then
        gum style --foreground 212 "Multiple matches found:"
        
        # Simplified preview command
        preview_cmd='eza -l --icons --git --group-directories-first --color=always $(echo {} | cut -d"|" -f1)'

        target_path=$(echo "$repos" | while read -r repo; do
            local name=$(basename "$repo")
            local org=$(basename "$(dirname "$repo")")
            printf "%s|%s\n" "$repo" "$(gum style --foreground 35 "$name") $(gum style --foreground 212 "($org)")"
        done | fzf --ansi \
            --preview="$preview_cmd" \
            --preview-window=right:40%:wrap:border-rounded \
            --height=40% \
            --border=rounded \
            --header="$(gum style --foreground 212 'Select a repository')" \
            --bind="ctrl-/:toggle-preview" \
            --with-nth=2 \
            --delimiter="|" | cut -d'|' -f1)
    else
        target_path=$(echo "$repos" | head -n1)
    fi
    
    [[ -d "$target_path" ]] && {
        pushd "$target_path" >/dev/null || return
        local scope=$(basename "$(dirname "$(dirname "$target_path")")")
        local org=$(basename "$(dirname "$target_path")")
        local name=$(basename "$target_path")
        gum style \
            --foreground 212 --border-foreground 212 --border double \
            --align center --width 50 --margin "1 2" --padding "1 2" \
            "Changed to repository:" \
            "$(gum style --foreground 99 "$scope/$org/$name")"
    }
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