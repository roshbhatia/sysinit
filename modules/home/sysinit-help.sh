#!/bin/bash
BLUE='\033[1;34m'
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
    echo "  LEADER: CMD"
    echo "  CMD + SHIFT + v        Split vertically (vim-like)"
    echo "  CMD + SHIFT + s        Split horizontally (vim-like)"
    echo "  CMD + w                Smart close (closes pane → tab → window)"
    echo "  CMD + SHIFT + h/j/k/l  Navigate between panes"
    echo "  CMD + ALT + h/j/k/l    Resize panes"
    echo "  CMD + k                Clear scrollback"
    echo "  CMD + SHIFT + p        Command palette"
    echo "  CMD + y                Copy mode"
    echo "  CMD + r                Reload configuration"
    echo
    echo "  Tab Navigation:"
    echo "  CMD + [1-9]            Switch to tab 1-9"
}

print_aerospace() {
    echo -e "${BLUE}🪟 Aerospace (Window Manager):${NC}"
    echo "  LEADER: ALT (Option) key"
    echo "  ALT + h/j/k/l          Focus window left/down/up/right"
    echo "  ALT + CTRL + h/j/k/l   Swap window left/down/up/right"
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
    echo "  CTRL + b               Go back in jump list"
    echo "  CTRL + f               Go forward in jump list"
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
    echo "  CTRL + b / CTRL + f    Go back/forward in jump list"
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
    echo "  CTRL + y               Accept suggestion"
    echo "  CTRL + w               Accept word"
    echo "  CTRL + l               Accept line"
    echo "  CTRL + n               Next suggestion"
    echo "  CTRL + p               Previous suggestion"
    echo "  CTRL + h               Show suggestions panel"
    echo "  SPACE + cc             Copilot Chat"
    echo "  SPACE + ce             Explain code"
    echo "  SPACE + ct             Toggle Copilot"
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
    echo "  Navigation:"
    echo "  CTRL + h               Go to beginning of line"
    echo "  CTRL + j               Go back one word"
    echo "  CTRL + k               Go forward one word"
    echo "  CTRL + l               Go to end of line"
    echo
    echo "  Search:"
    echo "  CTRL + r               Search command history"
    echo
    echo "  General Commands:"
    echo "  crepo                  Change to repository directory"
    echo "  nix-rollback           Rollback nix system to previous generation"
    echo "  sysinit-help           Show this help"
    echo "  sysinit-help [tool]    Show help for specific tool"
}

print_consistency() {
    echo -e "${YELLOW}⚙️ Keystroke Consistency Guide:${NC}"
    echo -e "Each tool has a dedicated leader key and consistent modifier pattern:"
    echo
    echo -e "WezTerm (Terminal) - CMD as leader:"
    echo "  - CMD alone: Basic operations (navigation, splits, tabs)"
    echo "  - CMD+SHIFT: Advanced operations (clear, close tab)"
    echo
    echo -e "ZSH (Shell) - CTRL for navigation:"
    echo "  - CTRL+hjkl: Line/word navigation"
    echo "  - CTRL+r: History search"
    echo
    echo -e "Neovim (Editor) - SPACE as leader:"
    echo "  - SPACE alone: Most operations"
    echo "  - CTRL: Universal operations (save, etc)"
    echo
    echo -e "Aerospace (Windows) - ALT as leader:"
    echo "  - ALT alone: Basic operations (focus, workspaces)"
    echo "  - ALT+CTRL: Movement operations"
    echo "  - ALT+SHIFT: Advanced operations (resize, workspace moves)"
    echo
    echo -e "Common Patterns:"
    echo "  Navigation: h/j/k/l keys for all directional operations"
    echo "  Numbers: 1-9 for switching workspaces/tabs"
    echo "  Advanced ops: Adding SHIFT to basic operations"
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