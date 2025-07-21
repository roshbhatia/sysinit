local theme_config = require("sysinit.theme_config")

local M = {}

local function get_transparency_config()
  return theme_config.transparency.enable and {
    transparent_background = true,
    show_end_of_buffer = false,
  } or {
    transparent_background = false,
    show_end_of_buffer = true,
  }
end

local function get_catppuccin_config()
  local transparency = get_transparency_config()
  
  return {
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
      aerial = true, alpha = true, avante = true, cmp = true,
      dap = { enabled = true, enable_ui = true }, dap_ui = true,
      dropbar = { enabled = true, color_mode = true }, fzf = true,
      gitsigns = true, grug_far = true, hop = true,
      indent_blankline = { enabled = true, scope_color = "lavender", colored_indent_levels = true },
      lsp_trouble = true, mason = true,
      native_lsp = { enabled = true, virtual_text = { errors = { "italic" }, hints = { "italic" } } },
      neotree = true, noice = true, notify = true, nvimtree = true,
      render_markdown = true, semantic_tokens = true, snacks = { enabled = true },
      telescope = { enabled = true, style = "nvchad" }, treesitter = true,
      treesitter_context = true, ufo = true, which_key = true, window_picker = true,
    },
  }
end

local function get_rose_pine_config()
  local transparency = get_transparency_config()
  
  return {
    variant = theme_config.variant,
    dark_variant = "moon",
    disable_background = transparency.transparent_background,
    disable_float_background = transparency.transparent_background,
    disable_italics = false,
    groups = {
      background = "base",
      panel = "surface",
      border = "highlight_med",
      comment = "muted",
      link = "iris",
      punctuation = "subtle",
      error = "love",
      hint = "iris",
      info = "foam",
      warn = "gold",
      headings = {
        h1 = "iris",
        h2 = "foam", 
        h3 = "rose",
        h4 = "gold",
        h5 = "pine",
        h6 = "foam",
      }
    },
  }
end

local function get_gruvbox_config()
  local transparency = get_transparency_config()
  
  return {
    terminal_colors = true,
    undercurl = true,
    underline = true,
    bold = true,
    italic = {
      strings = true,
      emphasis = true,
      comments = true,
      operators = false,
      folds = true,
    },
    strikethrough = true,
    invert_selection = false,
    invert_signs = false,
    invert_tabline = false,
    invert_intend_guides = false,
    inverse = true,
    contrast = "hard",
    palette_overrides = {},
    overrides = {},
    dim_inactive = false,
    transparent_mode = transparency.transparent_background,
  }
end

local function get_solarized_config()
  local transparency = get_transparency_config()
  
  return {
    transparent = transparency.transparent_background,
    terminal_colors = true,
    styles = {
      comments = { italic = true },
      keywords = { italic = true },
      functions = { bold = true },
      variables = {},
      constants = { bold = true },
      types = { bold = true },
    },
    on_highlights = function(highlights, colors)
      local bg = transparency.transparent_background and colors.none or colors.base03
      highlights.Normal = { bg = bg, fg = colors.base0 }
      highlights.NormalNC = { bg = bg }
      highlights.SignColumn = { bg = bg }
      highlights.CursorLine = { bg = colors.none }
      highlights.Visual = { bg = colors.base02, fg = colors.base1, bold = true }
    end,
  }
end

local function setup_theme()
  local plugin_config = theme_config.plugins[theme_config.colorscheme]
  
  if theme_config.colorscheme == "catppuccin" then
    require("catppuccin").setup(get_catppuccin_config())
  elseif theme_config.colorscheme == "rose-pine" then
    require("rose-pine").setup(get_rose_pine_config())
  elseif theme_config.colorscheme == "gruvbox" then
    require("gruvbox").setup(get_gruvbox_config())
  elseif theme_config.colorscheme == "solarized" then
    require("solarized-osaka").setup(get_solarized_config())
  end
  
  vim.cmd("colorscheme " .. plugin_config.colorscheme)
end

M.plugins = {
  {
    theme_config.plugins[theme_config.colorscheme].plugin,
    name = theme_config.plugins[theme_config.colorscheme].name,
    lazy = false,
    priority = 1000,
    config = setup_theme,
  },
}

return M
