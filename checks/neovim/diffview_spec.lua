local busted = require("plenary.busted")
local assert = require("luassert")

local config_root = assert(vim.env.SYSINIT_NVIM_CONFIG)

local function map_for(maps, lhs)
  for _, map in ipairs(maps) do
    if map[2] == lhs then
      return map
    end
  end
end

busted.describe("Diffview integration", function()
  local loaded

  busted.before_each(function()
    loaded = {}
    for _, name in ipairs({
      "diffview",
      "diffview.actions",
      "harness.diff_layout",
      "harness.diffview",
      "harness.notes_list",
      "harness.review",
      "harness.scopes",
    }) do
      loaded[name] = package.loaded[name]
    end
  end)

  busted.after_each(function()
    pcall(vim.api.nvim_del_user_command, "Review")
    for name, module in pairs(loaded) do
      package.loaded[name] = module
    end
  end)

  busted.it("keeps the lazy spec declarative", function()
    local calls = 0
    package.loaded["harness.diffview"] = {
      setup = function()
        calls = calls + 1
      end,
    }
    local specs = dofile(config_root .. "/lua/plugins/diffview.lua")
    specs[1].config()
    assert.are.equal(1, calls)
  end)

  busted.it("builds conflict maps by surface", function()
    local actions = {
      close = function() end,
      focus_files = function() end,
      toggle_files = function() end,
      conflict_choose = function(name)
        return "hunk:" .. name
      end,
      conflict_choose_all = function(name)
        return "file:" .. name
      end,
    }
    package.loaded["harness.diffview"] = nil
    local integration = require("harness.diffview")
    local view = integration.keymaps(actions, "both")
    local files = integration.keymaps(actions, "file")
    local history = integration.keymaps(actions, "none")

    assert.are.equal("hunk:ours", map_for(view, "<localleader>dco")[3])
    assert.are.equal("file:ours", map_for(view, "<localleader>dcO")[3])
    assert.is_nil(map_for(files, "<localleader>dco"))
    assert.are.equal("file:ours", map_for(files, "<localleader>dcO")[3])
    assert.is_nil(map_for(history, "<localleader>dco"))
    assert.is_nil(map_for(history, "<localleader>dcO"))
  end)

  busted.it("registers setup and commands idempotently", function()
    local diffview_options
    local layout_calls = 0
    local note_calls = 0
    local refresh_calls = 0
    local actions = {
      close = function() end,
      focus_files = function() end,
      toggle_files = function() end,
      conflict_choose = function()
        return function() end
      end,
      conflict_choose_all = function()
        return function() end
      end,
    }

    package.loaded["diffview.actions"] = actions
    package.loaded["diffview"] = {
      setup = function(options)
        diffview_options = options
      end,
    }
    package.loaded["harness.diff_layout"] = {
      file_panel = function() end,
      file_history_panel = function() end,
      setup = function()
        layout_calls = layout_calls + 1
      end,
    }
    package.loaded["harness.notes_list"] = {
      setup = function()
        note_calls = note_calls + 1
      end,
    }
    package.loaded["harness.review"] = {
      refresh = function()
        refresh_calls = refresh_calls + 1
      end,
    }
    package.loaded["harness.diffview"] = nil

    local integration = require("harness.diffview")
    integration.setup()
    integration.setup()
    vim.cmd("Review refresh")

    assert.are.same({ "pick", "all", "scope", "base", "refresh" }, integration.complete())
    assert.are.equal("tree", diffview_options.file_panel.listing_style)
    assert.are.equal(1, layout_calls)
    assert.are.equal(1, note_calls)
    assert.are.equal(1, refresh_calls)
  end)

  busted.it("moves the file panel below narrow diffs", function()
    local columns = vim.o.columns
    local lines = vim.o.lines
    package.loaded["harness.diff_layout"] = nil
    local layout = require("harness.diff_layout")

    vim.o.columns = 200
    vim.o.lines = 60
    assert.are.same({ type = "split", position = "left", width = 40 }, layout.file_panel())
    vim.o.columns = 120
    assert.are.same({ type = "split", position = "bottom", height = 14 }, layout.file_panel())

    vim.o.columns = columns
    vim.o.lines = lines
  end)
end)
