local M = {}

M.keybindings = {
    f = {
        name = "󰈔 Find",
        bindings = {
            { key = "f", description = "󰈞 Find Files", action = "workbench.action.quickOpen" },
            { key = "g", description = "󰱽 Live Grep", action = "workbench.action.findInFiles" },
            { key = "b", description = "󰋚 Find Buffers", action = "workbench.action.showAllEditors" },
            { key = "s", description = "󰥨 Find Symbols", action = "workbench.action.showAllSymbols" },
            { key = "r", description = "󰋚 Recent Files", action = "workbench.action.openRecent" }
        }
    },
    w = {
        name = "󰖮 Window",
        bindings = {
            { key = "h", description = "Focus Left", action = "workbench.action.focusLeftGroup" },
            { key = "j", description = "Focus Down", action = "workbench.action.focusDownGroup" },
            { key = "k", description = "Focus Up", action = "workbench.action.focusUpGroup" },
            { key = "l", description = "Focus Right", action = "workbench.action.focusRightGroup" },
            { key = "=", description = "Equal Width", action = "workbench.action.evenEditorWidths" },
            { key = "_", description = "Max Width", action = "workbench.action.toggleEditorWidths" },
            { key = "w", description = "Close Editor", action = "workbench.action.closeActiveEditor" },
            { key = "o", description = "Close Others", action = "workbench.action.closeOtherEditors" },
            { key = "H", description = "Move Left", action = "workbench.action.moveEditorToLeftGroup" },
            { key = "J", description = "Move Down", action = "workbench.action.moveEditorToBelowGroup" },
            { key = "K", description = "Move Up", action = "workbench.action.moveEditorToAboveGroup" },
            { key = "L", description = "Move Right", action = "workbench.action.moveEditorToRightGroup" }
        }
    },
    u = {
        name = "󰘎 UI",
        bindings = {
            { key = "a", description = "Toggle Activity Bar", action = "workbench.action.toggleActivityBarVisibility" },
            { key = "s", description = "Toggle Status Bar", action = "workbench.action.toggleStatusbarVisibility" },
            { key = "t", description = "Toggle Tab Bar", action = "workbench.action.toggleTabsVisibility" },
            { key = "b", description = "Toggle Side Bar", action = "workbench.action.toggleSidebarVisibility" },
            { key = "z", description = "Toggle Zen Mode", action = "workbench.action.toggleZenMode" },
            { key = "f", description = "Toggle Full Screen", action = "workbench.action.toggleFullScreen" }
        }
    },
    b = {
        name = "󰓩 Buffer",
        bindings = {
            { key = "n", description = "Next Buffer", action = "workbench.action.nextEditor" },
            { key = "p", description = "Previous Buffer", action = "workbench.action.previousEditor" },
            { key = "d", description = "Close Buffer", action = "workbench.action.closeActiveEditor" },
            { key = "o", description = "Close Others", action = "workbench.action.closeOtherEditors" }
        }
    },
    g = {
        name = " Git",
        bindings = {
            { key = "b", description = "󰊢 Git Blame", action = "gitlens.toggleLineBlame" },
            { key = "d", description = "󰧑 Git Diff", action = "git.openChange" },
            { key = "s", description = "󰊢 Git Status", action = "workbench.scm.focus" }
        }
    },
    c = {
        name = "󰌵 Code",
        bindings = {
            { key = "a", description = "󰌵 Code Actions", action = "editor.action.quickFix" },
            { key = "r", description = "󰑕 Rename Symbol", action = "editor.action.rename" },
            { key = "f", description = "󰉨 Format Document", action = "editor.action.formatDocument" },
            { key = "d", description = "󰞋 Go to Definition", action = "editor.action.revealDefinition" },
            { key = "i", description = "Go to Implementation", action = "editor.action.goToImplementation" },
            { key = "h", description = "Show Hover", action = "editor.action.showHover" },
            { key = "]", description = "Start Inline Chat", action = "inlineChat.start" }
        }
    },
    t = {
        name = "󰙅 Toggle",
        bindings = {
            { key = "e", description = "󰏖 Explorer", action = "workbench.view.explorer" },
            { key = "t", description = "󰙅 Terminal", action = "workbench.action.terminal.toggleTerminal" },
            { key = "p", description = "󰏘 Problems", action = "workbench.actions.view.problems" },
            { key = "o", description = "󰙀 Outline", action = "outline.focus" },
            { key = "c", description = "󰚩 Copilot Chat", action = "github.copilot.chat.focus" },
            { key = "b", description = "󰌽 Return to Editor", action = "workbench.action.focusActiveEditorGroup" },
            { key = "m", description = "⌘ Command Palette", action = "workbench.action.showCommands" }
        }
    }
}

return M
