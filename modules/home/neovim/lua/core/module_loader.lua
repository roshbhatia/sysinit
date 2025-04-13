local M = {}

-- List all modules by category
M.modules = {
  ui = {
    "bufferline",
    "carbonfox",
    "devicons",
    "heirline",
    "wezterm",
  },
  editor = {
    "commander", -- Load this first since other modules depend on it
    "telescope", 
    "oil",
    "wilder",
  },
  tools = {
    "comment",
    "hop",
    "treesitter",
    "trouble",
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
  -- Commander must be set up first since other modules register commands with it
  local commander_ok, commander = pcall(require, "modules.editor.commander")
  if commander_ok and commander.setup then
    commander.setup()
  end
  
  -- Process other modules
  local categories = {"editor", "ui", "tools"}
  
  for _, category in ipairs(categories) do
    for _, module_name in ipairs(M.modules[category]) do
      -- Skip commander since we already set it up
      if module_name ~= "commander" then
        local ok, module = pcall(require, "modules." .. category .. "." .. module_name)
        if ok and module.setup then
          module.setup()
        end
      end
    end
  end
end

return M