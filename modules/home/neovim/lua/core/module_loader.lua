local M = {}

M.modules = {
  editor = {
    "which-key",
    "telescope", 
    "oil",
    "wilder",
  },
  ui = {
    "devicons",
    "dropbar",
    "lualine",
    "neominimap",
    "nvimtree", 
    "wezterm",
  },
  tools = {
    "autosession",
    "comment",
    "hop",
    "neoscroll",
    "treesitter",
  }
}

function M.get_plugin_specs()
  local specs = {}
  
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

function M.setup_modules()
  local which_key_ok, which_key = pcall(require, "modules.editor.which-key")
  if which_key_ok and which_key.setup then
    which_key.setup()
  end
  
  local categories = {"editor", "ui", "tools"}
  
  for _, category in ipairs(categories) do
    for _, module_name in ipairs(M.modules[category]) do
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