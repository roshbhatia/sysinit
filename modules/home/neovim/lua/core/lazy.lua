local M = {}

function M.setup()
  -- Lazy.nvim configuration
  require("lazy").setup({
    -- Performance and UI settings
    performance = {
      rtp = {
        disabled_plugins = {
          "gzip",
          "matchit",
          "matchparen",
          "netrwPlugin",
          "tarPlugin",
          "tohtml",
          "tutor",
          "zipPlugin",
        },
      },
    },
    ui = {
      border = "rounded",
      icons = {
        cmd = " ",
        config = " ",
        event = " ",
        ft = " ",
        init = " ",
        keys = " ",
        plugin = " ",
        runtime = " ",
        source = " ",
        start = " ",
        task = " ",
        lazy = "󰒲 ",
      },
    },
    change_detection = {
      notify = false,
    },
  })
end

return M
