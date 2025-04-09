-- Indentation plugins
return {
  -- Remove mini.indentscope (causing errors)
  {
    "echasnovski/mini.indentscope",
    enabled = false,
  },

  -- Alternative indentation guide plugin
  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      -- Use newer indent-blankline.nvim v3 configuration
      indent = {
        char = "│",
        tab_char = "│",
      },
      scope = { enabled = false },
      exclude = {
        filetypes = {
          "help",
          "alpha",
          "dashboard",
          "neo-tree",
          "Trouble",
          "lazy",
          "mason",
          "notify",
          "toggleterm",
          "lazyterm",
          "startify",
        },
      },
    },
    main = "ibl",
  },
}
