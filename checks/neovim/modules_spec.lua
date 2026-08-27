local busted = require("plenary.busted")
local assert = require("luassert")

busted.describe("Lua module lifecycle", function()
  local names = {
    "harness.preview",
    "utils.gitrepo",
    "utils.markdown_preview",
  }

  busted.after_each(function()
    for _, name in ipairs(names) do
      package.loaded[name] = nil
    end
  end)

  busted.it("does not register autocmds during require", function()
    local create_autocmd = vim.api.nvim_create_autocmd
    local create_augroup = vim.api.nvim_create_augroup
    local calls = 0
    vim.api.nvim_create_autocmd = function()
      calls = calls + 1
    end
    vim.api.nvim_create_augroup = function()
      calls = calls + 1
      return 1
    end

    for _, name in ipairs(names) do
      package.loaded[name] = nil
      require(name)
    end

    vim.api.nvim_create_autocmd = create_autocmd
    vim.api.nvim_create_augroup = create_augroup
    assert.are.equal(0, calls)
  end)

  busted.it("registers each lifecycle hook once through setup", function()
    local groups = {
      ["harness.preview"] = "SysinitPreview",
      ["utils.gitrepo"] = "gitrepo_cache",
      ["utils.markdown_preview"] = "SysinitGoGrip",
    }
    for _, name in ipairs(names) do
      package.loaded[name] = nil
      local module = require(name)
      module.setup()
      module.setup()
      assert.are.equal(1, #vim.api.nvim_get_autocmds({ group = groups[name] }))
    end
  end)
end)
