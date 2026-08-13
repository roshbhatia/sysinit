-- A repository's commits, or one file's, as a quickfix list whose rows open a review of
-- that commit. This is the list the review reads a previous revision out of.
local M = {}

-- How far back a list reaches. A reader looking further reaches for a rev range.
local depth = 200

-- The id of the list this module pushed, so `<CR>` on one of its rows opens a revision
-- rather than a file, and a row of any other list is left to whoever owns it.
local id = nil

-- `%H`, `%h`, the parents, the relative date, the author and the subject.
local format = "%H%x00%h%x00%P%x00%ar%x00%an%x00%s"

--- One commit per line, each line split on NUL. A subject holds no newline, because `%s`
--- is a commit message's first line.
---@param out string
---@return table[]
local function parse(out)
  local commits = {}
  for line in out:gmatch("[^\n]+") do
    local part = {}
    local at = 1
    while true do
      local stop = line:find("\0", at, true)
      if stop == nil then
        part[#part + 1] = line:sub(at)
        break
      end
      part[#part + 1] = line:sub(at, stop - 1)
      at = stop + 1
    end
    if #part >= 6 then
      commits[#commits + 1] = {
        sha = part[1],
        short = part[2],
        -- The first parent. A root commit has none, and the diff falls back to the empty
        -- tree, which is the only left side it has.
        parent = vim.split(part[3], " ")[1] ~= "" and vim.split(part[3], " ")[1] or nil,
        when = part[4],
        who = part[5],
        subject = part[6],
        revision = true,
      }
    end
  end
  return commits
end

--- Pad to a width. Not `%-<n>s`, because `string.format` takes at most two digits of
--- width, and an author name or a date phrase is not bounded by two digits.
---@param text string
---@param width integer
---@return string
local function pad(text, width)
  if #text >= width then
    return text
  end
  return text .. string.rep(" ", width - #text)
end

--- The quickfix items for a set of commits, aligned so the subjects start in one column.
---@param root string
---@param commits table[]
---@return table[]
local function items(root, commits)
  local width = { when = 1, who = 1 }
  for _, commit in ipairs(commits) do
    width.when = math.max(width.when, #commit.when)
    width.who = math.max(width.who, #commit.who)
  end
  local built = {}
  for _, commit in ipairs(commits) do
    built[#built + 1] = {
      -- The repository root, because a row is a commit rather than a place in a file, and
      -- quickfix wants a file for every row it will let a reader land on.
      filename = root,
      lnum = 1,
      col = 1,
      text = table.concat({
        commit.short,
        pad(commit.when, width.when),
        pad(commit.who, width.who),
        commit.subject,
      }, "  "),
      user_data = vim.tbl_extend("force", commit, { root = root }),
    }
  end
  return built
end

--- A per-list renderer, because `nvim-pqf` sets the global one and a row of ours comes
--- back from it with the columns gone.
---@param info table
---@return string[]
local function render(info)
  local got = vim.fn.getqflist({ id = info.id, items = 1 }).items
  local lines = {}
  for index = info.start_idx, info.end_idx do
    lines[#lines + 1] = got[index] and got[index].text or ""
  end
  return lines
end

--- Push one history list and show it.
---@param root string
---@param relative string|nil one file's history, or the whole repository's
local function load(root, relative)
  local args = { "git", "-C", root, "log", "--max-count=" .. depth, "--format=" .. format }
  if relative then
    -- `--follow` so a rename does not end the history, which is the whole point of asking
    -- for one file's commits.
    vim.list_extend(args, { "--follow", "--", relative })
  end
  vim.system(args, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        vim.notify("History: " .. vim.split(res.stderr or "", "\n")[1], vim.log.levels.WARN)
        return
      end
      local commits = parse(res.stdout or "")
      if #commits == 0 then
        vim.notify("History: no commits for " .. (relative or vim.fn.fnamemodify(root, ":t")), vim.log.levels.INFO)
        return
      end
      local name = relative or vim.fn.fnamemodify(root, ":t")
      -- To the newest list first, because pushing one while an older list is current frees
      -- every list above it.
      pcall(vim.cmd, "cnewer 99")
      vim.fn.setqflist({}, " ", {
        title = "history: " .. name,
        items = items(root, commits),
        quickfixtextfunc = render,
      })
      id = vim.fn.getqflist({ id = 0 }).id
      vim.cmd("botright copen 12")
    end)
  end)
end

--- The commits of the repository a caller is in, asked for when the workspace holds
--- several, since a commit list spanning repositories is a fiction.
function M.repo()
  require("utils.gitrepo").resolve(function(root)
    load(root, nil)
  end, { ask = true })
end

--- The commits of the file in the current buffer.
function M.file()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" or vim.uv.fs_stat(path) == nil then
    vim.notify("History: this buffer is not a file", vim.log.levels.WARN)
    return
  end
  require("utils.gitrepo").resolve(function(root)
    -- Relative to the repository, which is how git names a path and is not what `:.`
    -- gives, since that is relative to the working directory.
    local relative = vim.startswith(path, root .. "/") and path:sub(#root + 2) or path
    load(root, relative)
  end)
end

--- Open the commit under the cursor as a review. False when the list is not this
--- module's, so the caller can fall back to whatever else claims `<CR>`.
---@return boolean handled
function M.activate()
  if id == nil or vim.fn.getqflist({ id = 0 }).id ~= id then
    return false
  end
  local at = vim.api.nvim_win_get_cursor(0)[1]
  local item = vim.fn.getqflist()[at]
  local commit = item and item.user_data
  if commit == nil or not commit.revision then
    return false
  end
  require("review").open_revision(commit.root, commit)
  return true
end

return M
