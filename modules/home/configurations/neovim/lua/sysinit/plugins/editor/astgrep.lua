local M = {}

-- Quick access to interactive picker
local function open_astgrep_picker()
  local picker = require("sysinit.plugins.editor.astgrep-picker")
  picker.start_picker(function(results)
    if results then
      -- Create a new buffer with the results
      vim.cmd("new")
      local buf = vim.api.nvim_get_current_buf()
      local lines = vim.split(results, "\n")
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
      vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
      vim.api.nvim_buf_set_option(buf, "filetype", "astgrep-results")
      vim.api.nvim_buf_set_name(buf, "ast-grep Results")
    end
  end)
end

-- Repeat last ast-grep search
local function repeat_last_search()
  local picker = require("sysinit.plugins.editor.astgrep-picker")
  picker.repeat_last_search(function(results)
    if results then
      -- Create a new buffer with the results
      vim.cmd("new")
      local buf = vim.api.nvim_get_current_buf()
      local lines = vim.split(results, "\n")
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
      vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
      vim.api.nvim_buf_set_option(buf, "filetype", "astgrep-results")
      vim.api.nvim_buf_set_name(buf, "ast-grep Results")
    end
  end)
end

M.plugins = {
  {
    "0xstepit/ast-grep.nvim",
    cmd = { "AstGrep", "AstGrepSearch", "AstGrepReplace" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("ast-grep").setup({
        command = "ast-grep",

        file_patterns = {
          "*.ts",
          "*.tsx",
          "*.js",
          "*.jsx",
          "*.go",
          "*.py",
          "*.lua",
          "*.nix",
          "*.rs",
          "*.c",
          "*.cpp",
          "*.java",
        },

        search_opts = {
          case_sensitive = false,
          follow_symlinks = true,
          hidden = false,
        },

        telescope = {
          enabled = true,
          theme = "ivy",
        },
      })
    end,
    keys = {
      {
        "<leader>fS",
        open_astgrep_picker,
        desc = "ast-grep: Interactive search",
      },
      {
        "<leader>fR",
        function()
          require("ast-grep").replace()
        end,
        desc = "ast-grep: Replace pattern",
        mode = { "n", "v" },
      },
      {
        "<leader>f<C-s>",
        repeat_last_search,
        desc = "ast-grep: Repeat last search",
      },
    },
  },
}

return M
