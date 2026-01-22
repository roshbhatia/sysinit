return {
  {
    "tamton-aquib/staline.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    lazy = false,
    config = function()
      local function get_fg(hl_name)
        local hl = vim.api.nvim_get_hl(0, { name = hl_name, link = false })
        if hl and hl.fg then
          return string.format("#%06x", hl.fg)
        end
      end

      -- Track code action availability for the current line
      local code_action_available = false
      local code_action_timer = nil

      local function check_code_actions()
        local bufnr = vim.api.nvim_get_current_buf()
        local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/codeAction" })
        if #clients == 0 then
          code_action_available = false
          return
        end

        local params = vim.lsp.util.make_range_params()
        params.context = {
          diagnostics = vim.lsp.diagnostic.get_line_diagnostics(bufnr),
          only = nil,
          triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Automatic,
        }

        vim.lsp.buf_request_all(bufnr, "textDocument/codeAction", params, function(results)
          code_action_available = false
          for _, result in pairs(results or {}) do
            if result.result and #result.result > 0 then
              code_action_available = true
              break
            end
          end
          vim.cmd.redrawstatus()
        end)
      end

      local function debounced_check_code_actions()
        if code_action_timer then
          vim.fn.timer_stop(code_action_timer)
        end
        code_action_timer = vim.fn.timer_start(150, function()
          vim.schedule(check_code_actions)
        end)
      end

      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufEnter", "InsertLeave" }, {
        callback = debounced_check_code_actions,
      })

      local function code_action_indicator()
        if code_action_available then
          return "󱣀 "
        end
        return ""
      end

      require("staline").setup({
        sections = {
          left = {
            "mode",
            "branch",
            "file_name",
          },
          mid = {
            code_action_indicator,
          },
          right = {
            "lsp",
            "lsp_name",
            "file_size",
            "line_column",
          },
        },
        defaults = {
          expand_null_ls = false,
          true_colors = true,
          line_column = ":%c [%l/%L]",
          lsp_client_symbol = "󰘧 ",
          lsp_client_character_length = 40,
          file_size_suffix = true,
          branch_symbol = " ",
        },
        special_table = {
          qf = { "QuickFix", " " },
          ["neo-tree"] = { "File Tree", " " },
          Outline = { "Outline", " " },
        },
        lsp_symbols = {
          Error = " ",
          Info = " ",
          Warn = " ",
          Hint = " ",
        },
        mode_colors = {
          n = get_fg("Normal"),
          i = get_fg("String"),
          c = get_fg("Special"),
          v = get_fg("Statement"),
          V = get_fg("Statement"),
          [""] = get_fg("Statement"),
          R = get_fg("Constant"),
          r = get_fg("Constant"),
          s = get_fg("Type"),
          S = get_fg("Type"),
          t = get_fg("Directory"),
          ic = get_fg("String"),
          Rc = get_fg("Constant"),
          cv = get_fg("Special"),
        },
        mode_icons = {
          n = "NORMAL",
          i = "INSERT",
          c = "COMMAND",
          v = "VISUAL",
          V = "V-LINE",
          [""] = "V-BLOCK",
          R = "REPLACE",
          r = "REPLACE",
          s = "SELECT",
          S = "S-LINE",
          t = "TERMINAL",
          ic = "INSERT",
          Rc = "REPLACE",
          cv = "VIM EX",
        },
      })
    end,
  },
}
