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

local lazy_keys = {}
for _, path in ipairs({ "gitsigns.lua", "snacks.lua" }) do
  local specs = dofile(config_root .. "/lua/plugins/" .. path)
  for _, spec in ipairs(specs) do
    for _, binding in ipairs(spec.keys or {}) do
      lazy_keys[binding[1]] = true
    end
  end
end
for key in pairs(movement_maps) do
  assert(not lazy_keys[key], key .. " collides with a lazy key binding")
end

print("Neovim context and key integration passed")
