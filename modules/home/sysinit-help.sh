#!/bin/bash

print_header() {
    echo "
 ╭───────────────────────────────────────╮
 │         🚀 SysInit Help 🚀            │
 ╰───────────────────────────────────────╯
"
}

print_wezterm() {
    echo "📟 WezTerm Key Bindings:"
    echo "  CMD + d                Split horizontally"
    echo "  CMD + SHIFT + d        Split vertically"
    echo "  CMD + w                Close pane"
    echo "  CMD + SHIFT + w        Close tab"
    echo "  CMD + arrows           Navigate between panes"
    echo "  CMD + SHIFT + arrows   Navigate words"
    echo "  CMD + k                Clear scrollback"
    echo "  CMD + SHIFT + p        Command palette"
    echo "  CMD + SHIFT + f        Copy mode"
    echo "  CMD + r                Reload configuration"
}

print_aerospace() {
    echo "🪟 Aerospace (Window Manager):"
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

print_neovim() {
    echo "🧠 Neovim Essentials:"
    echo "  SPACE                  Leader key"
    echo "  SPACE + ff             Find files"
    echo "  SPACE + fg             Find text in files (grep)"
    echo "  SPACE + pv             File explorer"
    echo "  SPACE + \\\\             Split vertically"
    echo "  SPACE + -              Split horizontally"
    echo "  CTRL + h/j/k/l         Navigate splits"
    echo "  SPACE + j/k            Move line down/up (changed from ALT+j/k)"
    echo "  SPACE + J/K            Duplicate line down/up"
    echo "  SPACE + [1-9]          Go to buffer 1-9 (changed from ALT+[1-9])"
    echo "  CTRL + s               Save file"
    echo "  SPACE + p              Command palette"
    echo "  CTRL + d               Multi-cursor selection"
    echo "  SPACE + fm             Format document"
    echo "  gd                     Go to definition"
    echo "  K                      Show hover information"
}

print_terminal() {
    echo "🧑‍💻 Terminal Shortcuts:"
    echo "  CTRL + r               Search command history with fzf"
    echo "  CTRL + t               Find files with fzf"
    echo "  crepo                  Change to repository directory"
    echo "  nix-rollback           Rollback nix system to previous generation"
    echo "  CTRL + s               Start forward search (with zsh shift-select enabled)"
    echo "  CTRL + p               Previous command from history"
    echo "  CTRL + n               Next command from history"
}

print_all() {
    print_header
    print_wezterm
    echo
    print_aerospace
    echo
    print_neovim
    echo
    print_terminal
}

case "$1" in
    "wezterm")
        print_wezterm
        ;;
    "aerospace")
        print_aerospace
        ;;
    "neovim")
        print_neovim
        ;;
    "terminal")
        print_terminal
        ;;
    *)
        print_all
        ;;
esac