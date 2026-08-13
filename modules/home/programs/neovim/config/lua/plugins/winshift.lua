return {
  {
    -- smart-splits moves the cursor between windows and resizes them; this moves the
    -- windows themselves, which is the half neither it nor bufresize covers.
    "sindrets/winshift.nvim",
    cmd = "WinShift",
    config = function()
      local ft = require("utils.filetypes")
      require("winshift").setup({
        window_picker = function()
          return require("winshift.lib").pick_window({
            picker_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
            filter_rules = {
              cur_win = true,
              floats = true,
              -- A sidebar is placed, not arranged: swapping the file tree into the middle
              -- of a diff is never the move being asked for.
              filetype = vim.list_extend(
                vim.deepcopy(ft.sidebar_filetypes),
                { "DiffviewFiles", "DiffviewFileHistory" }
              ),
              buftype = ft.utility_buftypes,
              bufname = {},
            },
          })
        end,
      })
    end,
    keys = {
      { "<C-w>m", "<Cmd>WinShift<CR>", desc = "Move this window" },
      { "<C-w>X", "<Cmd>WinShift swap<CR>", desc = "Swap this window with another" },
    },
  },
}
