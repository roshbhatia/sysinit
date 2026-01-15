local M = {}

M.plugins = {
  {
    "vhyrro/luarocks.nvim",
    priority = 9998,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      rocks_path = vim.fn.stdpath("data") .. "/luarocks",
      lua_path = vim.fn.stdpath("data")
        .. "/luarocks/share/lua/5.1/?.lua;"
        .. vim.fn.stdpath("data")
        .. "/luarocks/share/lua/5.1/?/init.lua",
      lua_cpath = vim.fn.stdpath("data") .. "/luarocks/lib/lua/5.1/?.so",
      create_dirs = true,
      install = {
        only_deps = false,
        flags = {
          "--local",
          "--force-config",
        },
      },
      show_progress = true,
      rocks = {
        "prec2",
        "tiktoken_core",
        "wezterm-types",
      },
    },
  },
}

return M
