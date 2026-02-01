return {
  {
    "rachartier/tiny-devicons-auto-colors.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "catppuccin/nvim",
    },
    event = "VeryLazy",
    config = function()
      local setup_opts = {}

      -- Only load theme_config.json if managed by Nix
      if vim.g.nix_managed then
        local json_loader = require("sysinit.utils.json_loader")
        local theme_config = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"))
        setup_opts.colors = theme_config.palette
      end

      require("tiny-devicons-auto-colors").setup(setup_opts)
    end,
  },
}
