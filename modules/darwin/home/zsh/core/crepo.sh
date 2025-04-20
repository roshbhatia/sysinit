#!/usr/bin/env zsh
# Converted from core.main/crepo.sh to standalone executable
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all

# Make sure this script is sourced, not executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script must be sourced, not executed."
    echo "Use: source $(basename ${0})"
    exit 1
fi

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
        echo "$target_path"
        return 0
    fi
    return 1
}

function _crepo_show_help() {
    gum style --foreground 212 "Crepo - Repository Navigation Tool"
    echo
    gum style --foreground 99 --bold "Usage:" && gum style "crepo [-w WORKSPACE] [-o OWNER] [REPO_NAME]"
    echo
    gum style --foreground 99 --bold "Options:"
    echo "$(gum style --foreground 212 "  -w WORKSPACE")     $(gum style "Filter repositories by workspace (e.g., personal, work)")"
    echo "$(gum style --foreground 212 "  -o OWNER")        $(gum style "Filter repositories by owner/organization")"
    echo
    gum style --foreground 99 --bold "Examples:"
    echo "$(gum style --foreground 212 "  crepo")            $(gum style "Interactive repository selection")"
    echo "$(gum style --foreground 212 "  crepo sysinit")    $(gum style "Change to repository named sysinit")"
    echo "$(gum style --foreground 212 "  crepo -w work sysinit")  $(gum style "Change to sysinit repo in work workspace")"
    echo "$(gum style --foreground 212 "  crepo -o roshbhatia sysinit")  $(gum style "Change to sysinit repo owned by roshbhatia")"
}

function _crepo_change_dir() {
    local REPO_BASE="$1"
    local target_repo="$2"
    local workspace="$3"
    local owner="$4"
    local target_path=""
    
    if [[ -z "$target_repo" ]]; then
        target_path=$(_crepo_list_interactive "$REPO_BASE")
    else
        local repos=$(_crepo_list_repos "$REPO_BASE" | grep -i "/${target_repo}[^/]*$" || echo "")
        
        # Apply workspace filter if specified
        if [[ -n "$workspace" ]]; then
            repos=$(echo "$repos" | grep "/$workspace/" || echo "")
        fi
        
        # Apply owner filter if specified
        if [[ -n "$owner" ]]; then
            repos=$(echo "$repos" | grep "/${owner}/" || echo "")
        fi
        
        local repo_count=$(echo "$repos" | grep -c .)
        
        if [[ "$repo_count" -eq 0 ]]; then
            gum style --foreground 196 "No repositories found matching '$target_repo'" >&2
            [[ -n "$workspace" ]] && gum style --foreground 196 "in workspace '$workspace'" >&2
            [[ -n "$owner" ]] && gum style --foreground 196 "owned by '$owner'" >&2
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
        # First output just the raw path to stdout for capture by the caller
        printf '%s\n' "$target_path"
        
        # Then show the styled information on stderr
        {
            local scope=$(basename "$(dirname "$(dirname "$target_path")")") 
            local org=$(basename "$(dirname "$target_path")")
            local name=$(basename "$target_path")
            
            gum style \
                --foreground 212 --border-foreground 212 --border double \
                --align center --width 50 --margin "1 2" --padding "1 2" \
                "Repository found:" \
                "$(gum style --foreground 99 "$scope/$org/$name")"
        } >&2
        
        return 0
    fi
    return 1
}

function crepo() {
    local REPO_BASE=~/github
    local workspace=""
    local owner=""

    # Parse options
    while getopts ":w:o:" opt; do
        case ${opt} in
            w)
                workspace=$OPTARG
                ;;
            o)
                owner=$OPTARG
                ;;
            \?)
                gum style --foreground 196 "Invalid option: -$OPTARG" >&2
                _crepo_show_help >&2
                return 1
                ;;
            :)
                gum style --foreground 196 "Option -$OPTARG requires an argument" >&2
                _crepo_show_help >&2
                return 1
                ;;
        esac
    done
    shift $((OPTIND -1))

    [[ ! -d "$REPO_BASE" ]] && { echo "Repository base directory does not exist: $REPO_BASE" >&2; return 1; }

    # All arguments after options are treated as the repo name
    local repo_name="$1"
    local target_path
    
    if [[ -z "$repo_name" ]]; then
        target_path=$(_crepo_list_interactive "$REPO_BASE")
    else
        target_path=$(_crepo_change_dir "$REPO_BASE" "$repo_name" "$workspace" "$owner")
    fi
    
    if [[ -n "$target_path" ]] && [[ -d "$target_path" ]]; then
        builtin pushd "$target_path" > /dev/null || return 1
        return 0
    fi
    return 1
}
