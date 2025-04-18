-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/folke/which-key.nvim/refs/heads/main/doc/which-key.nvim.txt"
local M = {}

M.plugins = {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
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
        triggers = "auto",
      })
      
      wk.add({
        { "<leader>f", group = "Find/Files", icon = { icon = "󰍉", hl = "WhichKeyIconPurple" } },
        { "<leader>b", group = "Buffers", icon = { icon = "󰓩", hl = "WhichKeyIconBlue" } },
        { "<leader>w", group = "Windows", icon = { icon = "󰖮", hl = "WhichKeyIconCyan" } },
        { "<leader>g", group = "Git", icon = { icon = "", hl = "WhichKeyIconRed" } },
        { "<leader>l", group = "LSP", icon = { icon = "󰒕", hl = "WhichKeyIconBlue" } },
        { "<leader>s", group = "Session", icon = { icon = "󱂬", hl = "WhichKeyIconCyan" } },
        { "<leader>c", group = "Comment", icon = { icon = "󰅺", hl = "WhichKeyIconGreen" } },
        { "<leader>o", group = "Oil", icon = { icon = "󰏘", hl = "WhichKeyIconBlue" } },
        { "<leader>e", group = "Explorer", icon = { icon = "🌲", hl = "WhichKeyIconGreen" } },
        { "<leader>m", group = "Minimap", icon = { icon = "🗺️", hl = "WhichKeyIconBlue" } },
        
        { "<leader>q", "<cmd>q<cr>", desc = "Quit", mode = { "n", "v" } },
        { "<leader>Q", "<cmd>qa<cr>", desc = "Quit All", mode = { "n", "v" } },
        { "<leader>w", "<cmd>w<cr>", desc = "Write", mode = { "n", "v" } },
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