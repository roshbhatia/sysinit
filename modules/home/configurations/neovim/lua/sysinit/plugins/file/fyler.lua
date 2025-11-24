local M = {}

M.plugins = {
  {
    "s1n7ax/nvim-window-picker",
    version = "2.*",
    event = "VeryLazy",
    config = function()
      require("window-picker").setup({
        hint = "floating-big-letter",
        picker_config = {
          handle_mouse_click = true,
        },
        filter_rules = {
          include_current_win = false,
          autoselect_one = true,
          bo = {
            filetype = { "fyler", "notify" },
            buftype = { "terminal", "quickfix" },
          },
        },
        show_prompt = false,
      })
    end,
  },
  {
    "antosha417/nvim-lsp-file-operations",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    event = "VeryLazy",
    config = function()
      require("lsp-file-operations").setup({
        operations = {
          willRenameFiles = true,
          didRenameFiles = true,
          willCreateFiles = true,
          didCreateFiles = true,
          willDeleteFiles = true,
          didDeleteFiles = true,
        },
      })

      vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = "*",
        callback = function(args)
          if vim.bo[args.buf].filetype == "fyler" then
            vim.notify("File operations completed in tree", vim.log.levels.INFO)
          end
        end,
        group = vim.api.nvim_create_augroup("FylerLSPFileOps", { clear = true }),
      })
    end,
  },
  {
    "A7Lavinraj/fyler.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "antosha417/nvim-lsp-file-operations",
      "s1n7ax/nvim-window-picker",
    },
    branch = "stable",
    event = "VeryLazy",
    opts = {
      integrations = {
        icon = "nvim_web_devicons",
      },
      views = {
        finder = {
          icon = {
            directory_collapsed = "",
            directory_empty = "󱧵",
            directory_expanded = "",
          },
          indentscope = {
            enabled = false,
          },
        },
      },
    },
    keys = function()
      local fyler = require("fyler")
      local window_picker = require("window-picker")

      -- Helper function to find the leftmost non-fyler window
      local function get_leftmost_window()
        local windows = vim.api.nvim_tabpage_list_wins(0)
        local leftmost_win = nil
        local leftmost_col = math.huge

        for _, win in ipairs(windows) do
          local buf = vim.api.nvim_win_get_buf(win)
          local ft = vim.api.nvim_buf_get_option(buf, "filetype")

          if ft ~= "fyler" then
            local pos = vim.api.nvim_win_get_position(win)
            if pos[2] < leftmost_col then
              leftmost_col = pos[2]
              leftmost_win = win
            end
          end
        end

        return leftmost_win
      end

      return {
        {
          "<leader>et",
          function()
            fyler.toggle({ kind = "split_left_most" })
          end,
          desc = "Toggle explore in filesystem buffer as tree",
        },
        {
          "<localleader>s",
          function()
            if vim.bo.filetype == "fyler" then
              local target_win = get_leftmost_window()
              if target_win then
                vim.api.nvim_set_current_win(target_win)
                vim.cmd("split")
                vim.cmd("wincmd p")
                local cr = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
                vim.api.nvim_feedkeys(cr, "n", false)
              end
            end
          end,
          desc = "Open file in horizontal split",
          ft = "fyler",
        },
        {
          "<localleader>v",
          function()
            if vim.bo.filetype == "fyler" then
              local target_win = get_leftmost_window()
              if target_win then
                vim.api.nvim_set_current_win(target_win)
                vim.cmd("vsplit")
                vim.cmd("wincmd p")
                local cr = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
                vim.api.nvim_feedkeys(cr, "n", false)
              end
            end
          end,
          desc = "Open file in vertical split",
          ft = "fyler",
        },
        {
          "<localleader>w",
          function()
            if vim.bo.filetype == "fyler" then
              local picked_window = window_picker.pick_window()
              if picked_window then
                vim.api.nvim_set_current_win(picked_window)
              end
            end
          end,
          desc = "Open file in existing pane",
          ft = "fyler",
        },
      }
    end,
  },
}

return M
