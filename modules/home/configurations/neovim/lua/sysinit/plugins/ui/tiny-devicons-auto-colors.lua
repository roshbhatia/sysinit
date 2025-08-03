local M = {}

M.plugins = {
  {
    "rachartier/tiny-devicons-auto-colors.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "catppuccin/nvim",
    },
    event = "VeryLazy",
    config = function()
      local json_loader = require("sysinit.pkg.utils.json_loader")
      local theme_config =
        json_loader.load_json_file(json_loader.get_config_path("theme_config.json"))

      require("tiny-devicons-auto-colors").setup({
        colors = theme_config.palette,
      })
    end,
  },
}
return M
