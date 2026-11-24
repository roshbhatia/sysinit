vim.opt.runtimepath:append(assert(arg[1]))
vim.opt.runtimepath:append(assert(arg[2]))
vim.cmd.runtime("plugin/sysinit-workbench.lua")

local root = vim.fn.tempname()
vim.fn.mkdir(root)
root = assert(vim.uv.fs_realpath(root))
vim.fn.chdir(root)
local function git(args, env)
  local result = vim.system(vim.list_extend({ "git" }, args), { env = env, text = true }):wait()
  assert(result.code == 0, result.stderr)
  return result.stdout
end

git({ "init", "--quiet", "--template=" })
vim.fn.writefile({ "original" }, "tracked.txt")
git({ "add", "tracked.txt" })
git({ "config", "user.email", "test@example.com" })
git({ "config", "user.name", "Test" })
git({ "commit", "--quiet", "-m", "Initial" })
vim.fn.writefile({ "staged" }, "tracked.txt")
git({ "add", "tracked.txt" })
vim.fn.writefile({ "working" }, "tracked.txt")
vim.fn.writefile({ "untracked contents" }, "new file.txt")
local real_index = { GIT_INDEX_FILE = root .. "/.git/index" }
local staged = git({ "diff", "--cached" }, real_index)

local transport = require("reviewr.transport")
transport.detect = function(_repo)
  return {
    { transport = "wezterm", id = "10" },
    { transport = "wezterm", id = "11" },
    { transport = "neovim-terminal", id = "10" },
  }
end
vim.env.SYSINIT_REVIEW_PANE = "10"
local review = require("sysinit_workbench.review")
assert(review.open())
assert(vim.g.sysinit_review_ready == 1)
local candidates = transport.detect(root)
assert(#candidates == 1 and candidates[1].id == "10" and candidates[1].transport == "wezterm")
assert(git({ "diff", "HEAD", "--name-only" }):find("new file.txt", 1, true))
assert(vim.inspect(require("reviewr.state").get().files):find("new file.txt", 1, true))
local reviewr = require("reviewr")
reviewr.mark_turn()
local baseline = require("reviewr.turn").last_turn_sha(root, { name = "turn" })
assert(baseline)
vim.fn.writefile({ "another untracked file" }, "later.txt")
assert(review.refresh() == 1)
assert(vim.inspect(require("reviewr.state").get().files):find("later.txt", 1, true))
assert(git({ "diff", "--cached" }, real_index) == staged)
assert(
  git({ "ls-files", "--others", "--exclude-standard" }, real_index) == "later.txt\nnew file.txt\n"
)
assert(reviewr.set_scope("turn"))
assert(require("reviewr.state").get().base_ref == baseline)
assert(not vim.inspect(require("reviewr.state").get().files):find("new file.txt", 1, true))
vim.env.GIT_INDEX_FILE = nil

local function await_text(buffer, target)
  local function contents()
    return table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), "\n")
  end
  assert(
    vim.wait(10000, function()
      return contents():find(target, 1, true) ~= nil
    end),
    contents()
  )
  return contents()
end

vim.cmd.Changes({
  args = { "--no-groups", "--no-symbols", "--no-calls", "--no-notes", "--quiet" },
})
local buffer = vim.api.nvim_get_current_buf()
local contents = await_text(buffer, "tracked.txt")
assert(contents:find("Changes · ", 1, true))
assert(not vim.bo[buffer].modifiable)

for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(buffer, "n")) do
  if mapping.lhs == "p" then
    mapping.callback()
    break
  end
end
assert(vim.api.nvim_buf_get_name(0):find("changes://diff", 1, true))
assert(vim.bo.filetype == "diff")
await_text(vim.api.nvim_get_current_buf(), "+ working")
vim.cmd.tabclose()
assert(vim.api.nvim_get_current_buf() == buffer)

vim.cmd.Changes({
  args = { "--staged", "--no-groups", "--no-symbols", "--no-calls", "--no-notes", "--quiet" },
})
await_text(vim.api.nvim_get_current_buf(), "· staged")

local function message(session, body)
  return {
    timeUnixNano = "1794772800000000000",
    eventName = "agent.assistant",
    body = { stringValue = body },
    attributes = { { key = "session.id", value = { stringValue = session } } },
  }
end

local file = vim.fn.tempname()
local config = vim.fn.tempname()
vim.fn.writefile({ "{}" }, config)
vim.fn.writefile({
  vim.json.encode({
    resourceLogs = {
      {
        scopeLogs = {
          {
            logRecords = {
              message("example-session", "Expected assistant reply"),
              message("example-session-other", "Other assistant reply"),
            },
          },
        },
      },
    },
  }),
}, file)
vim.cmd.Traces({
  args = { "--file", file, "--config", config, "--session", "example-session" },
})
contents = await_text(vim.api.nvim_get_current_buf(), "Expected assistant reply")
assert(not contents:find("Other assistant reply", 1, true))

vim.ui.select = function(sessions, _opts, select)
  assert(#sessions == 2)
  for _, session in ipairs(sessions) do
    if session.session == "example-session-other" then
      return select(session)
    end
  end
  error("Traces did not discover the second session")
end
vim.cmd.Traces({
  args = { "--all", "--file", file, "--config", config },
})
assert(vim.wait(10000, function()
  return vim.api.nvim_buf_get_name(0):find("traces://transcript/example-session-other", 1, true)
end))
await_text(vim.api.nvim_get_current_buf(), "Other assistant reply")

local empty = vim.fn.tempname()
vim.fn.writefile({ "{}" }, empty)
vim.cmd.Traces({
  args = { "--all", "--file", empty, "--config", config },
})
await_text(vim.api.nvim_get_current_buf(), "No Traces sessions in this scope")
