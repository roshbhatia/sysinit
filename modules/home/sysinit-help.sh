#!/bin/bash

# Colors for better readability
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_header() {
    echo "
 ╭───────────────────────────────────────╮
 │         🚀 SysInit Help 🚀            │
 ╰───────────────────────────────────────╯
"
}

print_wezterm() {
    echo -e "${BLUE}📟 WezTerm Key Bindings:${NC}"
    echo "  LEADER: CMD (macOS)"
    echo "  CMD + d                Split horizontally"
    echo "  CMD + SHIFT + d        Split vertically"
    echo "  CMD + w                Close pane"
    echo "  CMD + SHIFT + w        Close tab"
    echo "  CTRL + h/j/k/l         Navigate between panes (smart integration with Neovim)"
    echo "  CMD + arrows           Alternative pane navigation"
    echo "  CMD + SHIFT + arrows   Navigate words"
    echo "  CMD + k                Clear scrollback"
    echo "  CMD + SHIFT + p        Command palette"
    echo "  CMD + SHIFT + f        Copy mode"
    echo "  CMD + r                Reload configuration"
}

print_aerospace() {
    echo -e "${BLUE}🪟 Aerospace (Window Manager):${NC}"
    echo "  LEADER: ALT (Option) key"
    echo "  ALT + h/j/k/l          Focus window left/down/up/right"
    echo "  ALT + CTRL + h/j/k/l   Move window left/down/up/right"
    echo "  ALT + SHIFT + h/j/k/l  Resize window left/down/up/right"
    echo "  ALT + [1-4]            Switch to workspace 1-4"
    echo "  ALT + SHIFT + [1-4]    Move window to workspace 1-4"
    echo "  ALT + tab              Switch to last workspace"
    echo "  ALT + slash            Toggle between tiles horizontal/vertical"
    echo "  ALT + comma            Toggle between accordion horizontal/vertical"
    echo "  ALT + f                Toggle fullscreen"
    echo "  ALT + SHIFT + ;        Enter service mode"
}

print_neovim_basic() {
    echo -e "${BLUE}🧠 Neovim Essentials:${NC}"
    echo "  LEADER: SPACE key"
    echo
    echo "  Navigation:"
    echo "  SPACE + ff             Find files"
    echo "  SPACE + fg             Find text in files (grep)"
    echo "  SPACE + fb             Find buffers"
    echo "  SPACE + e              File explorer"
    echo "  CTRL + p               Quick find files (like VS Code)"
    echo
    echo "  Window Management:"
    echo "  SPACE + wv/SPACE + \\   Split vertically"
    echo "  SPACE + ws/SPACE + -   Split horizontally"
    echo "  CTRL + h/j/k/l         Navigate splits (smart integration with WezTerm)"
    echo "  CTRL + arrows          Resize splits"
    echo "  SPACE + wc             Close window"
    echo "  SPACE + wo             Close other windows"
    echo
    echo "  Editing:"
    echo "  CTRL + s               Save file (works in insert mode too)"
    echo "  SPACE + ca             Code actions"
    echo "  SPACE + fm/cf          Format document"
    echo "  jk or kj               Exit insert mode"
    echo
    echo "  Code Navigation:"
    echo "  gd                     Go to definition"
    echo "  gr                     Show references"
    echo "  K                      Show hover information"
    echo "  SPACE + ha             Add file to harpoon"
    echo "  SPACE + hh             Harpoon menu"
    echo
    echo "  Run 'sysinit-help neovim-full' for more advanced features"
}

