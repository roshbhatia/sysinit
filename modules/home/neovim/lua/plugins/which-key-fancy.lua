-- Enhanced which-key configuration with fancy nerd font icons
return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local wk = require("which-key")
      wk.setup({
        plugins = {
          marks = true,
          registers = true,
          spelling = true,
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
        -- Modern options for which-key
        icons = {
          breadcrumb = "»",
          separator = "➜",
          group = "󰉋 ",
        },
        popup_mappings = {
          scroll_down = "<c-d>",
          scroll_up = "<c-u>",
        },
        win = { -- updated from window to win
          border = "rounded",
          position = "bottom",
          margin = { 1, 0, 1, 0 },
          padding = { 1, 2, 1, 2 },
          winblend = 0,
        },
        layout = {
          height = { min = 4, max = 25 },
          width = { min = 20, max = 50 },
          spacing = 3,
          align = "center",
        },
        -- Using new format for triggers
        triggers = { "<leader>", "g", "z", "d", "y", "c", "[", "]" },
        triggers_nowait = { "'" },
        -- Using new format for triggers_blacklist
        triggers_ignore = {
          i = { "j", "k" },
          v = { "j", "k" },
        },
        -- Using new filter option instead of ignore_missing
        filter = function(client, result)
          return not (result.desc and result.desc:match("DEBUG"))
        end
      })

      -- Register categories with beautiful nerd font icons using new format
      wk.register({
        { "<leader>f", group = "󰈞 Files/Find" },
        { "<leader>b", group = "󰓩 Buffers" },
        { "<leader>w", group = "󱂬 Windows" },
        { "<leader>g", group = "󰊢 Git" },
        { "<leader>h", group = "󰛡 Harpoon" },
        { "<leader>t", group = "󰒮 Toggle" },
        { "<leader>c", group = "󰅩 Code" },
        { "<leader>d", group = "󱃸 Debug" },
        { "<leader>s", group = "󰒺 Session" },
        { "<leader>r", group = "󰑌 Refactor" },
        { "<leader>l", group = "󰒕 LSP" },
        { "<leader>p", group = "󰏖 Packages" },
        { "<leader>m", group = "󰍉 Markdown" },
        { "<leader>u", group = "󰦒 UI" },
        { "<leader>x", group = "󰁨 Diagnostics" },
        { "<leader>o", group = "󰁕 Options" },
      })
    end
  }
}
