local function get_all_commands()
  local cmds = {}
  local builtins = vim.api.nvim_get_commands({})
  local user_cmds = vim.api.nvim_get_commands({builtin=false})
  
  for cmd, _ in pairs(builtins) do cmds[cmd] = true end
  for cmd, _ in pairs(user_cmds) do cmds[cmd] = true end
  
  local ex_cmds = vim.fn.execute('command'):split('\n')
  for _, line in ipairs(ex_cmds) do
    local cmd = line:match('^[!]*%s*([%w]+)')
    if cmd then cmds[cmd] = true end
  end
  
  local result_file = io.open("./commands/neovim/all.txt", "w")
  if result_file then
    local sorted = {}
    for cmd in pairs(cmds) do table.insert(sorted, cmd) end
    table.sort(sorted)
    result_file:write(table.concat(sorted, '\n'))
    result_file:close()
  end
end

get_all_commands()
vim.cmd('quit')
