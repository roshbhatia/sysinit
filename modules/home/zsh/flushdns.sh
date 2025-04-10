#!/usr/bin/env zsh
# shellcheck disable=all

# Flush DNS cache with visual feedback
flushdns() {
    gum spin --spinner dot --title "Flushing DNS cache..." -- \
        sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder
    
    gum style --foreground "#00ff00" "✓ DNS cache flushed successfully"
}