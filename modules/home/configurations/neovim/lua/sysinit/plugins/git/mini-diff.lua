local M = {}

M.plugins = {
  {
    "echasnovski/mini.diff",
    event = "VeryLazy",
    config = function()
      require("mini.diff").setup({
        -- Options for how hunks are visualized
        view = {
          -- Visualization style: 'sign' or 'number'
          style = vim.go.number and "number" or "sign",
          -- Signs for hunks (used when style = 'sign')
          signs = {
            add = "▎",
            change = "▎",
            delete = "▎",
          },
          -- Priority of used visualization extmarks
          priority = 199,
        },

        -- Source to use for reference text
        source = nil, -- Uses default Git source (MiniDiff.gen_source.git())

        -- Debounce delay (in ms) for realtime diff updates
        delay = {
          text_change = 200,
        },

        -- Module mappings
        mappings = {
          -- Apply hunks inside a visual/operator region
          apply = "gh",
          -- Reset hunks inside a visual/operator region
          reset = "gH",
          -- Hunk range textobject to be used inside operator
          textobject = "gh",
          -- Go to hunk range in the forward/backward direction
          goto_first = "[H",
          goto_prev = "[h",
          goto_next = "]h",
          goto_last = "]H",
        },

        -- Various options
        options = {
          -- Diff algorithm (see :h vim.diff())
          algorithm = "histogram",
          -- Whether to use "indent heuristic"
          indent_heuristic = true,
          -- Amount of second-stage diff to align lines (0 to disable)
          linematch = 60,
          -- Whether to wrap around edges during hunk navigation
          wrap_goto = false,
        },
      })

      -- Function to populate quickfix list with files that have changes
      local function populate_quickfix_with_changes()
        local qf_list = {}

        -- Get all listed buffers
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, "buflisted") then
            local buf_data = require("mini.diff").get_buf_data(buf)

            -- Check if buffer has diff data and hunks
            if buf_data and buf_data.hunks and #buf_data.hunks > 0 then
              local filepath = vim.api.nvim_buf_get_name(buf)

              if filepath ~= "" then
                local summary = buf_data.summary or { add = 0, change = 0, delete = 0 }
                local total_changes = summary.add + summary.change + summary.delete

                -- Add entry for each hunk
                for _, hunk in ipairs(buf_data.hunks) do
                  local hunk_type = hunk.type or "change"
                  local line_start = hunk.buf_start or 1

                  table.insert(qf_list, {
                    bufnr = buf,
                    filename = filepath,
                    lnum = line_start,
                    col = 1,
                    text = string.format("[%s] %d lines", hunk_type:upper(), hunk.buf_count or 0),
                    type = hunk_type == "delete" and "W" or "I",
                  })
                end
              end
            end
          end
        end

        -- Set quickfix list if there are changes
        if #qf_list > 0 then
          vim.fn.setqflist(qf_list, "r")
          vim.fn.setqflist({}, "a", { title = "Git Changes (" .. #qf_list .. " hunks)" })
        else
          vim.fn.setqflist({}, "r")
          vim.fn.setqflist({}, "a", { title = "Git Changes (no changes)" })
        end
      end

      -- Auto-refresh quickfix list when diff is updated
      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniDiffUpdated",
        callback = function()
          -- Only update if quickfix window is open
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.api.nvim_buf_get_option(buf, "buftype") == "quickfix" then
              populate_quickfix_with_changes()
              break
            end
          end
        end,
        desc = "Update quickfix list with git changes",
      })

      -- Store the function globally so it can be called from keymaps
      _G._minidiff_populate_qf = populate_quickfix_with_changes
    end,
    keys = function()
      return {
        {
          "<leader>go",
          function()
            require("mini.diff").toggle_overlay()
          end,
          desc = "Toggle diff overlay",
          mode = "n",
        },
        {
          "<leader>gd",
          function()
            require("mini.diff").toggle()
          end,
          desc = "Toggle diff for current buffer",
          mode = "n",
        },
        {
          "<leader>gq",
          function()
            if _G._minidiff_populate_qf then
              _G._minidiff_populate_qf()
              vim.cmd("copen")
            else
              vim.notify("Mini.diff quickfix not initialized", vim.log.levels.WARN)
            end
          end,
          desc = "Show git changes in quickfix",
          mode = "n",
        },
        -- Apply/reset hunks in visual mode
        {
          "<leader>ga",
          function()
            vim.cmd("normal! gh")
          end,
          desc = "Apply hunk",
          mode = { "n", "x" },
        },
        {
          "<leader>gr",
          function()
            vim.cmd("normal! gH")
          end,
          desc = "Reset hunk",
          mode = { "n", "x" },
        },
      }
    end,
  },
}

return M
