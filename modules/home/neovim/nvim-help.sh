#!/bin/bash

print_navigation() {
    echo "🧭 Navigation Commands:"
    echo "  <leader>ff     Find files (Telescope)"
    echo "  <leader>fg     Find text in files (live grep)"
    echo "  <leader>fb     Find buffers"
    echo "  <leader>fh     Find help tags"
    echo "  <leader>fs     Find symbols in document"
    echo "  <leader>fr     Find recent files"
    echo "  <F2>           Toggle file explorer (NvimTree)"
    echo "  <leader>pv     Toggle file explorer (NvimTree)"
    echo "  <leader>pf     Find file in explorer"
    echo "  <C-p>          Quick find files (like VS Code Ctrl+P)"
    echo "  <leader>p      Open command palette (like VS Code)"
}

print_code() {
    echo "📝 Code Navigation:"
    echo "  gd             Go to definition"
    echo "  gD             Go to declaration"
    echo "  gr             Find references"
    echo "  gi             Go to implementation"
    echo "  K              Show hover information"
    echo "  <C-k>          Show signature help"
    echo "  <leader>rn     Rename symbol"
    echo "  <leader>ca     Code actions"
    echo "  <leader>e      Show line diagnostics"
    echo "  <leader>xx     Toggle trouble (diagnostic list)"
    echo "  <leader>xd     Document diagnostics"
    echo "  <leader>xw     Workspace diagnostics"
    echo "  <leader>so     Toggle symbols outline"
    echo "  <leader>to     Toggle aerial (code outline)"
    echo "  ]d / [d        Next/prev diagnostic"
    echo "  ]f / [f        Next/prev function"
    echo "  ]c / [c        Next/prev class"
    echo "  {C-CR}         Expand selection (treesitter)"
    echo "  af / if        Select around/in function"
    echo "  ac / ic        Select around/in class"
    echo "  aa / ia        Select around/in parameter"
}

print_editor() {
    echo "✏️ VS Code-like Editor Commands:"
    echo "  <C-s>          Save file (works in insert mode too)"
    echo "  <C-a>          Select entire line"
    echo "  <C-d>          Add cursor at next occurrence (multi-cursor)"
    echo "  <C-S-l>        Select all occurrences (multi-cursor)"
    echo "  <A-j/k>        Move line/selection up/down"
    echo "  <S-A-j/k>      Duplicate line up/down"
    echo "  <leader>fm     Format document"
    echo "  <leader>nl     Add newline"
    echo "  <leader>nld    Remove newline"
    echo
    echo "  Comment Commands:"
    echo "  gcc            Comment current line"
    echo "  gc{motion}     Comment/uncomment lines"
    echo "  gbc            Block comment"
    echo
    echo "  Terminal & Sessions:"  
    echo "  <F1>           Open Startify (sessions)"
    echo "  <C-\\>         Toggle terminal"
    echo "  <leader>tf     Float terminal"
    echo "  <leader>th     Horizontal terminal"
    echo "  <leader>tv     Vertical terminal"
    echo "  <leader>ss     Save session"
    echo "  <leader>sl     Load session"
    echo
    echo "  UI & Navigation:"
    echo "  <C-Space>      Trigger completion"
    echo "  <M-e>          Fast bracket wrapping"
    echo "  <leader>mm     Toggle minimap (code preview)"
    echo "  <C-s>          Buffer picker"
    echo "  <A-1..9>       Go to buffer 1-9"
}

print_split() {
    echo "🪟 Window Commands (VS Code Style):"
    echo "  <leader>\\      Split vertically"
    echo "  <leader>-       Split horizontally"
    echo "  <C-h/j/k/l>    Navigate between splits"
    echo "  <C-Left/Right> Resize split width"
    echo "  <C-Up/Down>    Resize split height"
    echo "  <C-w>c         Close split"
    echo "  <C-w>o         Close all other splits"
    echo "  <C-w>=         Equal size splits"
    echo
    echo "  Traditional Vim splits also work:"
    echo "  <C-w>s         Split horizontally"
    echo "  <C-w>v         Split vertically"
    echo "  <C-w>H/J/K/L   Move splits"
    echo "  <C-w>+/-       Resize splits (height)"
    echo "  <C-w>>/&lt;     Resize splits (width)"
}

print_buffer() {
    echo "📑 Buffer Commands:"
    echo "  <leader>bp     Previous buffer"
    echo "  <leader>bn     Next buffer"
    echo "  <leader>bc     Close buffer"
    echo "  <leader>bb     Order buffers by number"
    echo "  <leader>bd     Order buffers by directory"
    echo "  <leader>bl     Order buffers by language"
}

print_git() {
    echo "🌿 Git Commands:"
    echo "  <leader>gb     Toggle Git blame"
    echo "  <leader>tb     Toggle current line blame"
    echo "  <leader>hd     Git diff this"
    echo "  <leader>hp     Git preview hunk"
    echo "  <leader>hs     Stage hunk"
    echo "  <leader>hr     Reset hunk"
    echo "  <leader>hS     Stage buffer"
    echo "  <leader>hR     Reset buffer"
    echo "  <leader>hu     Undo stage hunk"
    echo "  <leader>td     Toggle deleted hunks"
    echo "  ]c / [c        Next/previous git hunk"
}

print_copilot() {
    echo "🤖 Copilot Commands:"
    echo "  <leader>cc     Toggle Copilot"
    echo "  <leader>cs     Show Copilot suggestions"
    echo "  <leader>cd     Open Copilot panel"
    echo "  <M-l>          Accept suggestion"
    echo "  <M-w>          Accept word"
    echo "  <M-j>          Accept line"
    echo "  <M-]>/<M-[>    Next/prev suggestion"
    echo "  <C-]>          Dismiss suggestion"
    echo "  <M-CR>         Open Copilot panel"
}

print_todo() {
    echo "📋 TODO Comments:"
    echo "  <leader>ft     Find TODOs (telescope)"
    echo "  <leader>xt     List TODOs (trouble)"
    echo "  ]t / [t        Next/previous TODO"
}

print_kubernetes() {
    echo "☸️ Kubernetes Commands:"
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
    print_split
    echo
    print_buffer
    echo
    print_git
    echo
    print_copilot
    echo
    print_todo
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
    "split")
        print_split
        ;;
    "buffer")
        print_buffer
        ;;
    "git")
        print_git
        ;;
    "copilot")
        print_copilot
        ;;
    "todo")
        print_todo
        ;;
    "k8s")
        print_kubernetes
        ;;
    *)
        print_all
        ;;
esac