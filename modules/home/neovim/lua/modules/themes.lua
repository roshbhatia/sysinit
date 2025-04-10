local M = {}

-- Store currently active theme
M.active_theme = nil
M.color_cache = {}

-- Define theme module dependencies
M.depends_on = { "core" }

M.plugins = {
  {
    "zaldih/themery.nvim",
    lazy = false,
    opts = {
      themes = {
        { name = "Gruvbox Dark", colorscheme = "gruvbox", before = [[vim.opt.background = "dark"]] },
        { name = "Gruvbox Light", colorscheme = "gruvbox", before = [[vim.opt.background = "light"]] },
        { name = "Kanagawa Dragon", colorscheme = "kanagawa-dragon" },
        { name = "Kanagawa Wave", colorscheme = "kanagawa-wave" },
        { name = "Catppuccin Mocha", colorscheme = "catppuccin-mocha" },
        { name = "Catppuccin Latte", colorscheme = "catppuccin-latte" },
        { name = "Tokyonight Storm", colorscheme = "tokyonight-storm" },
        { name = "Tokyonight Night", colorscheme = "tokyonight-night" },
        { name = "Carbonfox", colorscheme = "carbonfox" },
        { name = "Nightfox", colorscheme = "nightfox" },
        { name = "Duskfox", colorscheme = "duskfox" },
        { name = "Nord", colorscheme = "nord" },
        { name = "Onedark", colorscheme = "onedark" },
        { name = "Onenord", colorscheme = "onenord" },
        { name = "Rose Pine", colorscheme = "rose-pine" },
        { name = "Rose Pine Moon", colorscheme = "rose-pine-moon" },
        { name = "Dracula", colorscheme = "dracula" },
        { name = "Material Deep Ocean", colorscheme = "material-deep-ocean" },
        { name = "Github Dark", colorscheme = "github_dark" },
        { name = "Oxocarbon Dark", colorscheme = "oxocarbon" },
        { name = "Everforest Dark", colorscheme = "everforest", before = [[vim.opt.background = "dark"]] },
        { name = "Everforest Light", colorscheme = "everforest", before = [[vim.opt.background = "light"]] },
        { name = "Sonokai", colorscheme = "sonokai" },
        { name = "Edge", colorscheme = "edge" },
        { name = "Melange", colorscheme = "melange" },
        { name = "Moonfly", colorscheme = "moonfly" },
        { name = "Nightfly", colorscheme = "nightfly" },
        { name = "Tokyo Night Moon", colorscheme = "tokyonight-moon" },
        { name = "Calvera Dark", colorscheme = "calvera" },
        { name = "Minimal", colorscheme = "minimal" },
      },
      livePreview = true,
      themeConfigFile = vim.fn.stdpath("config") .. "/lua/theme_config.lua",
      -- Hook into theme changes to update our records
      on_change = function(theme)
        M.active_theme = theme.name
        M._extract_theme_colors(theme.colorscheme)
        -- Notify other modules about theme change
        require("core.state").emit("theme.changed", {
          name = theme.name,
          colorscheme = theme.colorscheme,
          colors = M.get_colors()
        })
      end
    },
    keys = {
      { "<leader>9", "<cmd>Themery<CR>", desc = "Switch Theme" },
    },
  },

  -- Theme preview command
  {
    "rktjmp/lush.nvim",
    lazy = true,
    cmd = { "ThemePreview" },
  },
  
  -- Theme plugins
  { "gruvbox-community/gruvbox" },
  { "rebelot/kanagawa.nvim" },
  { "catppuccin/nvim", name = "catppuccin" },
  { "folke/tokyonight.nvim" },
  { "EdenEast/nightfox.nvim" },
  { "shaunsingh/nord.nvim" },
  { "navarasu/onedark.nvim" },
  { "rmehri01/onenord.nvim" },
  { "rose-pine/neovim", name = "rose-pine" },
  { "Mofiqul/dracula.nvim" },
  { "marko-cerovac/material.nvim" },
  { "projekt0n/github-nvim-theme" },
  { "nyoom-engineering/oxocarbon.nvim" },
  { "sainnhe/everforest" },
  { "sainnhe/sonokai" },
  { "sainnhe/edge" },
  { "savq/melange-nvim" },
  { "bluz71/vim-moonfly-colors" },
  { "bluz71/vim-nightfly-colors" },
  { "yashguptaz/calvera-dark.nvim" },
  { "Yazeed1s/minimal.nvim" },
}

-- Color scheme API functions
function M.get_active_theme()
  return M.active_theme
end

function M.get_colors()
  if not M.color_cache then
    return {}
  end
  return M.color_cache
end

function M.get_color(name)
  return M.color_cache and M.color_cache[name]
end

function M._extract_theme_colors(colorscheme)
  -- Reset color cache
  M.color_cache = {}
  
  -- Extract colors from current highlight groups
  local function get_hl_color(group, attr)
    local hl = vim.api.nvim_get_hl(0, { name = group })
    return hl and hl[attr] and string.format("#%06x", hl[attr])
  end
  
  -- Get core colors from common highlight groups
  M.color_cache.bg = get_hl_color("Normal", "bg")
  M.color_cache.fg = get_hl_color("Normal", "fg")
  M.color_cache.accent = get_hl_color("Special", "fg") or get_hl_color("Keyword", "fg")
  M.color_cache.selection = get_hl_color("Visual", "bg")
  M.color_cache.comment = get_hl_color("Comment", "fg")
  M.color_cache.keyword = get_hl_color("Keyword", "fg")
  M.color_cache.string = get_hl_color("String", "fg")
  M.color_cache.func = get_hl_color("Function", "fg")
  M.color_cache.constant = get_hl_color("Constant", "fg")
  M.color_cache.error = get_hl_color("Error", "fg")
  M.color_cache.warning = get_hl_color("WarningMsg", "fg")
  M.color_cache.info = get_hl_color("DiagnosticInfo", "fg")
  M.color_cache.hint = get_hl_color("DiagnosticHint", "fg")
  
  -- Determine if theme is dark or light
  if M.color_cache.bg then
    local bg_dec = tonumber(M.color_cache.bg:sub(2), 16)
    M.color_cache.is_dark = bg_dec and bg_dec < 0x808080
  else
    M.color_cache.is_dark = vim.opt.background:get() == "dark"
  end
  
  -- Store in state
  local state = require("core.state")
  state.set("themes", "colors", M.color_cache)
  state.set("themes", "active", M.active_theme)
  
  return M.color_cache
