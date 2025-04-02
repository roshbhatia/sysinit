#!/bin/bash

print_navigation() {
    echo "Navigation Commands:"
    echo "  cmd + arrows      Navigate between panes"
    echo "  alt + left/right  Navigate words"
}

print_selection() {
    echo "Selection Commands:"
    echo "  alt + shift + h   Select left"
    echo "  alt + shift + j   Select down"
    echo "  alt + shift + k   Select up"
    echo "  alt + shift + l   Select right"
    echo "  alt + shift + arrows   Select by word"
}

print_pane_management() {
    echo "Pane Management:"
    echo "  cmd + d           Split horizontally"
    echo "  cmd + shift + d   Split vertically"
    echo "  cmd + w           Close pane"
    echo "  cmd + shift + w   Close tab"
}

print_special() {
    echo "Special Commands:"
    echo "  cmd + k           Clear scrollback"
    echo "  cmd + shift + p   Command palette"
    echo "  cmd + shift + f   Copy mode"
}

print_all() {
    print_navigation
    echo
    print_selection
    echo
    print_pane_management
    echo
    print_special
}

case "$1" in
    "nav")
        print_navigation
        ;;
    "select")
        print_selection
        ;;
    "pane")
        print_pane_management
        ;;
    "special")
        print_special
        ;;
    *)
        print_all
        ;;
esac