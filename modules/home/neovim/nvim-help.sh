#!/bin/bash

print_navigation() {
    echo "Navigation Commands:"
    echo "  <leader>ff     Find files"
    echo "  <leader>fg     Find text in files (live grep)"
    echo "  <leader>fb     Find buffers"
    echo "  <leader>fh     Find help tags"
    echo "  <F2>           Toggle file explorer (NvimTree)"
}

print_code() {
    echo "Code Navigation:"
    echo "  gd             Go to definition"
    echo "  gr             Find references"
    echo "  gi             Go to implementation"
    echo "  K              Show hover information"
    echo "  <leader>rn     Rename symbol"
    echo "  <leader>ca     Code actions"
    echo "  <leader>e      Show line diagnostics"
    echo "  <leader>tt     Toggle trouble (diagnostic list)"
    echo "  <leader>so     Toggle symbols outline"
    echo "  <leader>to     Toggle aerial (code outline)"
}

print_editor() {
    echo "Editor Commands:"
    echo "  <leader>fm     Format document"
    echo "  <leader>nl     Add newline"
    echo "  <leader>nld    Remove newline"
    echo "  gc + motion    Comment/uncomment lines (e.g. gcc for current line)"
    echo "  <F1>           Open Startify (sessions/recent files)"
    echo "  <C-\>          Toggle terminal"
    echo "  <C-Space>      Trigger completion"
}

print_git() {
    echo "Git Commands:"
    echo "  <leader>gb     Toggle Git blame"
    echo "  <leader>gd     Git diff"
    echo "  <leader>gp     Git preview hunk"
    echo "  <leader>gr     Git reset hunk"
    echo "  <leader>gs     Git status"
}

print_copilot() {
    echo "Copilot Commands:"
    echo "  <leader>cc     Toggle Copilot"
    echo "  <leader>cs     Show Copilot suggestions"
    echo "  <leader>cd     Open Copilot panel"
    echo "  <leader>cr     Request explanation (Copilot Chat)"
}

print_kubernetes() {
    echo "Kubernetes Commands:"
    echo "  <leader>kl     Get pod logs"
    echo "  <leader>kp     List pods"
    echo "  <leader>kd     Describe resource"
}

print_all() {
    print_navigation
    echo
    print_code
    echo
    print_editor
    echo
    print_git
    echo
    print_copilot
    echo
    print_kubernetes
}

case "$1" in
    "nav")
        print_navigation
        ;;
    "code")
        print_code
        ;;
    "editor")
        print_editor
        ;;
    "git")
        print_git
        ;;
    "copilot")
        print_copilot
        ;;
    "k8s")
        print_kubernetes
        ;;
    *)
        print_all
        ;;
esac