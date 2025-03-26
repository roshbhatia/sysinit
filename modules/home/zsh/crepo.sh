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
function _crepo_list_repos() {
    local REPO_BASE="$1"
    fd --type d \
       --hidden \
       --no-ignore \
       --max-depth 4 \
       '^\.git$' \
       "$REPO_BASE" 2>/dev/null | 
        sed 's/[/]*\.git[/]*$//' | 
        sort -u
}

function _crepo_list_interactive() {
    local REPO_BASE="$1"
    local repos=$(_crepo_list_repos "$REPO_BASE")

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
        --delimiter="|" | cut -d"|" -f1
}

function _crepo_change_dir() {
    local REPO_BASE="$1"
    local target_repo="$2"
    local target_path=""
    
    if [[ -z "$target_repo" ]]; then
        target_path=$(_crepo_list_interactive "$REPO_BASE")
    else
        local repos=$(_crepo_list_repos "$REPO_BASE" | grep -i "/$target_repo[^/]*$" || echo "")
        local repo_count=$(echo "$repos" | grep -c .)
        
        if [[ "$repo_count" -eq 0 ]]; then
            gum style --foreground 196 "No repositories found matching '$target_repo'"
            return 1
        elif [[ "$repo_count" -eq 1 ]]; then
            target_path="$repos"
        else
            target_path=$(echo "$repos" | fzf --ansi --preview='eza -l --icons --git --color=always {}')
        fi
    fi
    
    if [[ -d "$target_path" ]]; then
        \cd "$target_path" || return
        local scope=$(basename "$(dirname "$(dirname "$target_path")")")
        local org=$(basename "$(dirname "$target_path")")
        local name=$(basename "$target_path")
        gum style \
            --foreground 212 --border-foreground 212 --border double \
            --align center --width 50 --margin "1 2" --padding "1 2" \
            "Changed to repository:" \
            "$(gum style --foreground 99 "$scope/$org/$name")"
    fi
}

function _crepo_show_help() {
    gum style --foreground 212 "Crepo - Repository Navigation Tool"
    echo
    gum style --foreground 99 --bold "Usage:" && gum style "crepo {list|l|d|cd|h|help} [REPO_NAME]"
    echo
    gum style --foreground 99 --bold "Commands:"
    echo "$(gum style --foreground 212 "  list, l")          $(gum style "List all repositories and their organizations")"
    echo "$(gum style --foreground 212 "  d, cd [REPO_NAME]") $(gum style "Change directory to the specified repository")"
    echo "$(gum style --foreground 212 "  h, help")          $(gum style "Show this help message")"
}

# Main crepo function
function crepo() {
    local REPO_BASE=~/github

    [[ ! -d "$REPO_BASE" ]] && { log_error "Repository base directory does not exist" path="$REPO_BASE"; return 1; }

    case "$1" in
        list|l)
            _crepo_list_interactive "$REPO_BASE"
            ;;
        d|cd)
            shift
            _crepo_change_dir "$REPO_BASE" "$1"
            ;;
        h|help)
            _crepo_show_help
            ;;
        *)
            _crepo_list_interactive "$REPO_BASE"
            ;;
    esac
}