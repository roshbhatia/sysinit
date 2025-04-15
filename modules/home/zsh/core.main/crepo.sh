#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all

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

    local target_path=$(echo "$repos" | while read -r repo; do
        local name=$(basename "$repo")
        local org=$(basename "$(dirname "$repo")")
        printf "%s|%s %s\n" "$repo" "$(gum style --foreground 35 "$name")" "$(gum style --foreground 212 "($org)")"
    done | fzf --ansi \
        --preview='eza --color=always --icons=always --long --no-permissions --no-user --no-time $(echo {} | cut -d"|" -f1)' \
        --preview-window=right:40%:wrap:border-rounded \
        --height=40% \
        --border=rounded \
        --header="$(gum style --foreground 212 'Select a repository')" \
        --bind="ctrl-/:toggle-preview" \
        --with-nth=2.. \
        --bind 'ctrl-r:refresh-preview' \
        --delimiter="|" | cut -d"|" -f1)

    if [[ -d "$target_path" ]]; then
        \pushd "$target_path" || return
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

function _crepo_change_dir() {
    local REPO_BASE="$1"
    local target_repo="$2"
    local workspace="$3"
    local target_path=""
    
    if [[ -z "$target_repo" ]]; then
        target_path=$(_crepo_list_interactive "$REPO_BASE")
    else
        local repos=$(_crepo_list_repos "$REPO_BASE" | grep -i "/${target_repo}[^/]*$" || echo "")
        if [[ -n "$workspace" ]]; then
            repos=$(echo "$repos" | grep "/$workspace/" || echo "")
        fi
        local repo_count=$(echo "$repos" | grep -c .)
        
        if [[ "$repo_count" -eq 0 ]]; then
            gum style --foreground 196 "No repositories found matching '$target_repo'"
            [[ -n "$workspace" ]] && gum style --foreground 196 "in workspace '$workspace'"
            return 1
        elif [[ "$repo_count" -eq 1 ]]; then
            target_path="$repos"
        else
            target_path=$(echo "$repos" | fzf --ansi \
                --preview='eza --icons=always --no-permissions --no-user --no-time {}' \
                --preview-window=right:40%:wrap:border-rounded \
                --bind 'ctrl-r:refresh-preview' \
            )
        fi
    fi
    
    if [[ -d "$target_path" ]]; then
        \pushd "$target_path" || return
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
    gum style --foreground 99 --bold "Usage:" && gum style "crepo [-w WORKSPACE] {list|l|d|cd|h|help} [REPO_NAME]"
    echo
    gum style --foreground 99 --bold "Options:"
    echo "$(gum style --foreground 212 "  -w WORKSPACE")     $(gum style "Filter repositories by workspace (e.g., personal, work)")"
    echo
    gum style --foreground 99 --bold "Commands:"
    echo "$(gum style --foreground 212 "  list, l")          $(gum style "List all repositories and their organizations")"
    echo "$(gum style --foreground 212 "  d, cd [REPO_NAME]") $(gum style "Change directory to the specified repository")"
    echo "$(gum style --foreground 212 "  h, help")          $(gum style "Show this help message")"
}

# Main crepo function
function crepo() {
    local REPO_BASE=~/github
    local workspace=""

    # Parse options
    while getopts ":w:" opt; do
        case ${opt} in
            w)
                workspace=$OPTARG
                ;;
            \?)
                gum style --foreground 196 "Invalid option: -$OPTARG"
                _crepo_show_help
                return 1
                ;;
            :)
                gum style --foreground 196 "Option -$OPTARG requires an argument"
                _crepo_show_help
                return 1
                ;;
        esac
    done
    shift $((OPTIND -1))

    [[ ! -d "$REPO_BASE" ]] && { log_error "Repository base directory does not exist" path="$REPO_BASE"; return 1; }

    case "$1" in
        list|l)
            _crepo_list_interactive "$REPO_BASE"
            ;;
        d|cd)
            shift
            _crepo_change_dir "$REPO_BASE" "$1" "$workspace"
            ;;
        h|help)
            _crepo_show_help
            ;;
        *)
            if [[ -n "$1" ]]; then
                _crepo_change_dir "$REPO_BASE" "$1" "$workspace"
            else
                _crepo_list_interactive "$REPO_BASE"
            fi
            ;;
    esac
}