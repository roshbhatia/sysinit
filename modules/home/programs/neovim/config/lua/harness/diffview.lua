local M = {}

local command_names = { "pick", "all", "scope", "base", "refresh" }
local configured = false

local commands = {
  pick = function()
    require("harness.review").pick()
  end,
  all = function()
    require("harness.review").all()
  end,
  scope = function()
    require("harness.scopes").open()
  end,
  base = function()
    require("harness.review").set_base()
  end,
  refresh = function()
    require("harness.review").refresh()
  end,
}

---@param actions table
---@return function
local function close_here(actions)
  -- A review can span several repository tabs. Close that review as one unit,
  -- while a standalone file-history tab keeps Diffview's local close action.
  return function()
    local ok, review = pcall(require, "harness.review")
    if ok and review.here() then
      return review.close()
    end
    actions.close()
  end
end

---@param actions table
---@param conflicts "none"|"hunk"|"file"|"both"
---@return table[]
function M.keymaps(actions, conflicts)
  local maps = {
    { "n", "q", close_here(actions), { desc = "Close the review" } },
    { "n", "<leader>e", false },
    { "n", "<leader>b", false },
    { "n", "<localleader>de", actions.focus_files, { desc = "Focus the file panel" } },
    { "n", "<localleader>db", actions.toggle_files, { desc = "Toggle the file panel" } },
  }
  local names = { o = "ours", t = "theirs", b = "base", a = "all" }
  for _, key in ipairs({ "o", "t", "b", "a" }) do
    local name = names[key]
    if conflicts == "hunk" or conflicts == "both" then
      maps[#maps + 1] = { "n", "<leader>c" .. key, false }
      maps[#maps + 1] = {
        "n",
        "<localleader>dc" .. key,
        actions.conflict_choose(name),
        { desc = "Take " .. name },
      }
    end
    if conflicts == "file" or conflicts == "both" then
      maps[#maps + 1] = { "n", "<leader>c" .. key:upper(), false }
      maps[#maps + 1] = {
        "n",
        "<localleader>dc" .. key:upper(),
        actions.conflict_choose_all(name),
        { desc = "Take " .. name .. " for the whole file" },
      }
    end
  end
  return maps
end

---@return string[]
function M.complete()
  return vim.deepcopy(command_names)
end

---@param name string
function M.run(name)
  local selected = name ~= "" and name or "pick"
  local command = commands[selected]
  if command == nil then
    vim.notify("Review: no such subcommand " .. name, vim.log.levels.WARN)
    return
  end
  command()
end

function M.setup()
  if configured then
    return
  end
  configured = true

  local actions = require("diffview.actions")
  local layout = require("harness.diff_layout")

  require("diffview").setup({
    enhanced_diff_hl = true,
    show_help_hints = false,
    view = {
      merge_tool = { layout = "diff3_mixed" },
    },
    file_panel = {
      listing_style = "tree",
      win_config = layout.file_panel,
    },
    file_history_panel = {
      win_config = layout.file_history_panel,
    },
    hooks = {
      diff_buf_read = function(bufnr)
        pcall(function()
          require("harness.notes").place(bufnr)
        end)
      end,
    },
    keymaps = {
      view = M.keymaps(actions, "both"),
      file_panel = M.keymaps(actions, "file"),
      file_history_panel = M.keymaps(actions, "none"),
    },
  })

  vim.api.nvim_create_user_command("Review", function(cmd)
    M.run(cmd.args)
  end, {
    nargs = "?",
    complete = M.complete,
    desc = "Review: pick, all, scope, base, refresh",
    force = true,
  })

  require("harness.notes_list").setup()
  layout.setup()
end

return M
