local M = {}

local PER_REPO = 40

local EMPTY_TREE = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"

local FORMAT = "%H%x1f%h%x1f%ct%x1f%an%x1f%s"

---@param root string
---@return string
local function name(root)
  return vim.fn.fnamemodify(root, ":t")
end

---@param stamp number
---@return string
local function ago(stamp)
  local seconds = os.time() - stamp
  if seconds < 3600 then
    return string.format("%dm", math.max(1, math.floor(seconds / 60)))
  end
  if seconds < 86400 then
    return string.format("%dh", math.floor(seconds / 3600))
  end
  if seconds < 86400 * 14 then
    return string.format("%dd", math.floor(seconds / 86400))
  end
  return os.date("%b %d", stamp)
end

---@param roots string[]
---@param cb fun(commits: table[])
local function log(roots, cb)
  local found, pending = {}, #roots
  if pending == 0 then
    return cb({})
  end
  for index, root in ipairs(roots) do
    vim.system(
      { "git", "-C", root, "log", "--max-count=" .. PER_REPO, "--format=" .. FORMAT },
      { text = true },
      function(res)
        local mine = {}
        if res.code == 0 then
          for line in (res.stdout or ""):gmatch("[^\n]+") do
            local sha, short, stamp, author, subject =
              line:match("^([^\31]*)\31([^\31]*)\31([^\31]*)\31([^\31]*)\31(.*)$")
            if sha and sha ~= "" then
              mine[#mine + 1] = {
                root = root,
                sha = sha,
                short = short,
                at = tonumber(stamp) or 0,
                author = author,
                subject = subject,
              }
            end
          end
        end
        found[index] = mine
        pending = pending - 1
        if pending == 0 then
          local flat = {}
          for at = 1, #roots do
            for _, commit in ipairs(found[at] or {}) do
              flat[#flat + 1] = commit
            end
          end
          table.sort(flat, function(a, b)
            return a.at > b.at
          end)
          vim.schedule(function()
            cb(flat)
          end)
        end
      end
    )
  end
end

---@param roots string[]
---@param stamp number
---@param cb fun(revs: table<string, string>)
local function revs_at(roots, stamp, cb)
  local revs, pending = {}, #roots
  if pending == 0 then
    return cb({})
  end
  local when = os.date("!%Y-%m-%dT%H:%M:%S", stamp) .. "Z"
  for _, root in ipairs(roots) do
    vim.system({ "git", "-C", root, "rev-list", "-1", "--before=" .. when, "HEAD" }, { text = true }, function(res)
      local sha = (res.stdout or ""):match("%x+")
      revs[root] = sha or EMPTY_TREE
      pending = pending - 1
      if pending == 0 then
        vim.schedule(function()
          cb(revs)
        end)
      end
    end)
  end
end

---@param roots string[]
---@param commit table
local function since(roots, commit)
  revs_at(roots, commit.at, function(revs)
    revs[commit.root] = commit.sha
    local review = require("harness.review")
    review.close()
    review.open(roots, revs)
    vim.notify(
      string.format("Review: %d repositories since %s %s", #roots, name(commit.root), commit.short),
      vim.log.levels.INFO
    )
  end)
end

---@param roots string[]
---@param title string
local function browse(roots, title)
  log(roots, function(commits)
    if #commits == 0 then
      vim.notify("History: no commits in " .. title, vim.log.levels.WARN)
      return
    end

    local items = {}
    for index, commit in ipairs(commits) do
      items[#items + 1] = {
        idx = index,
        score = 0,
        text = string.format("%s %s %s %s", name(commit.root), commit.short, commit.author, commit.subject),
        commit = commit,
      }
    end

    Snacks.picker.pick({
      source = "harness_history",
      title = title .. "  (enter: this commit, ctrl-o: everything since)",
      items = items,
      format = function(item)
        local commit = item.commit
        return {
          { string.format("%-12s ", name(commit.root)), "SnacksPickerLabel" },
          { commit.short .. " ", "SnacksPickerGitCommit" },
          { string.format("%-5s ", ago(commit.at)), "SnacksPickerComment" },
          { commit.subject, "SnacksPickerText" },
        }
      end,
      confirm = function(picker, item)
        picker:close()
        if item then
          require("harness.review").open_revision(item.commit.root, item.commit)
        end
      end,
      actions = {
        review_since = function(picker, item)
          picker:close()
          if item then
            since(roots, item.commit)
          end
        end,
      },
      win = {
        input = {
          keys = {
            ["<c-o>"] = { "review_since", mode = { "n", "i" } },
          },
        },
      },
    })
  end)
end

---@param cb fun(roots: string[])
local function scope(cb)
  local roots = require("harness.review").roots()
  if #roots > 0 then
    return cb(roots)
  end
  require("utils.gitrepo").workspace_roots(cb)
end

function M.open()
  scope(function(roots)
    if #roots == 0 then
      vim.notify("History: no git repository under " .. require("utils.gitrepo").workspace(), vim.log.levels.WARN)
      return
    end
    if #roots == 1 then
      return browse(roots, name(roots[1]))
    end

    local choices = { { label = string.format("All %d repositories, by time", #roots), roots = roots } }
    for _, root in ipairs(roots) do
      choices[#choices + 1] = { label = name(root), roots = { root } }
    end
    vim.ui.select(choices, {
      prompt = "History",
      format_item = function(choice)
        return choice.label
      end,
    }, function(choice)
      if choice then
        browse(choice.roots, choice.label)
      end
    end)
  end)
end

return M
