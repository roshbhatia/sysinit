local verify = require("core.verify")

local M = {}

M.plugins = {
  {
    "folke/trouble.nvim",
    lazy = true,
    cmd = { "Trouble", "TroubleToggle" },
    dependencies = { 
      "nvim-tree/nvim-web-devicons",
      "mrjones2014/legendary.nvim"
    },
    config = function()
      require("trouble").setup({
        position = "bottom",
        height = 10,
        width = 50,
        icons = true,
        mode = "workspace_diagnostics",
        fold_open = "",
        fold_closed = "",
        group = true,
        padding = true,
        action_keys = {
          close = "q",
          cancel = "<esc>",
          refresh = "r",
          jump = {"<cr>", "<tab>"},
          open_split = {"<c-x>"},
          open_vsplit = {"<c-v>"},
          open_tab = {"<c-t>"},
          jump_close = {"o"},
          toggle_mode = "m",
          toggle_preview = "P",
          hover = "K",
          preview = "p",
          close_folds = {"zM", "zm"},
          open_folds = {"zR", "zr"},
          toggle_fold = {"zA", "za"},
          previous = "k",
          next = "j"
        },
        indent_lines = true,
        auto_open = false,
        auto_close = false,
        auto_preview = true,
        auto_fold = false,
        auto_jump = {"lsp_definitions"},
        signs = {
          error = "",
          warning = "",
          hint = "",
          information = "",
          other = "﫠"
        },
        use_diagnostic_signs = false
      })
    end
  }
}

function M.setup()
  local legendary = require("legendary")

  -- Which-key bindings
  local which_key_bindings = {
    {
      "<leader>d",
      group = "+Diagnostics",
      desc = "Diagnostics Actions"
    },
    {
      "<leader>dt",
      "<cmd>TroubleToggle workspace_diagnostics<CR>",
      desc = "Toggle workspace diagnostics"
    },
    {
      "<leader>dd",
      "<cmd>TroubleToggle document_diagnostics<CR>",
      desc = "Toggle document diagnostics"
    },
    {
      "<leader>dq",
      "<cmd>TroubleToggle quickfix<CR>",
      desc = "Toggle quickfix list"
    },
    {
      "<leader>dl",
      "<cmd>TroubleToggle loclist<CR>",
      desc = "Toggle location list"
    },
    {
      "<leader>dr",
      "<cmd>TroubleToggle lsp_references<CR>",
      desc = "Toggle LSP references"
    }
  }

  -- Command Palette Commands
  local command_palette_commands = {
    {
      description = "Trouble: Toggle workspace diagnostics",
      command = "<cmd>TroubleToggle workspace_diagnostics<CR>",
      category = "Diagnostics"
    },
    {
      description = "Trouble: Toggle document diagnostics",
      command = "<cmd>TroubleToggle document_diagnostics<CR>",
      category = "Diagnostics"
    },
    {
      description = "Trouble: Toggle quickfix list",
      command = "<cmd>TroubleToggle quickfix<CR>",
      category = "Diagnostics"
    },
    {
      description = "Trouble: Toggle location list",
      command = "<cmd>TroubleToggle loclist<CR>",
      category = "Diagnostics"
    },
    {
      description = "Trouble: Toggle LSP references",
      command = "<cmd>TroubleToggle lsp_references<CR>",
      category = "Diagnostics"
    }
  }

  -- Register with Legendary
  legendary.keymaps(which_key_bindings)
  legendary.commands(command_palette_commands)

  -- Register verification steps
  verify.register_verification("trouble", {
    {
      desc = "Trouble Toggle",
      command = ":TroubleToggle workspace_diagnostics",
      expected = "Should open Trouble diagnostics panel"
    },
    {
      desc = "Legendary Keybindings",
      command = "Which-key <leader>d",
      expected = "Should show Trouble diagnostics commands"
    },
    {
      desc = "Command Palette Trouble Commands",
      command = ":Legendary commands",
      expected = "Should show Trouble commands in Command Palette"
    }
  })
end

return M