local M = {}

M.plugins = {
  {
    "nvim-mini/mini.diff",
    config = function()
      require("mini.diff").setup({
        options = {
          use_override = true,
          use_default_mappings = true,
        },
        mappings = {
          apply = "gh",
          reset = "gH",
          next = "]h",
          prev = "[h",
          textobject = "ih",
        },
        highlight = {
          diff = "DiffText",
          diff_add = "DiffAdd",
          diff_change = "DiffChange",
          diff_delete = "DiffDelete",
        },
        source = {
          git = {
            enabled = true,
            args = { "--no-color", "--no-ext-diff" },
          },
          diff = {
            enabled = true,
            args = { "-u" },
          },
        },
        view = {
          style = "sign",
          floating = false,
          split = false,
        },
      })
    end,
    keys = function()
      return {
        {
          "<leader>gd",
          function()
            local current_file = vim.fn.expand("%")
            if current_file ~= "" then
              vim.cmd("MiniDiffToggle " .. vim.fn.fnameescape(current_file))
            else
              vim.notify("No file to diff", vim.log.levels.WARN)
            end
          end,
          desc = "Toggle diff for current file",
          mode = "n",
        },
        {
          "<leader>gD",
          function()
            vim.cmd("MiniDiffToggle")
          end,
          desc = "Toggle diff for all files",
          mode = "n",
        },
        {
          "<leader>gh",
          function()
            local current_file = vim.fn.expand("%")
            if current_file ~= "" then
              vim.cmd("Git log --oneline --follow -- " .. vim.fn.fnameescape(current_file))
            else
              vim.notify("No file to show history for", vim.log.levels.WARN)
            end
          end,
          desc = "Show current file history",
          mode = "n",
        },
        {
          "<leader>gH",
          function()
            vim.cmd("Git log --oneline")
          end,
          desc = "Show project history",
          mode = "n",
        },
        {
          "<leader>ga",
          function()
            vim.cmd("MiniDiffApply")
          end,
          desc = "Apply current hunk",
          mode = "n",
        },
        {
          "<leader>gr",
          function()
            vim.cmd("MiniDiffReset")
          end,
          desc = "Reset current hunk",
          mode = "n",
        },
        {
          "]h",
          function()
            vim.cmd("MiniDiffNextHunk")
          end,
          desc = "Go to next hunk",
          mode = "n",
        },
        {
          "[h",
          function()
            vim.cmd("MiniDiffPrevHunk")
          end,
          desc = "Go to previous hunk",
          mode = "n",
        },
      }
    end,
  },
}

return M
