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
        window = {
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
        triggers = { "<leader>", "g", "z", "d", "y", "c", "[", "]" },
        triggers_nowait = { "'" },
        triggers_blacklist = {
          i = { "j", "k" },
          v = { "j", "k" },
        }
      })

      -- Register categories with beautiful nerd font icons
      wk.register({
        ["<leader>"] = {
          f = { name = "󰈞 Files/Find" },
          b = { name = "󰓩 Buffers" },
          w = { name = "󱂬 Windows" },
          g = { name = "󰊢 Git" },
          h = { name = "󰛡 Harpoon" },
          t = { name = "󰒮 Toggle" },
          c = { name = "󰅩 Code" },
          d = { name = "󱃸 Debug" },
          s = { name = "󰒺 Session" },
          r = { name = "󰑌 Refactor" },
          l = { name = "󰒕 LSP" },
          p = { name = "󰏖 Packages" },
          m = { name = "󰍉 Markdown" },
          u = { name = "󰦒 UI" },
          x = { name = "󰁨 Diagnostics" },
          z = { name = "󰉖 Notes" },
        },
      })
    end
  }
}
