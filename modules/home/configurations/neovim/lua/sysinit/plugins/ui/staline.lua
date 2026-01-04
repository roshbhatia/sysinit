local json_loader = require("sysinit.utils.json_loader")
local theme_config = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"), "theme_config")

local M = {}

local function get_git_blame_text()
  local ok, git_blame = pcall(require, "gitblame")
  if not ok then
    return ""
  end

  if git_blame.is_blame_text_available and git_blame.is_blame_text_available() then
    local text = git_blame.get_current_blame_text()
    local by_index = string.find(text, " by ")
    if by_index then
      local msg = string.sub(text, 1, by_index - 1)
      local rest = string.sub(text, by_index)
      if #msg > 32 then
        msg = string.sub(msg, 1, 29) .. "..."
      end
      return msg .. rest
    else
      if #text > 32 then
        return string.sub(text, 1, 29) .. "..."
      else
        return text
      end
    end
  else
    return ""
  end
end

M.plugins = {
  {
    "tamton-aquib/staline.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    event = "VeryLazy",
    config = function()
      require("staline").setup({
        sections = {
          left = {
            "mode",
            "branch",
          },
          mid = {
            {
              "mode",
              get_git_blame_text,
            },
          },
          right = {
            "file_size",
            "line_column",
          },
        },
        defaults = {
          expand_null_ls = false,
          true_colors = true,
          line_column = ":%c [%l/%L]",
          lsp_symbols = {
            Error = "󰅙 ",
            Info = "󰋼 ",
            Warn = "󰀨 ",
            Hint = " ",
          },
          lsp_client_character_length = 40,
          file_size_suffix = true,
          branch_symbol = " ",
        },
        special_table = {
          qf = { "QuickFix", " 󰂺 " },
        },
        mode_icons = {
          ["n"] = "  ",
          ["no"] = "  ",
          ["niI"] = "  ",
          ["niR"] = "  ",
          ["niV"] = "  ",
          ["nov"] = "  ",
          ["noV"] = "  ",
          ["i"] = " 󰘧 ",
          ["ic"] = " 󰘧 ",
          ["ix"] = " 󰘧 ",
          ["s"] = " 󰘧 ",
          ["S"] = " 󰘧 ",
          ["v"] = " 󰈈 ",
          ["V"] = " 󰈈 ",
          [""] = " 󰈈 ",
          ["r"] = " 󰛔 ",
          ["r?"] = "  ",
          ["c"] = "  ",
          ["t"] = "  ",
          ["!"] = "  ",
          ["R"] = "  ",
        },
        mode_colors = {
          n = theme_config.semanticColors.semantic.info,
          no = theme_config.semanticColors.semantic.info,
          niI = theme_config.semanticColors.semantic.info,
          niR = theme_config.semanticColors.semantic.info,
          niV = theme_config.semanticColors.semantic.info,
          nov = theme_config.semanticColors.semantic.info,
          noV = theme_config.semanticColors.semantic.info,
          i = theme_config.semanticColors.accent.primary,
          ic = theme_config.semanticColors.accent.primary,
          ix = theme_config.semanticColors.accent.primary,
          s = theme_config.semanticColors.accent.secondary,
          S = theme_config.semanticColors.accent.secondary,
          v = theme_config.semanticColors.semantic.error,
          V = theme_config.semanticColors.semantic.error,
          [""] = theme_config.semanticColors.semantic.error,
          r = theme_config.semanticColors.semantic.error,
          R = theme_config.semanticColors.semantic.error,
          c = theme_config.semanticColors.semantic.warning,
          t = theme_config.semanticColors.semantic.success,
          ["!"] = theme_config.semanticColors.semantic.success,
        },
      })
    end,
  },
}

return M
