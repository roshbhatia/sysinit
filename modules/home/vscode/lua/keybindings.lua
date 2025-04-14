local M = {}

M.keybindings = {
    f = {
        name = "🔍 Find",
        bindings = {
            { key = "f", description = "Find Files (with Preview)", action = "search-preview.quickOpenWithPreview" },
            { key = "g", description = "Live Grep", action = "workbench.action.findInFiles" },
            { key = "b", description = "Find Buffers", action = "workbench.action.showAllEditors" },
            { key = "s", description = "Find in Current File", action = "actions.find" },
            { key = "k", description = "Show Keyboard Shortcuts", action = "workbench.action.openGlobalKeybindings" },
            { key = "c", description = "Show Commands", action = "workbench.action.showCommands" },
            { key = "r", description = "Recent Files (with Preview)", action = "search-preview.showAllEditorsByMostRecentlyUsed" }
        }
    },
    w = {
        name = "🪟 Window",
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
        name = "⚙️ UI",
        bindings = {
            { key = "a", description = "Toggle Activity Bar", action = "workbench.action.toggleActivityBarVisibility" },
            { key = "s", description = "Toggle Status Bar", action = "workbench.action.toggleStatusbarVisibility" },
            { key = "t", description = "Toggle Tab Bar", action = "workbench.action.toggleTabsVisibility" },
            { key = "b", description = "Toggle Side Bar", action = "workbench.action.toggleSidebarVisibility" },
            { key = "z", description = "Toggle Zen Mode", action = "workbench.action.toggleZenMode" },
            { key = "f", description = "Toggle Full Screen", action = "workbench.action.toggleFullScreen" },
            { key = "m", description = "Toggle Minimap", action = "editor.action.toggleMinimap" },
            { key = "w", description = "Toggle Word Wrap", action = "editor.action.toggleWordWrap" },
            { key = "n", description = "Toggle Line Numbers", action = "editor.action.toggleLineNumbers" },
            { key = "r", description = "Toggle Render Whitespace", action = "editor.action.toggleRenderWhitespace" }
        }
    },
    b = {
        name = "📝 Buffer",
        bindings = {
            { key = "n", description = "Next Buffer", action = "workbench.action.nextEditor" },
            { key = "p", description = "Previous Buffer", action = "workbench.action.previousEditor" },
            { key = "d", description = "Close Buffer", action = "workbench.action.closeActiveEditor" },
            { key = "o", description = "Close Others", action = "workbench.action.closeOtherEditors" }
        }
    },
    g = {
        name = "🔄 Git",
        bindings = {
            { key = "b", description = "Git Blame", action = "gitlens.toggleLineBlame" },
            { key = "d", description = "Git Diff", action = "git.openChange" },
            { key = "s", description = "Git Status", action = "workbench.scm.focus" },
            { key = "c", description = "Git Commit", action = "git.commitAll" },
            { key = "p", description = "Git Push", action = "git.push" },
            { key = "P", description = "Git Pull", action = "git.pull" },
            { key = "h", description = "Git History", action = "git.viewHistory" },
            { key = "m", description = "Generate Commit Message", action = "github.copilot.generateCommitMessage" },
            { key = "f", description = "Git Fetch", action = "git.fetch" }
        }
    },
    c = {
        name = "💻 Code",
        bindings = {
            { key = "a", description = "Code Actions", action = "editor.action.quickFix" },
            { key = "r", description = "Rename Symbol", action = "editor.action.rename" },
            { key = "f", description = "Format Document", action = "editor.action.formatDocument" },
            { key = "d", description = "Go to Definition", action = "editor.action.revealDefinition" },
            { key = "i", description = "Go to Implementation", action = "editor.action.goToImplementation" },
            { key = "h", description = "Show Hover", action = "editor.action.showHover" },
            { key = "]", description = "Next Reference", action = "editor.action.wordHighlight.next" },
            { key = "[", description = "Previous Reference", action = "editor.action.wordHighlight.prev" },
            { key = "o", description = "Organize Imports", action = "editor.action.organizeImports" },
            { key = "s", description = "Show Symbol Outline", action = "outline.focus" }
        }
    },
    t = {
        name = "🔧 Terminal",
        bindings = {
            { key = "t", description = "Toggle Terminal", action = "workbench.action.terminal.toggleTerminal" },
            { key = "n", description = "New Terminal", action = "workbench.action.terminal.new" },
            { key = "k", description = "Kill Terminal", action = "workbench.action.terminal.kill" },
            { key = "]", description = "Next Terminal", action = "workbench.action.terminal.focusNext" },
            { key = "[", description = "Previous Terminal", action = "workbench.action.terminal.focusPrevious" },
            { key = "\\", description = "Split Terminal", action = "workbench.action.terminal.split" },
            { key = "c", description = "Clear Terminal", action = "workbench.action.terminal.clear" }
        }
    },
    d = {
        name = "🛠 Development",
        bindings = {
            { key = "c", description = "Start Copilot Chat", action = "workbench.panel.chat.view.copilot.focus" },
            { key = "i", description = "Inline Chat", action = "inlineChat.start" },
            { key = "g", description = "Explain Code", action = "codegpt.explainCodeGPT" },
            { key = "d", description = "Add Doc Comments", action = "extension.addDocComments" },
            { key = "h", description = "Show Hover", action = "editor.action.showHover" }
        }
    }
}

return M
