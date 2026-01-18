return {
  {
    "nvimtools/none-ls.nvim",
    event = "LSPAttach",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      local null_ls = require("null-ls")
      local code_actions = require("sysinit.utils.code_actions")

      null_ls.setup({
        border = "rounded",
        debounce = 150,
        default_timeout = 5000,
        temp_dir = vim.fn.stdpath("cache") .. "/null-ls",
        sources = {
          null_ls.builtins.code_actions.gitrebase,
          null_ls.builtins.code_actions.impl,
          null_ls.builtins.code_actions.refactoring,
          null_ls.builtins.code_actions.statix,
          null_ls.builtins.code_actions.textlint,
          null_ls.builtins.diagnostics.actionlint,
          null_ls.builtins.diagnostics.checkmake,
          null_ls.builtins.diagnostics.deadnix,
          null_ls.builtins.diagnostics.golangci_lint,
          null_ls.builtins.diagnostics.kube_linter,
          null_ls.builtins.diagnostics.staticcheck,
          null_ls.builtins.diagnostics.terraform_validate,
          null_ls.builtins.diagnostics.tfsec,
          null_ls.builtins.diagnostics.zsh,
          null_ls.builtins.hover.dictionary,
          null_ls.builtins.hover.printenv,
        },
      })

      null_ls.register({
        name = "open_link_in_browser",
        method = null_ls.methods.CODE_ACTION,
        filetypes = {},
        generator = code_actions.open_link.generator(),
      })

      null_ls.register({
        name = "hex_color_tools",
        method = null_ls.methods.CODE_ACTION,
        filetypes = {},
        generator = code_actions.hex_color.generator(),
      })
    end,
  },
}
