local M = {}

function M.setup()
  require("lazy").setup({
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
    change_detection = {
      notify = false,
    },
  })
end

return M
