local M = {}

M.plugins = {
  {
    "nvim-mini/mini.diff",
    config = function()
      require("mini.diff").setup({
        -- Options for diff highlighting
        options = {
          -- Whether to use algorithm from Neovim's built-in diff
          use_override = true,
          -- Whether to use default mappings
          use_default_mappings = true,
        },
        -- Module mappings. Use `''` (empty string) to disable one.
        mappings = {
          -- Apply hunks in three-way diff
          apply = "gh",
          -- Reset hunks in three-way diff
          reset = "gH",
          -- Go to next hunk
          next = "]h",
          -- Go to previous hunk
          prev = "[h",
          -- Textobject for current hunk
          textobject = "ih",
        },
        -- Highlight groups automatically set
        highlight = {
          -- Diff text from the left side
          diff = "DiffText",
          -- Diff text from the right side
          diff_add = "DiffAdd",
          -- Diff text from the right side
          diff_change = "DiffChange",
          -- Diff text from the right side
          diff_delete = "DiffDelete",
        },
        -- Source specific options
        source = {
          -- Options for git diff
          git = {
            -- Whether to use git diff
            enabled = true,
            -- Arguments for git diff
            args = { "--no-color", "--no-ext-diff" },
          },
          -- Options for diff command
          diff = {
            -- Whether to use diff command
            enabled = true,
            -- Arguments for diff command
            args = { "-u" },
          },
        },
        -- View specific options
        view = {
          -- Whether to show diff in current buffer
          style = "sign",
          -- Whether to show diff in floating window
          floating = false,
          -- Whether to show diff in split window
          split = false,
        },
      })
    end,
    keys = function()
      return {
        {
          "<leader>gd",
          function()
            -- Toggle diff view for current file
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
            -- Toggle diff view for all files
            vim.cmd("MiniDiffToggle")
          end,
          desc = "Toggle diff for all files",
          mode = "n",
        },
        {
          "<leader>gh",
          function()
            -- Show file history using git log
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
            -- Show project history
            vim.cmd("Git log --oneline")
          end,
          desc = "Show project history",
          mode = "n",
        },
        {
          "<leader>ga",
          function()
            -- Apply current hunk
            vim.cmd("MiniDiffApply")
          end,
          desc = "Apply current hunk",
          mode = "n",
        },
        {
          "<leader>gr",
          function()
            -- Reset current hunk
            vim.cmd("MiniDiffReset")
          end,
          desc = "Reset current hunk",
          mode = "n",
        },
        {
          "]h",
          function()
            -- Go to next hunk
            vim.cmd("MiniDiffNextHunk")
          end,
          desc = "Go to next hunk",
          mode = "n",
        },
        {
          "[h",
          function()
            -- Go to previous hunk
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
