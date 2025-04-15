local verify = require("core.verify")

local M = {}

M.plugins = {
  {
    "nvim-tree/nvim-tree.lua",
    lazy = false,
    dependencies = { 
      "nvim-tree/nvim-web-devicons"
    },
    config = function()
      -- Recommended settings from nvim-tree documentation
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
      
      require("nvim-tree").setup({
        sort_by = "case_sensitive",
        view = {
          width = 30,
          adaptive_size = false,
        },
        renderer = {
          group_empty = true,
          highlight_git = true,
          icons = {
            show = {
              git = true,
              folder = true,
              file = true,
              folder_arrow = true,
            },
            glyphs = {
              default = "",
              symlink = "",
              git = {
                unstaged = "✗",
                staged = "✓",
                unmerged = "",
                renamed = "➜",
                untracked = "★",
                deleted = "",
                ignored = "◌",
              },
              folder = {
                arrow_open = "",
                arrow_closed = "",
                default = "",
                open = "",
                empty = "",
                empty_open = "",
                symlink = "",
                symlink_open = "",
              },
            },
          },
        },
        filters = {
          dotfiles = false,
        },
        git = {
          enable = true,
          ignore = false,
          timeout = 500,
        },
        actions = {
          open_file = {
            quit_on_open = false,
            resize_window = true,
            window_picker = {
              enable = true,
            },
          },
        },
        diagnostics = {
          enable = true,
          show_on_dirs = true,
          icons = {
            hint = "",
            info = "",
            warning = "",
            error = "",
          },
        },
      })
      
      -- Auto open NvimTree when Neovim starts
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          -- Only open if a directory or no file is specified
          if vim.fn.argc() == 0 or vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
            vim.cmd("NvimTreeOpen")
          end
        end,
      })
    end
  }
}

function M.setup()
  local commander = require("commander")

  -- Register nvim-tree commands with commander
  commander.add({
    {
      desc = "Toggle NvimTree",
      cmd = "<cmd>NvimTreeToggle<CR>",
      keys = { "n", "<leader>e" },
      cat = "Explorer"
    },
    {
      desc = "Find File in NvimTree",
      cmd = "<cmd>NvimTreeFindFile<CR>",
      keys = { "n", "<leader>ef" },
      cat = "Explorer"
    },
    {
      desc = "Refresh NvimTree",
      cmd = "<cmd>NvimTreeRefresh<CR>",
      keys = { "n", "<leader>er" },
      cat = "Explorer"
    },
    {
      desc = "Collapse NvimTree",
      cmd = "<cmd>NvimTreeCollapse<CR>",
      keys = { "n", "<leader>ec" },
      cat = "Explorer"
    },
    {
      desc = "Focus NvimTree",
      cmd = "<cmd>NvimTreeFocus<CR>",
      keys = { "n", "<leader>eo" },
      cat = "Explorer"
    }
  })
  
  -- Register verification steps
  verify.register_verification("nvim-tree", {
    {
      desc = "NvimTree Toggle",
      command = ":NvimTreeToggle",
      expected = "Should toggle NvimTree file explorer"
    },
    {
      desc = "NvimTree Find File",
      command = ":NvimTreeFindFile",
      expected = "Should find and highlight current file in NvimTree"
    },
    {
      desc = "Commander Keybindings",
      command = "<leader>e",
      expected = "Should toggle NvimTree explorer"
    },
    {
      desc = "Commander Commands",
      command = ":Telescope commander filter cat=Explorer",
      expected = "Should show NvimTree commands in Commander palette"
    }
  })
end

return M