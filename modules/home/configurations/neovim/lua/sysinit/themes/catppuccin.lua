local json_loader = require("sysinit.pkg.utils.json_loader")
local theme_config = json_loader.load_json_file(json_loader.get_config_path("theme_config.json"))

local M = {}

function M.setup(transparency)
  local config = {
    flavour = theme_config.variant,
    show_end_of_buffer = transparency.show_end_of_buffer,
    transparent_background = transparency.transparent_background,
    term_colors = true,
    dim_inactive = {
      enabled = true,
      shade = "dark",
      percentage = 0.15,
    },
    styles = {
      comments = { "italic" },
      conditionals = { "italic" },
      loops = { "bold" },
      functions = { "bold" },
      keywords = { "italic", "bold" },
      strings = { "italic" },
      variables = {},
      numbers = { "bold" },
      booleans = { "bold", "italic" },
      properties = { "italic" },
      types = { "bold" },
      operators = { "bold" },
    },
    color_overrides = {
      [theme_config.variant] = {
        base = "#1e1e2e",
        mantle = "#181825",
        crust = "#11111b",
        blue = "#7287c7",
        green = "#9cb380",
        yellow = "#d4c481",
        red = "#d67b7b",
        pink = "#d19bc4",
        teal = "#7fb3aa",
        lavender = "#9da3d4",
        peach = "#c7a584",
        mauve = "#b39bc7",
      },
    },
    highlight_overrides = {
      [theme_config.variant] = function(colors)
        local bg = theme_config.transparency.enable and colors.none or colors.base
        return {
          Normal = { bg = bg },
          NormalNC = { bg = bg },
          CursorLine = { bg = colors.none },
          CursorLineNr = { fg = colors.lavender, style = { "bold" } },
          LineNr = { fg = colors.overlay1 },
          Visual = { bg = colors.surface1, style = { "bold" } },
          Search = { bg = colors.yellow, fg = colors.base, style = { "bold" } },
          IncSearch = { bg = colors.red, fg = colors.base, style = { "bold" } },
          Pmenu = { bg = colors.none, fg = colors.text },
          PmenuSel = { bg = colors.surface0, fg = colors.lavender, style = { "bold" } },
          PmenuBorder = { fg = colors.lavender, bg = colors.none },
          FloatBorder = { fg = colors.lavender, bg = colors.none },
          NormalFloat = { bg = colors.none },
          FloatTitle = { fg = colors.pink, bg = colors.none, style = { "bold" } },
          TelescopeBorder = { fg = colors.blue, bg = colors.none },
          TelescopeNormal = { bg = colors.none },
          TelescopeSelection = { bg = colors.surface0, fg = colors.lavender, style = { "bold" } },
          TelescopeTitle = { fg = colors.pink, bg = colors.none, style = { "bold" } },
          WhichKeyBorder = { fg = colors.lavender, bg = colors.none },
          WhichKeyFloat = { bg = colors.none },
          DiagnosticError = { fg = colors.red, style = { "bold" } },
          DiagnosticWarn = { fg = colors.yellow, style = { "bold" } },
          DiagnosticInfo = { fg = colors.blue, style = { "bold" } },
          DiagnosticHint = { fg = colors.teal, style = { "bold" } },
          GitSignsAdd = { fg = colors.green, style = { "bold" } },
          GitSignsChange = { fg = colors.yellow, style = { "bold" } },
          GitSignsDelete = { fg = colors.red, style = { "bold" } },
          StatusLine = { bg = colors.none, fg = colors.text },
          StatusLineNC = { bg = colors.none, fg = colors.overlay1 },
          WinSeparator = { fg = colors.blue, bg = colors.none, style = { "bold" } },
          SignColumn = { bg = colors.none },
        }
      end,
    },
    integrations = {
      aerial = true,
      alpha = true,
      avante = true,
      cmp = true,
      dap = { enabled = true, enable_ui = true },
      dap_ui = true,
      dropbar = { enabled = true, color_mode = true },
      fzf = true,
      gitsigns = true,
      grug_far = true,
      hop = true,
      indent_blankline = { enabled = true, scope_color = "lavender", colored_indent_levels = true },
      lsp_trouble = true,
      mason = true,
      native_lsp = { enabled = true, virtual_text = { errors = { "italic" }, hints = { "italic" } } },
      neotree = true,
      notify = true,
      nvimtree = true,
      render_markdown = true,
      semantic_tokens = true,
      snacks = { enabled = true },
      telescope = { enabled = true, style = "nvchad" },
      treesitter = true,
      treesitter_context = true,
      ufo = true,
      which_key = true,
      window_picker = true,
    },
  }

  require("catppuccin").setup(config)
end

function M.get_transparent_highlights()
  return {
    Normal = { bg = "none" },
    NormalNC = { bg = "none" },
    CursorLine = { bg = "none" },
    Pmenu = { bg = "none" },
    NormalFloat = { bg = "none" },
    FloatBorder = { bg = "none" },
    TelescopeNormal = { bg = "none" },
    TelescopeBorder = { bg = "none" },
    WhichKeyFloat = { bg = "none" },
    WhichKeyBorder = { bg = "none" },
    SignColumn = { bg = "none" },
    StatusLine = { bg = "none" },
    StatusLineNC = { bg = "none" },
    WinSeparator = { bg = "none" },
  }
end

return M
