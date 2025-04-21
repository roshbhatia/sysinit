-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/folke/which-key.nvim/refs/heads/main/doc/which-key.nvim.txt"
local M = {}

M.plugins = {
  {
    "folke/which-key.nvim",
    lazy = false,
    dependencies = { "echasnovski/mini.icons" },
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    config = function()
      local wk = require("which-key")
      
      wk.setup({
        plugins = {
          marks = true,
          registers = true,
          spelling = {
            enabled = true,
            suggestions = 20,
          },
          presets = {
            operators = true,
            motions = true,
            text_objects = true,
            windows = true,
            nav = true,
            z = true,
            g = true,
          },
        },
        win = {
          border = "rounded",
          padding = { 2, 2, 2, 2 },
        },
        layout = {
          spacing = 3,
        },
        icons = {
          breadcrumb = "»",
          separator = "➜",
          group = "+",
        },
        show_help = true,
        show_keys = true,
        -- use automatic trigger detection
        triggers = { { "<auto>", mode = "nxsotc" } },
      })
      
      wk.add({
        { "<leader>f", group = "Find/Files", icon = { icon = "󰍉", hl = "WhichKeyIconPurple" }, action = "search-preview.quickOpenWithPreview" }, -- vscode actions: search-preview.quickOpenWithPreview, workbench.action.findInFiles, workbench.action.showAllEditors, workbench.action.showAllSymbols, workbench.action.openRecent
        { "<leader>b", group = "Buffers", icon = { icon = "󰓩", hl = "WhichKeyIconBlue" }, action = "workbench.action.nextEditor" }, -- vscode actions: workbench.action.nextEditor, workbench.action.previousEditor, workbench.action.closeActiveEditor, workbench.action.closeOtherEditors
        { "<leader>w", group = "Windows", icon = { icon = "󰖮", hl = "WhichKeyIconCyan" }, action = "workbench.action.focusLeftGroup" }, -- vscode actions: workbench.action.focusLeftGroup, workbench.action.focusBelowGroup, workbench.action.focusAboveGroup, workbench.action.focusRightGroup, workbench.action.evenEditorWidths, workbench.action.toggleEditorWidths, workbench.action.closeActiveEditor, workbench.action.closeOtherEditors, workbench.action.moveEditorToLeftGroup, workbench.action.moveEditorToBelowGroup, workbench.action.moveEditorToAboveGroup, workbench.action.moveEditorToRightGroup
        { "<leader>g", group = "Git", icon = { icon = "", hl = "WhichKeyIconRed" }, action = "git.stage" }, -- vscode actions: git.stage, git.stageAll, git.unstage, git.unstageAll, git.commit, git.commitAll, git.push, git.pull, git.openChange, git.openAllChanges, git.checkout, git.fetch, git.revertChange, workbench.view.scm, workbench.action.chat.open
        { "<leader>u", group = "UI", icon = { icon = "⚙️", hl = "WhichKeyIconYellow" }, action = "workbench.action.toggleActivityBarVisibility" },
        { "<leader>c", group = "Code", icon = { icon = "💻", hl = "WhichKeyIconBlue" }, action = "editor.action.quickFix" },
        { "<leader>t", group = "Toggle", icon = { icon = "🔧", hl = "WhichKeyIconCyan" }, action = "workbench.view.explorer" },
        { "<leader>a", group = "AI", icon = { icon = "🤖", hl = "WhichKeyIconMagenta" }, action = "workbench.action.chat.open" },
        { "<leader>s", group = "Stage/Split", icon = { icon = "✂️", hl = "WhichKeyIconGreen" }, action = "git.diff.stageHunk" },
        { "<leader>l", group = "LSP", icon = { icon = "󰒕", hl = "WhichKeyIconBlue" } },
        { "<leader>s", group = "Session", icon = { icon = "󱂬", hl = "WhichKeyIconCyan" } },
        { "<leader>c", group = "Comment", icon = { icon = "󰅺", hl = "WhichKeyIconGreen" } },
        { "<leader>o", group = "Oil", icon = { icon = "󰏘", hl = "WhichKeyIconBlue" } },
        { "<leader>e", group = "Explorer", icon = { icon = "🌲", hl = "WhichKeyIconGreen" } },
        { "<leader>m", group = "Minimap", icon = { icon = "🗺️", hl = "WhichKeyIconBlue" } },
        
        { "<leader>;", ":", desc = "Command Mode", mode = "n" },
        
        { "<leader>bd", "<cmd>bdelete<cr>", desc = "Delete Buffer", mode = "n" },
        { "<leader>bn", "<cmd>bnext<cr>", desc = "Next Buffer", mode = "n" },
        { "<leader>bp", "<cmd>bprevious<cr>", desc = "Previous Buffer", mode = "n" },
        { "<leader>bN", "<cmd>enew<cr>", desc = "New Buffer", mode = "n" },
        { "<leader>bl", "<cmd>Telescope buffers<cr>", desc = "List Buffers", mode = "n" },
      })
      
      vim.keymap.set("n", "<leader>W", function()
        require("which-key").show({
          keys = "<c-w>",
          mode = "n", 
          loop = true -- Keep popup open until <esc>
        })
      end, { desc = "Window Hydra Mode" })
    end
  }
}

return M