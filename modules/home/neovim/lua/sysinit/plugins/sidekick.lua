return {
  {
    "folke/sidekick.nvim",
    config = function()
      require("sidekick").setup({})

      -- Ghost text namespace and state
      local ns_id = vim.api.nvim_create_namespace("sidekick_ghost")
      local ghost_extmark_id = nil
      local ghost_buf = nil

      -- Setup highlight groups for ghost text (linked to existing groups)
      vim.api.nvim_set_hl(0, "SidekickGhostText", { link = "Comment" })
      vim.api.nvim_set_hl(0, "SidekickGhostHint", { link = "NonText" })

      -- Clear existing ghost text extmark
      local function clear_ghost_text()
        if ghost_extmark_id and ghost_buf then
          if vim.api.nvim_buf_is_valid(ghost_buf) then
            pcall(vim.api.nvim_buf_del_extmark, ghost_buf, ns_id, ghost_extmark_id)
          end
          ghost_extmark_id = nil
          ghost_buf = nil
        end
      end

      -- Render ghost text preview for NES suggestion
      local function render_ghost_text()
        clear_ghost_text()

        local ok, nes = pcall(require, "sidekick.nes")
        if not ok or not nes then
          return
        end

        if not nes.have() then
          return
        end

        local edits = nes.get()
        if not edits or #edits == 0 then
          return
        end

        local edit = edits[1]
        if not edit then
          return
        end

        -- Get diff information
        local diff_ok, diff = pcall(function()
          return edit:diff()
        end)
        if not diff_ok or not diff then
          return
        end

        -- Extract preview text from the new content
        local preview = ""
        if diff.to and diff.to.lines and #diff.to.lines > 0 then
          preview = diff.to.lines[1] or ""
        elseif edit.text then
          -- Fallback to edit text if diff.to is not available
          local first_line = edit.text:match("^([^\n]*)")
          preview = first_line or ""
        end

        -- Truncate preview to reasonable length
        local max_len = 50
        if #preview > max_len then
          preview = preview:sub(1, max_len) .. "..."
        end

        -- Skip if no meaningful preview
        if preview == "" or preview:match("^%s*$") then
          return
        end

        -- Get edit position
        local buf = edit.buf
        local row = edit.from and edit.from[1] or 0
        local col = edit.from and edit.from[2] or 0

        -- Ensure buffer is valid
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end

        -- Ensure row is within buffer bounds
        local line_count = vim.api.nvim_buf_line_count(buf)
        if row >= line_count then
          row = line_count - 1
        end
        if row < 0 then
          row = 0
        end

        -- Get line content to validate column
        local line_content = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
        if col > #line_content then
          col = #line_content
        end

        -- Render ghost text at edit position
        local extmark_ok, extmark_id = pcall(vim.api.nvim_buf_set_extmark, buf, ns_id, row, col, {
          virt_text = {
            { preview, "SidekickGhostText" },
            { " [TAB]", "SidekickGhostHint" },
          },
          virt_text_pos = "overlay",
          hl_mode = "combine",
          priority = 100,
        })

        if extmark_ok and extmark_id then
          ghost_extmark_id = extmark_id
          ghost_buf = buf
        end
      end

      -- Setup autocmds for ghost text management
      local augroup = vim.api.nvim_create_augroup("SidekickGhostText", { clear = true })

      -- Show ghost text when NES suggestion arrives
      vim.api.nvim_create_autocmd("User", {
        group = augroup,
        pattern = "SidekickNesDone",
        callback = function()
          vim.schedule(render_ghost_text)
        end,
      })

      -- Clear ghost text on text changes and mode changes
      vim.api.nvim_create_autocmd({ "TextChangedI", "InsertEnter", "BufLeave" }, {
        group = augroup,
        callback = clear_ghost_text,
      })

      -- Also clear when sidekick clears its edits
      vim.api.nvim_create_autocmd("User", {
        group = augroup,
        pattern = "SidekickNesClear",
        callback = clear_ghost_text,
      })

      -- Re-render on cursor move in normal mode (suggestion may have changed)
      vim.api.nvim_create_autocmd("CursorMoved", {
        group = augroup,
        callback = function()
          -- Debounce by scheduling
          vim.schedule(function()
            local ok, nes = pcall(require, "sidekick.nes")
            if ok and nes and nes.have() then
              render_ghost_text()
            else
              clear_ghost_text()
            end
          end)
        end,
      })
    end,
    keys = {
      {
        "<tab>",
        function()
          if not require("sidekick").nes_jump_or_apply() then
            return "<Tab>"
          end
        end,
        expr = true,
        desc = "Goto/Apply Next Edit Suggestion",
      },
    },
  },
}
