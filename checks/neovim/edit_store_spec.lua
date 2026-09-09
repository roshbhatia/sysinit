local busted = require("plenary.busted")
local assert = require("luassert")

-- The path is a contract with gate's edit-event provider, which derives the
-- same stem with go-utils' paths.Keyed. A drift here reads an empty log and
-- reports "no agent write is recorded" while the provider keeps writing.
busted.describe("harness.edit_store", function()
  local state_home

  busted.before_each(function()
    state_home = vim.fn.tempname()
    vim.fn.mkdir(state_home .. "/sysinit", "p")
    vim.env.XDG_STATE_HOME = state_home
    vim.env.SYSINIT_WORKSPACE = nil
    package.loaded["harness.edit_store"] = nil
  end)

  busted.it("keys the stem on the base name and the first 16 hex of sha256(root)", function()
    local store = require("harness.edit_store")
    -- printf %s /work/alpha | sha256sum | cut -c1-16
    assert.are.equal("/edits/alpha-017094432d2c0fa9", store.keyed("/edits", "/work/alpha"))
    assert.are_not.equal(store.keyed("/edits", "/work/alpha"), store.keyed("/edits", "/other/alpha"))
  end)

  busted.it("falls to <state>/agents/edits with no manifest", function()
    local store = require("harness.edit_store")
    assert.are.equal(state_home .. "/agents/edits", store.edits_dir())
    assert.is_truthy(store.log_file("/work/alpha"):find("^" .. vim.pesc(state_home .. "/agents/edits/alpha-")))
    assert.is_truthy(store.log_file("/work/alpha"):find("%.jsonl$"))
    assert.is_truthy(store.delta_dir("/work/alpha"):find("%.delta$"))
  end)

  busted.it("reads agentEdits from the paths manifest", function()
    local manifest = assert(io.open(state_home .. "/sysinit/paths.json", "w"))
    manifest:write(vim.json.encode({ version = 1, paths = { agentEdits = "/elsewhere/edits" } }))
    manifest:close()
    local store = require("harness.edit_store")
    assert.are.equal("/elsewhere/edits", store.edits_dir())
  end)

  busted.it("resolves the workspace as declared, then the git top level, then the cwd", function()
    local store = require("harness.edit_store")
    local root = vim.fn.tempname()
    vim.fn.mkdir(root .. "/repo/nested", "p")
    vim.fn.system({ "git", "-C", root .. "/repo", "init", "-q" })
    local physical = vim.uv.fs_realpath(root)
    assert.are.equal(physical .. "/repo", store.workspace(root .. "/repo/nested"))

    vim.env.SYSINIT_WORKSPACE = root .. "/"
    assert.are.equal(root, store.workspace(root .. "/repo/nested"))
    vim.env.SYSINIT_WORKSPACE = root .. "/unrelated"
    assert.are.equal(physical .. "/repo", store.workspace(root .. "/repo/nested"))

    vim.env.SYSINIT_WORKSPACE = nil
    vim.fn.mkdir(root .. "/plain", "p")
    assert.are.equal(root .. "/plain", store.workspace(root .. "/plain/"))
  end)
end)
