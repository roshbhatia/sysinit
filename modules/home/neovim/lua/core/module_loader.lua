local M = {}

-- List all modules by category
M.modules = {
  ui = {
    "devicons",
    "dropbar",
    "lualine",
    "neominimap",
    "nvimtree", 
    "wezterm",
  },
  editor = {
    "which-key", -- Load this first to register keybindings
    "telescope", 
    "oil",
    "wilder",
  },
  tools = {
    "autosession",
    "comment",
    "hop",
    "neoscroll",
    "treesitter",
  }
}

-- Get all plugin specs
function M.get_plugin_specs()
  local specs = {}
  
  -- Process modules in a specific order to handle dependencies
  local categories = {"editor", "ui", "tools"}
  
  for _, category in ipairs(categories) do
    for _, module_name in ipairs(M.modules[category]) do
      local ok, module = pcall(require, "modules." .. category .. "." .. module_name)
      if ok and module.plugins then
        vim.list_extend(specs, module.plugins)
      end
    end
  end
  
  return specs
end

-- Set up all modules
function M.setup_modules()
  -- WhichKey must be set up first since other modules will register keybindings
  local which_key_ok, which_key = pcall(require, "modules.editor.which-key")
  if which_key_ok and which_key.setup then
    which_key.setup()
  end
  
  -- Process other modules
  local categories = {"editor", "ui", "tools"}
  
  for _, category in ipairs(categories) do
    for _, module_name in ipairs(M.modules[category]) do
      -- Skip which-key since we already set it up
      if module_name ~= "which-key" then
        local ok, module = pcall(require, "modules." .. category .. "." .. module_name)
        if ok and module.setup then
          module.setup()
        end
      end
    end
  end
end

return M