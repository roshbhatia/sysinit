local core = require("core")

-- Register modules
local modules = {
  "editor",
  "keybindings", 
  "layout", 
  "lsp", 
  "themes"
}

for _, module_name in ipairs(modules) do
  local ok, mod = pcall(require, module_name)
  if ok then
    core.register(module_name, mod)
  else
    vim.notify("Failed to load module: " .. module_name, vim.log.levels.ERROR)
  end
end

return {}
