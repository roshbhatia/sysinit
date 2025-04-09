#!/bin/bash

# sysinit-help.sh - Help and information about sysinit configurations
# Shows keybindings, plugin info and general configuration overview

# ANSI colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Print header
print_header() {
    echo -e "${BOLD}${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                      SYSINIT HELP                          ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Print keybindings section
print_keybindings() {
    echo -e "${BOLD}${GREEN}NEOVIM KEYBINDINGS${NC}\n"
    echo -e "${CYAN}Window Management${NC}"
    echo -e "  ${YELLOW}<C-h/j/k/l>${NC} - Navigate between windows (also works from terminal)"
    echo -e "  ${YELLOW}<leader>wh/j/k/l>${NC} - Resize window in direction"
    echo -e "  ${YELLOW}<leader>wS/J/K/L>${NC} - Swap buffer in direction"
    echo -e "  ${YELLOW}<leader>w=${NC} - Equal window size"
    echo -e ""
    
    echo -e "${CYAN}Search and Navigation${NC}"
    echo -e "  ${YELLOW}<leader>p>${NC} - Find files (was Ctrl+P)"
    echo -e "  ${YELLOW}<leader>fg>${NC} - Find text (grep)"
    echo -e "  ${YELLOW}<leader>fb>${NC} - Find buffers"
    echo -e "  ${YELLOW}<leader>jb>${NC} - Jump back (was Ctrl+B)"
    echo -e "  ${YELLOW}<leader>jf>${NC} - Jump forward (was Ctrl+F)"
    echo -e "  ${YELLOW}<leader>jl>${NC} - Show jump list"
    echo -e ""
    
    echo -e "${CYAN}Code Actions and LSP${NC}"
    echo -e "  ${YELLOW}gd${NC} - Go to definition"
    echo -e "  ${YELLOW}K${NC} - Hover documentation"
    echo -e "  ${YELLOW}<leader>ca>${NC} - Code actions"
    echo -e "  ${YELLOW}gR${NC} - Show references in Trouble"
    echo -e ""
    
    echo -e "${CYAN}Copilot${NC}"
    echo -e "  ${YELLOW}<C-y>${NC} - Accept suggestion"
    echo -e "  ${YELLOW}<C-w>${NC} - Accept word"
    echo -e "  ${YELLOW}<C-l>${NC} - Accept line"
    echo -e "  ${YELLOW}<C-n>${NC} - Next suggestion"
    echo -e "  ${YELLOW}<C-p>${NC} - Previous suggestion"
    echo -e "  ${YELLOW}<C-h>${NC} - Show suggestions panel"
    echo -e "  ${YELLOW}<leader>ct>${NC} - Toggle Copilot"
    echo -e ""
    
    echo -e "${CYAN}Git Integration${NC}"
    echo -e "  ${YELLOW}<leader>gd>${NC} - Open Diffview"
    echo -e "  ${YELLOW}<leader>gh>${NC} - File history"
    echo -e "  ${YELLOW}<leader>gc>${NC} - Close Diffview"
    echo -e ""
    
    echo -e "${CYAN}Terminal and Running Commands${NC}"
    echo -e "  ${YELLOW}<leader>tf>${NC} - Open floating terminal"
    echo -e "  ${YELLOW}<leader>th>${NC} - Open horizontal terminal"
    echo -e "  ${YELLOW}<leader>tv>${NC} - Open vertical terminal"
    echo -e "  ${YELLOW}<leader>tg>${NC} - Open Lazygit"
    echo -e ""
    
    echo -e "${CYAN}Diagnostics and Notifications${NC}"
    echo -e "  ${YELLOW}<leader>xx>${NC} - Document diagnostics (Trouble)"
    echo -e "  ${YELLOW}<leader>xX>${NC} - Workspace diagnostics (Trouble)"
    echo -e "  ${YELLOW}<leader>ne>${NC} - Show error history"
    echo -e "  ${YELLOW}<leader>nm>${NC} - Show message history"
    echo -e "  ${YELLOW}<leader>nd>${NC} - Dismiss notifications"
    echo -e "  ${YELLOW}<leader>nt>${NC} - Toggle noice UI"
    echo -e "  ${YELLOW}<leader>tn>${NC} - Toggle notifications"
    echo -e ""
}

# Print aerospace keybindings
print_aerospace_bindings() {
    echo -e "${BOLD}${GREEN}AEROSPACE KEYBINDINGS${NC}\n"
    echo -e "${CYAN}Window Navigation${NC}"
    echo -e "  ${YELLOW}alt+h/j/k/l>${NC} - Focus window in direction"
    echo -e ""
    
    echo -e "${CYAN}Window Movement${NC}"
    echo -e "  ${YELLOW}alt+ctrl+h/j/k/l>${NC} - Move window in direction"
    echo -e ""
    
    echo -e "${CYAN}Window Resizing${NC}"
    echo -e "  ${YELLOW}alt+shift+h/j/k/l>${NC} - Smart resize window"
    echo -e "  ${YELLOW}alt+minus/equal>${NC} - Decrease/increase window size"
    echo -e ""
    
    echo -e "${CYAN}Workspaces${NC}"
    echo -e "  ${YELLOW}alt+1/2/3/4>${NC} - Switch to workspace"
    echo -e "  ${YELLOW}alt+shift+1/2/3/4>${NC} - Move window to workspace"
    echo -e "  ${YELLOW}alt+tab>${NC} - Toggle between workspaces"
    echo -e "  ${YELLOW}alt+shift+tab>${NC} - Move workspace to monitor"
    echo -e ""
}

# Print wezterm keybindings
print_wezterm_bindings() {
    echo -e "${BOLD}${GREEN}WEZTERM KEYBINDINGS${NC}\n"
    echo -e "${CYAN}Panes and Tabs${NC}"
    echo -e "  ${YELLOW}cmd+d>${NC} - Split horizontally"
    echo -e "  ${YELLOW}cmd+shift+d>${NC} - Split vertically"
    echo -e "  ${YELLOW}cmd+w>${NC} - Close pane"
    echo -e "  ${YELLOW}cmd+shift+w>${NC} - Close tab"
    echo -e ""
    
    echo -e "${CYAN}Navigation${NC}"
    echo -e "  ${YELLOW}ctrl+h/j/k/l>${NC} - Navigate between panes"
    echo -e "  ${YELLOW}ctrl+arrows>${NC} - Resize panes"
    echo -e ""
    
    echo -e "${CYAN}Misc Commands${NC}"
    echo -e "  ${YELLOW}cmd+k>${NC} - Clear scrollback"
    echo -e "  ${YELLOW}cmd+shift+p>${NC} - Command palette"
    echo -e "  ${YELLOW}cmd+shift+f>${NC} - Activate copy mode"
    echo -e "  ${YELLOW}cmd+r>${NC} - Reload configuration"
    echo -e ""
}

# Print integration tips
print_integration_tips() {
    echo -e "${BOLD}${GREEN}INTEGRATION TIPS${NC}\n"
    echo -e "${CYAN}Navigation Between Programs${NC}"
    echo -e "  • ${BOLD}Use ctrl+h/j/k/l${NC} for seamless navigation between Neovim splits and WezTerm panes"
    echo -e "  • ${BOLD}Use alt+h/j/k/l${NC} for navigating Aerospace windows"
    echo -e "  • ${BOLD}Use <leader>w keys${NC} for window operations inside Neovim"
    echo -e ""
    
    echo -e "${CYAN}Terminal Tips${NC}"
    echo -e "  • Terminal tabs now show the running process name"
    echo -e "  • Increased font size for better readability"
    echo -e "  • ZSH red highlight blocks have been removed"
    echo -e ""
    
    echo -e "${CYAN}Notifications${NC}"
    echo -e "  • Toggle notifications with ${BOLD}<leader>tn${NC}"
    echo -e "  • View error history with ${BOLD}<leader>ne${NC}"
    echo -e "  • Dismiss all notifications with ${BOLD}<leader>nd${NC}"
    echo -e ""
}

# Main function
main() {
    clear
    print_header
    
    echo -e "This help document provides an overview of keyboard shortcuts and features."
    echo -e "The configuration integrates WezTerm, Neovim, and Aerospace for a seamless experience.\n"
    
    print_keybindings
    echo -e ""
    print_aerospace_bindings
    echo -e ""
    print_wezterm_bindings
    echo -e ""
    print_integration_tips
    
    echo -e "\n${BOLD}${BLUE}Press q to exit${NC}"
    read -n 1 -s key
    if [[ $key = q ]]; then
        clear
        exit 0
    fi
}

# Execute main function
main
