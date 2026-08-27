local config_root = vim.fs.abspath(assert(arg[1], "Neovim config path is required"))

package.path = table.concat({
  config_root .. "/lua/?.lua",
  config_root .. "/lua/?/init.lua",
  package.path,
}, ";")

local function equal(actual, expected, label)
  if actual ~= expected then
    error(string.format("%s: got %q, want %q", label, actual, expected))
  end
end

local function run_git(cwd, ...)
  local command = { "git", "-C", cwd }
  vim.list_extend(command, { ... })
  local result = vim.system(command, { text = true }):wait()
  if result.code ~= 0 then
    error(result.stderr or table.concat(command, " "))
  end
  return result.stdout or ""
end

local temporary = vim.fn.tempname()
local repo_a = temporary .. "/repo-a"
local repo_b = temporary .. "/repo-b"
vim.fn.mkdir(repo_a, "p")
vim.fn.mkdir(repo_b, "p")

for _, repo in ipairs({ repo_a, repo_b }) do
  run_git(repo, "init", "--quiet")
  run_git(repo, "config", "user.name", "editor check")
  run_git(repo, "config", "user.email", "editor-check@localhost")
  run_git(repo, "config", "commit.gpgsign", "false")
  vim.fn.writefile({ "old" }, repo .. "/tracked.txt")
  run_git(repo, "add", "tracked.txt")
  run_git(repo, "commit", "--quiet", "-m", "seed")
end

vim.fn.writefile({ "new" }, repo_a .. "/tracked.txt")
vim.fn.chdir(repo_b)

local buffer = vim.fn.bufadd(repo_a .. "/tracked.txt")
vim.fn.bufload(buffer)
local editor = {
  buf = buffer,
  cwd = repo_b,
  row = 1,
  col = 1,
}

local context = require("harness.context")
local placeholders = require("harness.placeholders").providers
equal(context.get_git_root(repo_a), assert(vim.uv.fs_realpath(repo_a)), "explicit Git root")
equal(context.strip_git_root(repo_a .. "/tracked.txt"), "tracked.txt", "repository-relative path")

context.setup()
local context_autocmds = vim.api.nvim_get_autocmds({ group = "harness_context" })
equal(#context_autocmds, 4, "context autocmd count")
context.setup()
equal(#vim.api.nvim_get_autocmds({ group = "harness_context" }), #context_autocmds, "idempotent context setup")

local status = assert(placeholders.git(editor), "Git status was empty")
assert(status:find("tracked.txt", 1, true), "Git status used the editor working directory")
local diff = assert(placeholders.diff(editor), "Git diff was empty")
assert(diff:find("-old", 1, true), "Git diff missed the old line")
assert(diff:find("+new", 1, true), "Git diff missed the new line")

local move_config
package.loaded["nvim-treesitter-textobjects"] = {
  setup = function(options)
    move_config = options.move
  end,
}
local movement_calls = {}
package.loaded["nvim-treesitter-textobjects.move"] = setmetatable({}, {
  __index = function(_, method)
    return function(capture, group)
      movement_calls[#movement_calls + 1] = { method = method, capture = capture, group = group }
    end
  end,
})
local movement_maps = {}
local keymap_set = vim.keymap.set
vim.keymap.set = function(_, lhs, callback, options)
  movement_maps[lhs] = { callback = callback, description = options.desc }
end
local treesitter_specs = dofile(config_root .. "/lua/plugins/nvim-treesitter.lua")
treesitter_specs[2].config()
vim.keymap.set = keymap_set

assert(move_config.set_jumps, "Tree-sitter motions do not update the jump list")
movement_maps["]C"].callback()
equal(movement_calls[1].method, "goto_next_start", "next class method")
equal(movement_calls[1].capture, "@class.outer", "next class capture")
equal(movement_calls[1].group, "textobjects", "next class query group")

local plugin_files = 0
local plugin_ids = {}
local lazy_keys = {}
for name, kind in vim.fs.dir(config_root .. "/lua/plugins") do
  if kind == "file" and name:match("%.lua$") then
    plugin_files = plugin_files + 1
    local ok, specs = pcall(dofile, config_root .. "/lua/plugins/" .. name)
    assert(ok, name .. " did not load: " .. tostring(specs))
    assert(type(specs) == "table", name .. " returned no plugin specs")
    if type(specs[1]) == "string" then
      specs = { specs }
    end
    for _, spec in ipairs(specs) do
      if type(spec) == "table" then
        local id = spec.name or spec[1]
        if type(id) == "string" then
          assert(not plugin_ids[id], string.format("duplicate plugin %s in %s and %s", id, plugin_ids[id], name))
          plugin_ids[id] = name
        end
        local bindings = type(spec.keys) == "table" and spec.keys or {}
        for _, binding in ipairs(bindings) do
          local modes = type(binding.mode) == "table" and binding.mode or { binding.mode or "n" }
          for _, mode in ipairs(modes) do
            local chord = mode .. "\0" .. tostring(binding[1])
            assert(
              not lazy_keys[chord],
              string.format("duplicate lazy key %s in %s and %s", binding[1], lazy_keys[chord], name)
            )
            lazy_keys[chord] = name
          end
        end
      end
    end
  end
end
assert(plugin_files > 0, "no plugin specs were checked")
assert(plugin_ids.harness == "harness.lua", "the harness is not a registered plugin")
for key in pairs(movement_maps) do
  assert(not lazy_keys["n\0" .. key], key .. " collides with a lazy key binding")
end

local subsystem_calls = {}
for _, spec in ipairs({
  { name = "context", method = "setup" },
  { name = "completion", method = "setup" },
  { name = "file_refresh", method = "start" },
  { name = "edit_events", method = "start" },
  { name = "notes", method = "setup" },
}) do
  package.loaded["harness." .. spec.name] = {
    [spec.method] = function()
      subsystem_calls[#subsystem_calls + 1] = spec.name
      if spec.name == "edit_events" then
        error("expected subsystem failure")
      end
    end,
  }
end
local notifications = {}
local notify = vim.notify
vim.notify = function(message)
  notifications[#notifications + 1] = message
end
package.loaded["harness.api"] = nil
require("harness.api").setup()
vim.notify = notify
equal(table.concat(subsystem_calls, ","), "context,completion,file_refresh,edit_events,notes", "subsystem order")
equal(#notifications, 1, "subsystem failure count")
assert(notifications[1]:find("edit_events", 1, true), "subsystem failure omitted its name")

print("Neovim context and key integration passed")
