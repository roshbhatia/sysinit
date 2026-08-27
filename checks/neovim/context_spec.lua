local busted = require("plenary.busted")
local assert = require("luassert")

local function run_git(cwd, ...)
  local command = { "git", "-C", cwd }
  vim.list_extend(command, { ... })
  local result = vim.system(command, { text = true }):wait()
  assert.are.equal(0, result.code, result.stderr or table.concat(command, " "))
  return result.stdout or ""
end

busted.describe("harness context", function()
  local temporary
  local repo_a
  local repo_b
  local original_cwd

  busted.before_each(function()
    original_cwd = assert(vim.uv.cwd())
    temporary = vim.fn.tempname()
    repo_a = temporary .. "/repo-a"
    repo_b = temporary .. "/repo-b"
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

    package.loaded["harness.context"] = nil
    package.loaded["harness.placeholders"] = nil
  end)

  busted.after_each(function()
    vim.fn.chdir(original_cwd)
    vim.fn.delete(temporary, "rf")
  end)

  busted.it("uses the buffer repository instead of the editor directory", function()
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
    assert.are.equal(vim.uv.fs_realpath(repo_a), context.get_git_root(repo_a))
    assert.are.equal("tracked.txt", context.strip_git_root(repo_a .. "/tracked.txt"))

    local status = assert(placeholders.git(editor), "Git status was empty")
    assert.is_truthy(status:find("tracked.txt", 1, true))
    local diff = assert(placeholders.diff(editor), "Git diff was empty")
    assert.is_truthy(diff:find("-old", 1, true))
    assert.is_truthy(diff:find("+new", 1, true))
  end)

  busted.it("registers its autocmds once", function()
    local context = require("harness.context")
    context.setup()
    local autocmds = vim.api.nvim_get_autocmds({ group = "harness_context" })
    assert.are.equal(4, #autocmds)
    context.setup()
    assert.are.equal(#autocmds, #vim.api.nvim_get_autocmds({ group = "harness_context" }))
  end)
end)
