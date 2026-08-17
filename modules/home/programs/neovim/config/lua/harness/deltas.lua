local M = {}

-- Every agent write lands as one commit in a shadow git repository, whose subject is
-- the prompt that asked for it. Reading it back is plain git, so this module only
-- shells out; nothing here owns the history.

---@type table
local store = { asked = false, dir = nil, tree = nil }

---@param flag string
---@return string|nil
local function ask(flag)
  local out = vim.fn.system({ "agent-edit-event", flag })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  local value = vim.trim(out)
  if value == "" then
    return nil
  end
  return value
end

---@return string|nil dir
---@return string|nil tree
local function resolve()
  if not store.asked then
    store.asked = true
    if vim.fn.executable("agent-edit-event") == 1 then
      store.dir = ask("--print-delta")
      store.tree = ask("--print-workspace")
    end
  end
  if store.dir and store.tree and vim.uv.fs_stat(store.dir .. "/HEAD") then
    return store.dir, store.tree
  end
  return nil, nil
end

---@param args string[]
---@return string[]|nil
local function git(args)
  local dir, tree = resolve()
  if not dir then
    return nil
  end
  local cmd = { "git", "--git-dir=" .. dir, "--work-tree=" .. tree }
  vim.list_extend(cmd, args)
  local out = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return out
end

---@return string|nil
local function relative()
  local _, tree = resolve()
  if not tree then
    return nil
  end
  local file = vim.fs.normalize(vim.api.nvim_buf_get_name(0))
  local root = vim.fs.normalize(tree) .. "/"
  if file:sub(1, #root) ~= root then
    return nil
  end
  return file:sub(#root + 1)
end

local function missing()
  vim.notify("Deltas: no agent write is recorded here yet", vim.log.levels.INFO)
end

---@param sha string
local function open_message(sha)
  local body = git({ "show", "--no-patch", "--format=%B", sha })
  if not body or #body == 0 then
    missing()
    return
  end
  while #body > 0 and body[#body] == "" do
    table.remove(body)
  end
  table.insert(body, "")
  table.insert(body, "delta " .. sha:sub(1, 12))

  local shown = pcall(vim.lsp.util.open_floating_preview, body, "gitcommit", {
    border = "rounded",
    focusable = true,
    max_width = 84,
  })
  if not shown then
    vim.notify(table.concat(body, "\n"))
  end
end

---@param sha string
local function open_patch(sha)
  local patch = git({ "show", "--format=%B", sha })
  if not patch or #patch == 0 then
    missing()
    return
  end
  vim.cmd("tabnew")
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, patch)
  vim.bo[bufnr].filetype = "git"
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].buftype = "nofile"
  vim.api.nvim_buf_set_name(bufnr, "delta://" .. sha:sub(1, 12))
end

-- Which prompt wrote the line under the cursor.
function M.why()
  local file = relative()
  if not file then
    missing()
    return
  end
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local blame = git({ "blame", "--porcelain", "-L", line .. "," .. line, "--", file })
  if not blame or #blame == 0 then
    missing()
    return
  end
  local sha = blame[1]:match("^(%x+)")
  if not sha then
    missing()
    return
  end
  open_message(sha)
end

---@param opts table|nil
function M.pick(opts)
  opts = opts or {}
  local args = { "log", "--no-merges", "--max-count=200", "--format=%H\31%ar\31%s" }
  if opts.file then
    local file = relative()
    if not file then
      missing()
      return
    end
    vim.list_extend(args, { "--follow", "--", file })
  end

  local lines = git(args)
  if not lines or #lines == 0 then
    missing()
    return
  end

  local items = {}
  for index, line in ipairs(lines) do
    local sha, when, subject = line:match("^(%x+)\31([^\31]*)\31(.*)$")
    if sha then
      items[#items + 1] = {
        idx = index,
        score = 0,
        text = when .. " " .. subject,
        sha = sha,
        when = when,
        subject = subject,
      }
    end
  end

  Snacks.picker.pick({
    source = "harness_deltas",
    items = items,
    title = opts.file and "Deltas in this file" or "Deltas",
    format = function(item)
      return {
        { item.when .. "  ", "SnacksPickerLabel" },
        { item.subject, "SnacksPickerComment" },
      }
    end,
    preview = function(ctx)
      -- pcall keeps a snacks preview API change from breaking the whole picker.
      pcall(function()
        local patch = git({ "show", "--format=%B", ctx.item.sha }) or { "this delta is gone" }
        ctx.preview:reset()
        ctx.preview:set_lines(patch)
        ctx.preview:highlight({ ft = "git" })
      end)
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        open_patch(item.sha)
      end
    end,
  })
end

---@return table
function M.status()
  local dir, tree = resolve()
  local count = 0
  if dir then
    local out = git({ "rev-list", "--count", "HEAD" })
    count = tonumber(out and out[1]) or 0
  end
  return { dir = dir, tree = tree, deltas = count }
end

return M
