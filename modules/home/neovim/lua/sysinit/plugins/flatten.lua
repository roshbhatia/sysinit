return {
  "willothy/flatten.nvim",
  -- Must be loaded as early as possible to minimize delay
  lazy = false,
  priority = 1001,
  opts = function()
    return {
      -- File opening behavior
      window = {
        -- Open files in alternate window (last used window)
        -- This works well with toggleable terminals
        open = "alternate",

        -- Open diff mode in vertical split in new tab
        diff = "tab_vsplit",

        -- Focus first file when multiple files are opened
        focus = "first",
      },

      -- Block (wait for editor to close) for these filetypes
      block_for = {
        gitcommit = true,
        gitrebase = true,
        gitconfig = false,
      },

      -- Allow command passthrough from guest to host
      disable_cmd_passthrough = false,

      -- Nest if no arguments are passed
      nest_if_no_args = false,

      -- Nest even if commands are passed
      nest_if_cmds = false,

      -- Terminal integrations
      integrations = {
        -- Enable Wezterm integration (flatten across tabs/panes by cwd)
        wezterm = true,

        -- Enable Kitty integration (flatten across tabs)
        kitty = false,
      },

      -- Hooks for custom behavior
      hooks = {
        -- Determine if guest should wait for host to close file
        should_block = function(argv)
          -- Block if -b flag is present
          -- Usage: nvim -b file1 file2
          if vim.tbl_contains(argv, "-b") then
            return true
          end

          -- Block if in diff mode
          if vim.tbl_contains(argv, "-d") then
            return true
          end

          -- Default blocking based on filetype
          return false
        end,

        -- Called before opening files
        pre_open = function()
          -- Could be used to save terminal state, hide terminal, etc.
        end,

        -- Called after opening files
        post_open = function(bufnr, winnr, ft)
          -- Switch to the window with the file
          vim.api.nvim_set_current_win(winnr)

          -- If in a Wezterm pane, switch focus to the current pane
          -- This ensures you see the file that was opened
          if vim.env.WEZTERM_PANE then
            local ok, wezterm = pcall(require, "wezterm")
            if ok then
              wezterm.switch_pane.id(tonumber(vim.env.WEZTERM_PANE))
            end
          end

          -- Auto-close git commit buffer on write
          if ft == "gitcommit" or ft == "gitrebase" then
            vim.api.nvim_create_autocmd("BufWritePost", {
              buffer = bufnr,
              once = true,
              callback = vim.schedule_wrap(function()
                vim.api.nvim_buf_delete(bufnr, {})
              end),
              desc = "Flatten: Auto-close git commit buffer on write",
            })
          end
        end,

        -- Called when blocking ends (file is closed)
        block_end = function()
          -- Could be used to reopen terminal, restore state, etc.
        end,
      },
    }
  end,
}
