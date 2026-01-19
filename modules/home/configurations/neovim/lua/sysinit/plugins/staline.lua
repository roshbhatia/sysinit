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

      require("staline").setup({
        sections = {
          left = {
            "mode",
            "branch",
            "file_name",
          },
          mid = {},
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
