#!/usr/bin/env bash
# shellcheck disable=all

show_help() {
    echo -e "\nCRD Browser - Interactive Kubernetes CRD Explorer"
    echo "Usage: crdbrowse <crd-url>"
    echo -e "\nKeys:"
    echo "  ↑/↓    : Navigate through paths"
    echo "  Enter  : Select path"
    echo "  Tab    : Toggle preview"
    echo "  Ctrl+E : Edit YQ query"
    echo "  ESC    : Exit current view"
    echo "  ?      : Show this help"
    echo -e "\nExample:"
    echo "  crdbrowse https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/main/config/crd/bases/opentelemetry.io_opentelemetrycollectors.yaml"
}

if [ -z "$1" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 1
fi

# Download and process the CRD
TMP_FILE=$(mktemp)
curl -s "$1" > "$TMP_FILE"

# Function to extract paths from yaml
get_paths() {
    yq -r '.. | select(.|length>0) | path | join(".")' "$TMP_FILE" | sort -u
}

# Function to handle YQ query editing
edit_query() {
    local current_query="$1"
    local new_query=$(gum input --value "$current_query" --placeholder "Enter YQ query (e.g., .spec.template)")
    echo "$new_query"
}

# Show initial logo
clear
echo -e "$LOGO"
sleep 1

# Main interactive loop
CURRENT_QUERY=""
while true; do
    clear
    echo -e "$LOGO\n"
    
    if [ -n "$CURRENT_QUERY" ]; then
        echo "Current YQ Query: $CURRENT_QUERY"
    fi

    SELECTED=$(get_paths | fzf --preview "yq '{\"selected\": $(echo {} | sed 's/\./\"\.\"/g')}' $TMP_FILE | bat -l yaml --color=always" \
                            --preview-window=right:60%:wrap \
                            --height=80% \
                            --border=rounded \
                            --header="↑/↓: Navigate | Enter: Select | Tab: Toggle Preview | Ctrl+E: Edit Query | ?: Help" \
                            --bind="ctrl-e:execute(echo {} > /tmp/current_path)+abort" \
                            --bind="?:execute(echo -e '$LOGO\n\nKeys:\n↑/↓: Navigate\nEnter: Select\nTab: Toggle Preview\nCtrl+E: Edit Query\nESC: Exit\n?' | less)" \
                            --prompt="Select path (ESC to exit): ")
    
    if [ -z "$SELECTED" ]; then
        if [ -f "/tmp/current_path" ]; then
            CURRENT_PATH=$(cat /tmp/current_path)
            CURRENT_QUERY=$(edit_query "$CURRENT_PATH")
            rm /tmp/current_path
            if [ -n "$CURRENT_QUERY" ]; then
                clear
                echo -e "$LOGO\n"
                echo "Query: $CURRENT_QUERY"
                echo "---"
                yq "$CURRENT_QUERY" "$TMP_FILE" | bat -l yaml --color=always
                echo ""
                gum confirm "Continue browsing?" && continue || break
            fi
            continue
        else
            break
        fi
    fi

    # Show the selected path with syntax highlighting
    clear
    echo -e "$LOGO\n"
    echo "Selected path: $SELECTED"
    echo "---"
    yq "{\"selected\": $(echo $SELECTED | sed 's/\./\"\.\"/g')}" "$TMP_FILE" | bat -l yaml --color=always
    
    echo ""
    gum confirm "Continue browsing?" && continue || break
done

# Cleanup
rm "$TMP_FILE"