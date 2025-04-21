-- WARNING: AUTO-GENERATED FILE. DO NOT EDIT.

local M = {}

-- VGEN-BEGIN CMD_MAP
-- map of Neovim commands (without <cmd> and <cr>) to VSCode action names
M.cmd_map = {
  w      = 'workbench.action.files.save',
  wa     = 'workbench.action.files.saveAll',
  q      = 'workbench.action.closeActiveEditor',
  qa     = 'workbench.action.quit',
  enew   = 'workbench.action.files.newUntitledFile',
  bdelete= 'workbench.action.closeActiveEditor',
  bn     = 'workbench.action.nextEditor',
  bp     = 'workbench.action.previousEditor',
  split  = 'workbench.action.splitEditorDown',
  vsplit = 'workbench.action.splitEditorRight',
}
-- VGEN-END CMD_MAP

-- VGEN-BEGIN KEYBINDINGS
  M.keybindings = {
    f = {
      name = "🔍 Find",
      bindings = {
        { key = "f", description = "Find Files",    action = "search-preview.quickOpenWithPreview" },
        { key = "g", description = "Find in Files", action = "workbench.action.findInFiles" },
        { key = "b", description = "Find Buffers",  action = "workbench.action.showAllEditors" },
        { key = "s", description = "Find Symbols",  action = "workbench.action.showAllSymbols" },
        { key = "r", description = "Recent Files",  action = "workbench.action.openRecent" }
      }
    },
    w = {
      name = "🪟 Window",
      bindings = {
        { key = "h", description = "Focus Left",   action = "workbench.action.focusLeftGroup" },
        { key = "j", description = "Focus Down",   action = "workbench.action.focusBelowGroup" },
        { key = "k", description = "Focus Up",     action = "workbench.action.focusAboveGroup" },
        { key = "l", description = "Focus Right",  action = "workbench.action.focusRightGroup" },
        { key = "=", description = "Equal Width",  action = "workbench.action.evenEditorWidths" },
        { key = "_", description = "Max Width",    action = "workbench.action.toggleEditorWidths" },
        { key = "w", description = "Close Editor", action = "workbench.action.closeActiveEditor" },
        { key = "o", description = "Close Others", action = "workbench.action.closeOtherEditors" },
        { key = "H", description = "Move Left",    action = "workbench.action.moveEditorToLeftGroup" },
        { key = "J", description = "Move Down",    action = "workbench.action.moveEditorToBelowGroup" },
        { key = "K", description = "Move Up",      action = "workbench.action.moveEditorToAboveGroup" },
        { key = "L", description = "Move Right",   action = "workbench.action.moveEditorToRightGroup" }
      }
    },
    u = {
      name = "⚙️ UI",
      bindings = {
        { key = "a", description = "Activity Bar", action = "workbench.action.toggleActivityBarVisibility" },
        { key = "s", description = "Status Bar",   action = "workbench.action.toggleStatusbarVisibility" },
        { key = "t", description = "Tab Bar",      action = "workbench.action.toggleTabsVisibility" },
        { key = "b", description = "Side Bar",     action = "workbench.action.toggleSidebarVisibility" },
        { key = "z", description = "Zen Mode",     action = "workbench.action.toggleZenMode" },
        { key = "f", description = "Full Screen",  action = "workbench.action.toggleFullScreen" }
      }
    },
    b = {
      name = "📝 Buffer",
      bindings = {
        { key = "n", description = "Next Buffer",     action = "workbench.action.nextEditor" },
        { key = "p", description = "Previous Buffer", action = "workbench.action.previousEditor" },
        { key = "d", description = "Close Buffer",    action = "workbench.action.closeActiveEditor" },
        { key = "o", description = "Close Others",    action = "workbench.action.closeOtherEditors" }
      }
    },
    g = {
      name = "🔄 Git",
      bindings = {
        { key = "s", description = "Stage Changes",           action = "git.stage" },
        { key = "S", description = "Stage All",               action = "git.stageAll" },
        { key = "u", description = "Unstage Changes",         action = "git.unstage" },
        { key = "U", description = "Unstage All",             action = "git.unstageAll" },
        { key = "c", description = "Commit",                  action = "git.commit" },
        { key = "C", description = "Commit All",              action = "git.commitAll" },
        { key = "p", description = "Push",                    action = "git.push" },
        { key = "P", description = "Pull",                    action = "git.pull" },
        { key = "d", description = "Open Change",             action = "git.openChange" },
        { key = "D", description = "Open All Changes",        action = "git.openAllChanges" },
        { key = "b", description = "Checkout Branch",         action = "git.checkout" },
        { key = "f", description = "Fetch",                   action = "git.fetch" },
        { key = "r", description = "Revert Change",           action = "git.revertChange" },
        { key = "v", description = "SCM View",                action = "workbench.view.scm" },
        { key = "m", description = "Generate Commit Message", action = "workbench.action.chat.open" }
      }
    },
    c = {
      name = "💻 Code",
      bindings = {
        { key = "a", description = "Quick Fix",            action = "editor.action.quickFix" },
        { key = "r", description = "Rename Symbol",        action = "editor.action.rename" },
        { key = "f", description = "Format Document",      action = "editor.action.formatDocument" },
        { key = "d", description = "Go to Definition",     action = "editor.action.revealDefinition" },
        { key = "i", description = "Go to Implementation", action = "editor.action.goToImplementation" },
        { key = "h", description = "Show Hover",           action = "editor.action.showHover" },
        { key = "c", description = "Toggle Comment",       action = "editor.action.commentLine" },
        { key = "s", description = "Go to Symbol",         action = "workbench.action.gotoSymbol" },
        { key = "R", description = "Find References",      action = "editor.action.goToReferences" }
      }
    },
    t = {
      name = "🔧 Toggle",
      bindings = {
        { key = "e", description = "Explorer",         action = "workbench.view.explorer" },
        { key = "t", description = "Terminal",         action = "workbench.action.terminal.toggleTerminal" },
        { key = "p", description = "Problems",         action = "workbench.actions.view.problems" },
        { key = "o", description = "Outline",          action = "outline.focus" },
        { key = "c", description = "Chat",             action = "workbench.action.chat.open" },
        { key = "b", description = "Return to Editor", action = "workbench.action.focusActiveEditorGroup" },
        { key = "m", description = "Command Palette",  action = "workbench.action.showCommands" }
      }
    },
    a = {
      name = "🤖 AI",
      bindings = {
        { key = "c", description = "Start Chat",      action = "workbench.action.chat.open" },
        { key = "i", description = "Inline Chat",     action = "inlineChat.start" },
        { key = "v", description = "View in Chat",    action = "inlineChat.viewInChat" },
        { key = "r", description = "Regenerate",      action = "inlineChat.regenerate" },
        { key = "a", description = "Accept Changes",  action = "inlineChat.acceptChanges" },
        { key = "g", description = "Generate Commit", action = "workbench.action.chat.open" }
      }
    },
    s = {
      name = "✂️ Stage/Split",
      bindings = {
        { key = "s", description = "Stage Hunk",       action = "git.diff.stageHunk" },
        { key = "S", description = "Stage Selection",  action = "git.diff.stageSelection" },
        { key = "u", description = "Unstage",          action = "git.unstage" },
        { key = "h", description = "Split Horizontal", action = "workbench.action.splitEditorDown" },
        { key = "v", description = "Split Vertical",   action = "workbench.action.splitEditorRight" }
      }
    }
  }
-- VGEN-END KEYBINDINGS

return M
