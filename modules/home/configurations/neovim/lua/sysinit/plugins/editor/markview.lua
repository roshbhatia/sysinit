local M = {}

M.plugins = {
  {
    "OXY2DEV/markview.nvim",
    lazy = false,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      local presets = require("markview.presets")

      require("markview").setup({
        preview = {
          modes = {},
          hybrid_modes = {},
          icon_provider = "devicons",
          filetypes = {
            "markdown",
          },
        },

        markdown = {
          headings = presets.headings.simple,
          code_blocks = {
            style = "simple",
            position = "left",
            pad_amount = 1,
            language_names = {},
            language_direction = "left",
            min_width = 60,
          },
          tables = presets.tables.rounded,
          horizontal_rules = presets.horizontal_rules.thin,
        },

        sign = {
          enabled = false,
        },
      })

      local preview_bufnr = nil
      local preview_winnr = nil
      local source_bufnr = nil
      local update_timer = nil

      local function update_preview()
        if not preview_bufnr or not vim.api.nvim_buf_is_valid(preview_bufnr) then
          return
        end
        if not source_bufnr or not vim.api.nvim_buf_is_valid(source_bufnr) then
          return
        end

        local lines = vim.api.nvim_buf_get_lines(source_bufnr, 0, -1, false)
        vim.api.nvim_buf_set_lines(preview_bufnr, 0, -1, false, lines)
      end

      local function close_preview()
        if update_timer then
          update_timer:stop()
          update_timer:close()
          update_timer = nil
        end

        if preview_winnr and vim.api.nvim_win_is_valid(preview_winnr) then
          vim.api.nvim_win_close(preview_winnr, true)
        end

        preview_bufnr = nil
        preview_winnr = nil
        source_bufnr = nil
      end

      local function toggle_split_preview()
        if preview_winnr and vim.api.nvim_win_is_valid(preview_winnr) then
          close_preview()
          return
        end

        source_bufnr = vim.api.nvim_get_current_buf()

        local filetype = vim.api.nvim_buf_get_option(source_bufnr, "filetype")
        if filetype ~= "markdown" then
          vim.notify("Markview preview is only available for markdown files", vim.log.levels.WARN)
          return
        end

        vim.cmd("vsplit")
        preview_winnr = vim.api.nvim_get_current_win()

        preview_bufnr = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_win_set_buf(preview_winnr, preview_bufnr)

        vim.api.nvim_buf_set_option(preview_bufnr, "filetype", "markdown")
        vim.api.nvim_buf_set_option(preview_bufnr, "buftype", "nofile")
        vim.api.nvim_buf_set_option(preview_bufnr, "bufhidden", "wipe")
        vim.api.nvim_buf_set_name(preview_bufnr, "Markview Preview")

        vim.api.nvim_win_set_option(preview_winnr, "conceallevel", 2)
        vim.api.nvim_win_set_option(preview_winnr, "concealcursor", "nc")
        vim.api.nvim_win_set_option(preview_winnr, "wrap", true)
        vim.api.nvim_win_set_option(preview_winnr, "linebreak", true)

        vim.api.nvim_buf_call(preview_bufnr, function()
          require("markview").attach_buf(preview_bufnr)
        end)

        update_preview()

        local augroup = vim.api.nvim_create_augroup("MarkviewSplitPreview", { clear = true })

        vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
          group = augroup,
          buffer = source_bufnr,
          callback = function()
            if update_timer then
              update_timer:stop()
            end
            update_timer = vim.defer_fn(update_preview, 100)
          end,
        })

        vim.api.nvim_create_autocmd({ "BufWinLeave", "BufUnload" }, {
          group = augroup,
          buffer = source_bufnr,
          callback = close_preview,
        })

        vim.api.nvim_create_autocmd({ "WinClosed" }, {
          group = augroup,
          callback = function(args)
            if tonumber(args.match) == preview_winnr then
              close_preview()
            end
          end,
        })

        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
          group = augroup,
          buffer = source_bufnr,
          callback = function()
            if preview_winnr and vim.api.nvim_win_is_valid(preview_winnr) then
              local cursor = vim.api.nvim_win_get_cursor(0)
              pcall(vim.api.nvim_win_set_cursor, preview_winnr, cursor)
            end
          end,
        })

        vim.cmd("wincmd p")
      end

      vim.api.nvim_create_user_command("MarkviewSplitPreview", toggle_split_preview, {})
    end,
    keys = function()
      return {
        {
          "<localleader>mm",
          "<cmd>MarkviewSplitPreview<cr>",
          desc = "Toggle Markdown Preview",
        },
      }
    end,
  },
}

return M