end

-- Theme preview system
function M.create_preview()
  -- Create a new floating window with theme preview
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Sample content to display theme
  local lines = {
    "# Theme Preview",
    "============================================",
    "Normal text in the current theme",
    "",
    "function exampleFunction() {",
    "  // This is a comment",
    "  const string = \"This is a string\";",
    "  return calculateValue(string, 42);",
    "}",
    "",
    "Error: This is an error message",
    "Warning: This is a warning message",
    "Info: This is an info message",
    "Hint: This is a hint message",
    "",
    "Color Palette:",
  }
  
  -- Add color samples
  local colors = M.get_colors()
  for name, color in pairs(colors) do
    if type(color) == "string" and color:sub(1, 1) == "#" then
      table.insert(lines, string.format("%s: %s", name, color))
    end
  end
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Apply highlight groups
  vim.api.nvim_buf_add_highlight(buf, -1, "Title", 0, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, -1, "Normal", 2, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, -1, "Function", 4, 0, 21)
  vim.api.nvim_buf_add_highlight(buf, -1, "Comment", 5, 2, -1)
  vim.api.nvim_buf_add_highlight(buf, -1, "String", 6, 16, -1)
  vim.api.nvim_buf_add_highlight(buf, -1, "Error", 9, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, -1, "WarningMsg", 10, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, -1, "DiagnosticInfo", 11, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, -1, "DiagnosticHint", 12, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, -1, "Title", 14, 0, -1)
  
  -- Create floating window
  local width = 60
  local height = #lines
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " Theme Preview ",
    title_pos = "center",
  })
  
  -- Set options
  vim.api.nvim_win_set_option(win, "winblend", 0)
  
  -- Add keymaps to close
  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":close<CR>", { noremap = true, silent = true })
  
  return buf, win
end

-- Add user commands for theme management
function M._setup_commands()
  vim.api.nvim_create_user_command("ThemePreview", function()
    M.create_preview()
  end, {})
  
  vim.api.nvim_create_user_command("ThemeColors", function()
    local colors = M.get_colors()
    local lines = {"Current Theme Colors:"}
    
    for name, color in pairs(colors) do
      if type(color) == "string" and color:sub(1, 1) == "#" then
        table.insert(lines, string.format("%s: %s", name, color))
      end
    end
    
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  end, {})
end

-- Setup tests
local test = require("core.test")
test.register_test("theme_api", function()
  local tests = {
    function()
      print("Testing color extraction...")
      local colors = M._extract_theme_colors(vim.g.colors_name)
      assert(colors.bg, "Background color should be extracted")
      assert(colors.fg, "Foreground color should be extracted")
      return true, "Color extraction works"
    end,
    
    function()
      print("Testing theme preview...")
      local buf, win = M.create_preview()
      assert(buf, "Preview buffer should be created")
      assert(win, "Preview window should be created")
      vim.api.nvim_win_close(win, true)
      return true, "Theme preview works"
    end,
    
    function()
      print("Testing state integration...")
      local state = require("core.state")
      local colors = state.get("themes", "colors")
      assert(colors, "Theme colors should be stored in state")
      assert(state.get("themes", "active"), "Active theme should be stored in state")
      return true, "State integration works"
    end
  }
  
  for i, test_fn in ipairs(tests) do
    local success, msg = pcall(test_fn)
    if not success then
      return false, "Test " .. i .. " failed: " .. msg
    end
  end
  
  return true, "All theme API tests passed"
end)

-- Add verification steps
local verify = require("core.verify")
verify.register_verification("themes", {
  {
    desc = "Check if Themery is available",
    command = ":Themery",
    expected = "Should open theme picker with all configured themes",
  },
  {
    desc = "Test theme switching shortcut",
    command = "<leader>9",
    expected = "Should open Themery picker",
  },
  {
    desc = "Verify dark theme",
    command = "Select 'Gruvbox Dark' from Themery",
    expected = "Should switch to dark theme with correct background",
  },
  {
    desc = "Verify light theme",
    command = "Select 'Gruvbox Light' from Themery",
    expected = "Should switch to light theme with correct background",
  },
  {
    desc = "Check theme preview",
    command = ":ThemePreview",
    expected = "Should show preview window with current theme colors",
  },
  {
    desc = "Check theme colors command",
    command = ":ThemeColors",
    expected = "Should show notification with color information",
  },
})

function M.setup()
  -- Extract colors after theme is fully loaded
  vim.defer_fn(function()
    M.active_theme = vim.g.colors_name
    M._extract_theme_colors(M.active_theme)
  end, 100)
  
  -- Setup commands
  M._setup_commands()
  
  -- Listen to theme change events
  local state = require("core.state")
  state.mark_persistent("themes")
  
  -- Store theme state for persistence
  state.subscribe("themes", "active", function(theme_name)
    -- When theme changes, update other modules that might depend on colors
    state.emit("theme.changed", {
      name = theme_name,
      colors = M.get_colors()
    })
  end)
end

require("core").register("themes", M)

return M