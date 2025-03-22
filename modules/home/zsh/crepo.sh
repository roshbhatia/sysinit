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

# crepo - Navigate git repositories
function crepo() {
    REPO_BASE=~/github

    function list_repos() {
        repos=$(find "$REPO_BASE" -mindepth 2 -maxdepth 2 -type d ! -name ".*" | sort)
        selected_repo=$(echo "$repos" | while read -r repo; do
            org=$(basename "$(dirname "$repo")")
            name=$(basename "$repo")
            echo -e "$name ($org)"
        done | fzf --ansi --height=20)

        if [[ -n "$selected_repo" ]]; then
            repo_name=$(echo "$selected_repo" | awk '{print $1}')
            change_dir "$repo_name"
        fi
    }

    function change_dir() {
        target_repo=$1
        repos=$(find "$REPO_BASE" -mindepth 2 -maxdepth 2 -type d -name "$target_repo" ! -name ".*")
        target_path=$(echo "$repos" | head -n 1)
        if [[ -d "$target_path" ]]; then
            pushd "$target_path" || return
            echo "Changed directory to $target_path"
        else
            echo "Repository $target_repo not found."
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