print_neovim_full() {
    echo -e "${BLUE}🧠 Neovim Advanced Features:${NC}"
    echo "  LEADER: SPACE key"
    echo
    echo "  Buffers:"
    echo "  SHIFT + h/l            Previous/next buffer"
    echo "  SPACE + bn/bp          Next/previous buffer"
    echo "  SPACE + bc/bd          Close buffer"
    echo "  SPACE + bo             Close other buffers"
    echo
    echo "  Code Navigation:"
    echo "  SPACE + to             Toggle outline"
    echo "  SPACE + cl             Line diagnostics"
    echo "  [d / ]d                Previous/next diagnostic"
    echo "  [g / ]g                Previous/next git hunk"
    echo
    echo "  Git Commands:"
    echo "  SPACE + gg             Open LazyGit"
    echo "  SPACE + gp             Preview git hunk"
    echo "  SPACE + gb             Git blame line"
    echo "  SPACE + gs             Stage hunk"
    echo
    echo "  UI Toggles:"
    echo "  SPACE + tn             Toggle line numbers"
    echo "  SPACE + tr             Toggle relative numbers"
    echo "  SPACE + th             Toggle search highlight"
    echo "  SPACE + tw             Toggle word wrap"
    echo
    echo "  Copilot:"
    echo "  SPACE + cc             Copilot Chat"
    echo "  SPACE + ce             Explain code"
    echo "  SPACE + ct             Generate tests"
    echo "  SPACE + cf             Fix code"
    echo
    echo "  Debugging:"
    echo "  SPACE + db             Toggle breakpoint"
    echo "  SPACE + dc             Continue/Start debug"
    echo "  SPACE + du             Toggle debug UI"
    echo
    echo "  Session Management:"
    echo "  SPACE + ss             Load session from current dir"
    echo "  SPACE + sl             Load last session"
}

print_terminal() {
    echo -e "${BLUE}🧑‍💻 Terminal & ZSH Shortcuts:${NC}"
    echo "  LEADER: CTRL key for most operations"
    echo
    echo "  CTRL + r               Search command history with fzf"
    echo "  CTRL + t               Find files with fzf"
    echo "  CTRL + h/j/k/l         Move cursor (consistent with Neovim/WezTerm)"
    echo "  CTRL + a/e             Start/end of line"
    echo "  CTRL + s               Start forward search (with zsh shift-select enabled)"
    echo "  CTRL + p               Previous command from history"
    echo "  CTRL + n               Next command from history"
    echo "  crepo                  Change to repository directory"
    echo "  nix-rollback           Rollback nix system to previous generation"
    echo "  sysinit-help           Show this help"
    echo "  sysinit-help [tool]    Show help for specific tool"
}

print_consistency() {
    echo -e "${YELLOW}⚙️ Keystroke Consistency Guide:${NC}"
    echo "  This system is configured for consistent keystrokes across tools:"
    echo
    echo "  Navigation: CTRL + h/j/k/l"
    echo "  - Works in Neovim for window navigation"
    echo "  - Works in WezTerm for pane navigation"
    echo "  - Smart integration: when in Neovim inside WezTerm, keystrokes pass through"
    echo
    echo "  Window management:"
    echo "  - Neovim: SPACE (leader) + window commands"
    echo "  - WezTerm: CMD + split commands"
    echo "  - Aerospace: ALT + window commands"
    echo
    echo "  Workspaces & Tabs:"
    echo "  - Aerospace: ALT + [1-4] for workspaces"
    echo "  - WezTerm: CMD + [number] for tabs"
    echo
    echo "  Command palettes:"
    echo "  - Neovim: SPACE + p or CTRL + p (files)"
    echo "  - WezTerm: CMD + SHIFT + p"
    echo
    echo "  Each tool has a consistent LEADER key:"
    echo "  - Neovim: SPACE"
    echo "  - WezTerm: CMD (macOS)"
    echo "  - Aerospace: ALT (Option)"
    echo "  - Terminal: CTRL"
}

print_all() {
    print_header
    print_consistency
    echo
    print_wezterm
    echo
    print_aerospace
    echo
    print_neovim_basic
    echo
    print_terminal
    echo
    echo -e "${YELLOW}For more detailed help on each tool:${NC}"
    echo "  sysinit-help wezterm    - WezTerm terminal help"
    echo "  sysinit-help aerospace  - Aerospace window manager help"
    echo "  sysinit-help neovim     - Basic Neovim help"
    echo "  sysinit-help neovim-full - Complete Neovim help"
    echo "  sysinit-help terminal   - Terminal/ZSH help"
    echo "  sysinit-help consistency - Keystroke consistency guide"
}

case "$1" in
    "wezterm")
        print_header
        print_wezterm
        ;;
    "aerospace")
        print_header
        print_aerospace
        ;;
    "neovim")
        print_header
        print_neovim_basic
        ;;
    "neovim-full")
        print_header
        print_neovim_basic
        echo
        print_neovim_full
        ;;
    "terminal")
        print_header
        print_terminal
        ;;
    "consistency")
        print_header
        print_consistency
        ;;
    *)
        print_all
        ;;
esac