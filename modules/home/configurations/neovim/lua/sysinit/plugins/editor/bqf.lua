local M = {}

M.plugins = {
  {
    "kevinhwang91/nvim-bqf",
    event = "VeryLazy",
    config = function()
      require("bqf").setup({
        func_map = {
          open = "<CR>", -- Open the item under the cursor
          openc = "o", -- Open the item and close the quickfix window
          drop = "O", -- Use 'drop' to open the item and close quickfix
          split = "<C-s>", -- Open the item in a horizontal split
          vsplit = "<C-v>", -- Open the item in a vertical split
          tabc = "<C-t>", -- Open the item in a new tab and close quickfix
          ptogglemode = "z,", -- Toggle preview window between normal and max size
          ptoggleitem = "p", -- Toggle preview for a quickfix list item
          ptoggleauto = "P", -- Toggle auto-preview when cursor moves
          prevfile = "<C-p>", -- Go to previous file in quickfix
          nextfile = "<C-n>", -- Go to next file in quickfix
          prevhist = "<", -- Cycle to previous quickfix list
          nexthist = ">", -- Cycle to next quickfix list
          lastleave = '"', -- Go to last selected item in quickfix
          stoggleup = "<S-Tab>", -- Toggle sign and move cursor up
          stoggledown = "<Tab>", -- Toggle sign and move cursor down
          stogglevm = "<Tab>", -- Toggle multiple signs in visual mode
          stogglebuf = "'<Tab>", -- Toggle signs for same buffers under cursor
          sclear = "z<Tab>", -- Clear the signs in current quickfix list
          pscrollup = "<C-b>", -- Scroll up half-page in preview window
          pscrolldown = "<C-f>", -- Scroll down half-page in preview window
          pscrollorig = "zo", -- Scroll back to original position in preview
        },
        preview = {
          winblend = 0,
        },
      })

      -- Buffer-local undo/redo stack for qf window
      local function qf_undo_redo_setup(bufnr)
        local undo_stack = {}
        local redo_stack = {}
        local function save_state()
          table.insert(undo_stack, vim.deepcopy(vim.fn.getqflist()))
          -- Clear redo stack on new action
          redo_stack = {}
        end
        -- Save initial state
        save_state()

        -- dd: delete item and save state
        vim.keymap.set("n", "dd", function()
          local qf_idx = vim.fn.line(".")
          local qflist = vim.fn.getqflist()
          if #qflist == 0 then
            return
          end
          save_state()
          table.remove(qflist, qf_idx)
          vim.fn.setqflist({}, "r", { items = qflist })
          local new_count = #qflist
          if new_count == 0 then
            vim.cmd("cclose")
          else
            vim.api.nvim_win_set_cursor(0, { math.min(qf_idx, new_count), 0 })
          end
        end, { buffer = bufnr, desc = "Quickfix remove item" })

        -- u: undo last qflist change
        vim.keymap.set("n", "u", function()
          if #undo_stack > 1 then
            local current = table.remove(undo_stack)
            table.insert(redo_stack, current)
            local prev = undo_stack[#undo_stack]
            vim.fn.setqflist({}, "r", { items = prev })
          end
        end, { buffer = bufnr, desc = "Quickfix undo change" })

        -- U: redo last undone qflist change
        vim.keymap.set("n", "U", function()
          if #redo_stack > 0 then
            local state = table.remove(redo_stack)
            table.insert(undo_stack, state)
            vim.fn.setqflist({}, "r", { items = state })
          end
        end, { buffer = bufnr, desc = "Quickfix redo change" })
      end

      -- Setup autocmd for qf filetype
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "qf",
        callback = function(args)
          qf_undo_redo_setup(args.buf)
        end,
      })
    end,
  },
}

return M
