#!/bin/bash

print_navigation() {
    echo "Navigation Commands:"
    echo "  alt + h         Focus left"
    echo "  alt + j         Focus down"
    echo "  alt + k         Focus up"
    echo "  alt + l         Focus right"
    echo "  alt + tab       Switch to last workspace"
}

print_window_management() {
    echo "Window Management:"
    echo "  alt + ctrl + h/j/k/l   Move window"
    echo "  alt + h/j/k/l          Focus window"
    echo "  alt + shift + h/l      Cycle width (1/4 -> 1/3 -> 1/2 -> 2/3 -> 3/4)"
    echo "  alt + shift + j/k      Cycle height (1/4 -> 1/3 -> 1/2 -> 2/3 -> 3/4)"
    echo "  alt + minus            Decrease window size (smart)"
    echo "  alt + equal            Increase window size (smart)"
}

print_layout() {
    echo "Layout Controls:"
    echo "  alt + slash         Toggle between tiles horizontal/vertical"
    echo "  alt + comma         Toggle between accordion horizontal/vertical"
    echo "  Mode service + f    Toggle floating/tiling"
    echo "  Mode service + r    Reset/flatten layout"
}

print_workspace() {
    echo "Workspace Management:"
    echo "  alt + [1-9]         Switch to workspace 1-9"
    echo "  alt + [a-z]         Switch to workspace A-Z"
    echo "  alt + shift + [1-9] Move window to workspace 1-9"
    echo "  alt + shift + [a-z] Move window to workspace A-Z"
}

print_mode() {
    echo "Mode Commands:"
    echo "  alt + shift + ;     Enter service mode"
    echo "  esc                 Exit service mode"
}

print_service() {
    echo "Service Mode Commands:"
    echo "  backspace           Close all windows except current"
    echo "  up/down            Volume control"
    echo "  shift + down       Mute volume"
}

print_all() {
    print_navigation
    echo
    print_window_management
    echo
    print_layout
    echo
    print_workspace
    echo
    print_mode
    echo
    print_service
}

case "$1" in
    "nav")
        print_navigation
        ;;
    "window")
        print_window_management
        ;;
    "layout")
        print_layout
        ;;
    "workspace")
        print_workspace
        ;;
    "mode")
        print_mode
        ;;
    "service")
        print_service
        ;;
    *)
        print_all
        ;;
esac