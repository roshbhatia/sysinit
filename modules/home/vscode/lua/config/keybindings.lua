local M = {}

M.keybindings = {
    f = {
        name = "󰈔 Find",
        bindings = {
            { key = "f", description = "󰈞 Find Files", action = "workbench.action.quickOpen" },
            { key = "g", description = "󰱽 Live Grep", action = "workbench.action.findInFiles" },
            { key = "b", description = "󰋚 Find Buffers", action = "workbench.action.showAllEditors" },
            { key = "h", description = "󰋖 Find Help", action = "workbench.action.openHelp" },
            { key = "s", description = "󰥨 Find Symbols", action = "workbench.action.showAllSymbols" },
            { key = "r", description = "󰋚 Recent Files", action = "workbench.action.openRecent" }
        }
    },
    p = {
        name = "󰏖 Project/File",
        bindings = {
            { key = "f", description = "󰈞 Find in Project", action = "workbench.action.quickOpen" },
            { key = "v", description = "󰙅 Explorer Toggle", action = "workbench.view.explorer" },
            { key = "n", description = "󰎔 New File", action = "workbench.action.files.newUntitledFile" },
            { key = "s", description = "󰑓 Save File", action = "workbench.action.files.save" }
        }
    },
    b = {
        name = "󰓩 Buffer",
        bindings = {
            { key = "p", description = "Previous Buffer", action = "workbench.action.previousEditor" },
            { key = "n", description = "Next Buffer", action = "workbench.action.nextEditor" },
            { key = "c", description = "Close Buffer", action = "workbench.action.closeActiveEditor" },
            { key = "b", description = "Buffer List", action = "workbench.action.showAllEditors" }
        }
    },
    g = {
        name = " Git",
        bindings = {
            { key = "b", description = "󰊢 Git Blame", action = "gitlens.toggleLineBlame" },
            { key = "d", description = "󰧑 Git Diff", action = "git.openChange" },
            { key = "h", description = "󰊢 Preview Hunk", action = "git.openChange" },
            { key = "s", description = "󰊢 Git Status", action = "workbench.scm.focus" }
        }
    },
    x = {
        name = "󰃤 Diagnostics/Trouble",
        bindings = {
            { key = "x", description = "󰅚 Problems", action = "workbench.actions.view.problems" },
            { key = "d", description = "󰃤 Document Diagnostics", action = "workbench.actions.view.problems" },
            { key = "w", description = "󰃤 Workspace Diagnostics", action = "workbench.actions.viewAllProblems" }
        }
    },
    c = {
        name = "󰌵 Code",
        bindings = {
            { key = "a", description = "󰌵 Code Actions", action = "editor.action.quickFix" },
            { key = "r", description = "󰑕 Rename Symbol", action = "editor.action.rename" },
            { key = "f", description = "󰉨 Format Document", action = "editor.action.formatDocument" },
            { key = "d", description = "󰞋 Go to Definition", action = "editor.action.revealDefinition" }
        }
    },
    t = {
        name = "󰙅 Toggle",
        bindings = {
            { key = "e", description = "󰏖 Explorer", action = "workbench.view.explorer" },
            { key = "t", description = "󰙅 Terminal", action = "workbench.action.terminal.toggleTerminal" },
            { key = "p", description = "󰏘 Problems", action = "workbench.actions.view.problems" },
        }
    }
}

return M
