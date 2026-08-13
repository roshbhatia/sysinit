-- The commit history behind a review. diffview shows one repository's log in its own
-- panel; this exists for the other question, which is what happened across the workspace,
-- in the order it happened, when eighteen repositories moved together.
local M = {}

-- Deep enough to reach last week, short enough that the picker opens at once.
local PER_REPO = 40

-- git's empty tree: the only left side a repository with no commit before the chosen
-- moment can have.
local EMPTY_TREE = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"

local FORMAT = "%H%x1f%h%x1f%ct%x1f%an%x1f%s"

--- The short name a reader knows a repository by.
---@param root string
---@return string
local function name(root)
  return vim.fn.fnamemodify(root, ":t")
end

--- How long ago, in the units a reader thinks in.
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

--- Every repository's recent commits in one list, newest first. Interleaved by commit
--- time rather than grouped by repository, because a day's work crosses repositories and
--- reading it repository by repository loses the order it happened in.
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

--- The last commit in each repository at or before `stamp`, which is what "since this
--- commit" means in every repository other than the one the commit came from.
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
      -- No commit that old means every commit in this repository is inside the window,
      -- so the left side is the empty tree rather than a commit that does not exist.
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

--- Open a review of everything in `roots` since `commit`, using the commit itself in the
--- repository it came from and the same moment in the others.
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

--- The commits of these repositories, in a picker. Enter reads one commit; `<C-o>` takes
--- the commit as a starting point and reviews everything since.
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

--- The repositories a history should cover: the review's when one is open, the
--- workspace's otherwise.
---@param cb fun(roots: string[])
local function scope(cb)
  local roots = require("harness.review").roots()
  if #roots > 0 then
    return cb(roots)
  end
  require("utils.gitrepo").workspace_roots(cb)
end

--- Repository history. One repository answers for itself; several ask which, with the
--- whole workspace as the first answer.
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
