return {
  {
    "tamton-aquib/staline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false,
    config = function()
      local hl_utils = require("utils.highlight")
      local get_fg = hl_utils.get_fg

      local function get_format_status()
        if vim.g.disable_autoformat or vim.b.disable_autoformat then
          return "󰉥 "
        end
        return ""
      end

      -- A file with notes says so whether or not they are drawn, because a hidden note is
      -- the one case where the buffer itself shows nothing and the owner would not know.
      local function get_notes_status()
        local ok, notes = pcall(require, "harness.notes")
        if not ok then
          return ""
        end
        local state = notes.status()
        if state.count == 0 then
          return ""
        end
        return string.format("%s %d ", state.shown and "󰦢" or "󰦣", state.count)
      end

      require("staline").setup({
        sections = {
          left = { "mode", "branch", "file_name" },
          mid = {},
          right = { get_notes_status, get_format_status, "file_size", "line_column" },
        },
        defaults = {
          inactive_color = get_fg("Normal"),
          expand_null_ls = false,
          line_column = ":%c [%l/%L]",
          file_size_suffix = true,
          branch_symbol = " ",
        },
        mode_colors = {
          n = get_fg("Normal"),
          i = get_fg("String"),
          c = get_fg("Special"),
          v = get_fg("Statement"),
          V = get_fg("Statement"),
          [""] = get_fg("Statement"),
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
          [""] = "V-BLOCK",
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

      vim.defer_fn(function()
        vim.cmd("redrawstatus!")
      end, 10)
    end,
  },
}
