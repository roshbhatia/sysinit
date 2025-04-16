-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/mfussenegger/nvim-lint/master/doc/lint.txt"
local M = {}

M.plugins = {
  {
    "mfussenegger/nvim-lint",
    lazy = false,
    dependencies = {
      "mason.nvim",
    },
    config = function()
      local lint = require("lint")
      
      -- Configure linters for different filetypes
      lint.linters_by_ft = {
        python = {"pylint", "ruff"},
        javascript = {"eslint"},
        typescript = {"eslint"},
        javascriptreact = {"eslint"},
        typescriptreact = {"eslint"},
        go = {"golangcilint"},
        sh = {"shellcheck"},
        bash = {"shellcheck"},
        zsh = {"shellcheck"},
        yaml = {"yamllint"},
        json = {"jsonlint"},
        markdown = {"markdownlint"},
        lua = {"luacheck"},
        terraform = {"tflint"},
      }
      
      -- Configure specific linters
      lint.linters.pylint.args = {
        "--output-format=text",
        "--score=no",
        "--msg-template='{line}:{column}:{category}:{msg} ({symbol})'",
      }
      
      lint.linters.shellcheck.args = {
        "--format=gcc",
        "--external-sources",
        "--shell=bash",
      }
      
      -- Set up autocommands for running linters
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter" }, {
        callback = function()
          require("lint").try_lint()
        end,
      })
      
      -- Create a command to manually trigger linting
      vim.api.nvim_create_user_command("Lint", function()
        require("lint").try_lint()
      end, {})
      
      -- Create a function to toggle automatic linting
      local auto_linting_enabled = true
      
      local function toggle_auto_lint()
        auto_linting_enabled = not auto_linting_enabled
        
        if auto_linting_enabled then
          vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter" }, {
            callback = function()
              require("lint").try_lint()
            end,
            group = vim.api.nvim_create_augroup("nvim_lint_augroup", { clear = true }),
          })
          vim.notify("Automatic linting enabled", vim.log.levels.INFO)
        else
          vim.api.nvim_clear_autocmds({ group = "nvim_lint_augroup" })
          vim.notify("Automatic linting disabled", vim.log.levels.INFO)
        end
      end
      
      -- Create a command to toggle automatic linting
      vim.api.nvim_create_user_command("ToggleAutoLint", toggle_auto_lint, {})
      
      -- Register with which-key
      local wk = require("which-key")
      wk.add({
        { "<leader>cl", function() require("lint").try_lint() end, desc = "Lint Current File", mode = "n" },
        { "<leader>cL", toggle_auto_lint, desc = "Toggle Auto Linting", mode = "n" },
      })
    end
  }
}

return M