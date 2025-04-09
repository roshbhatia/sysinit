return {
  {
    "nvimtools/none-ls.nvim", -- Updated plugin name
    dependencies = { "nvim-lua/plenary.nvim" },
  },
  {
    "jay-babu/mason-null-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "nvimtools/none-ls.nvim",
    },
    config = function()
      local null_ls = require("null-ls")
      require("mason-null-ls").setup({
        ensure_installed = { "stylua", "prettier" }, -- Automatically install these tools
        automatic_installation = true, -- Automatically install tools based on sources in null-ls
        handlers = {
          -- Custom handler for stylua
          stylua = function(source_name, methods)
            null_ls.register(null_ls.builtins.formatting.stylua)
          end,
          -- Default handler for other sources
          function(source_name, methods)
            require("mason-null-ls").default_setup(source_name, methods)
          end,
        },
      })

      -- Set up null-ls
      null_ls.setup({
        sources = {
          null_ls.builtins.formatting.stylua,
          null_ls.builtins.formatting.prettier,
        },
      })
    end,
  },
}
