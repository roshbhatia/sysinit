-- codediff.lua
-- Enhanced codediff.nvim configuration with branch history navigation via quickfix

-- Create a global namespace for our codediff extensions
-- This ensures the module is accessible from lazy.nvim keymaps
_G.CodeDiffExtensions = _G.CodeDiffExtensions or {}
local M = _G.CodeDiffExtensions

-- Get the default branch (main or master)
function M.get_default_branch()
  local result = vim.fn.system("git rev-parse --verify main 2>/dev/null")
  if vim.v.shell_error == 0 then
    return "main"
  end
  result = vim.fn.system("git rev-parse --verify master 2>/dev/null")
  if vim.v.shell_error == 0 then
    return "master"
  end
  return nil
end

-- Get merge-base between current branch and default branch
function M.get_merge_base()
  local default_branch = M.get_default_branch()
  if not default_branch then
    return nil
  end
  local result = vim.fn.systemlist("git merge-base HEAD " .. default_branch .. " 2>/dev/null")
  if vim.v.shell_error ~= 0 or #result == 0 then
    return nil
  end
  return result[1]
end

-- Get current branch name
function M.get_current_branch()
  local result = vim.fn.systemlist("git branch --show-current 2>/dev/null")
  if vim.v.shell_error ~= 0 or #result == 0 then
    return "HEAD"
  end
  return result[1]
end

-- Check if we're on the default branch
function M.is_on_default_branch()
  local current = M.get_current_branch()
  local default_branch = M.get_default_branch()
  return current == default_branch
end

-- Get commits since merge-base (or last N commits if on default branch)
-- Returns table of { hash, date, author, message }, and a description string
function M.get_branch_commits()
  local current_branch = M.get_current_branch()
  local default_branch = M.get_default_branch()
  local cmd
  local description

  -- If on default branch, just show last 50 commits
  if current_branch == default_branch then
    cmd = "git log --format='%h|%ad|%an|%s' --date=short -50 2>/dev/null"
    description = "last 50"
  else
    local merge_base = M.get_merge_base()
    if merge_base then
      -- Check if there are any commits between merge-base and HEAD
      local count_result = vim.fn.systemlist(string.format("git rev-list --count %s..HEAD 2>/dev/null", merge_base))
      local count = tonumber(count_result[1] or "0") or 0

      if count > 0 then
        cmd = string.format("git log --format='%%h|%%ad|%%an|%%s' --date=short %s..HEAD 2>/dev/null", merge_base)
        description = string.format("%d since %s", count, default_branch or "base")
      else
        -- No commits since merge-base, show last 50
        cmd = "git log --format='%h|%ad|%an|%s' --date=short -50 2>/dev/null"
        description = "last 50"
      end
    else
      -- No merge-base found, show last 50
      cmd = "git log --format='%h|%ad|%an|%s' --date=short -50 2>/dev/null"
      description = "last 50"
    end
  end

  local result = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    return {}, description
  end

  local commits = {}
  for _, line in ipairs(result) do
    local hash, date, author, message = line:match("^([^|]+)|([^|]+)|([^|]+)|(.*)$")
    if hash then
      table.insert(commits, {
        hash = hash,
        date = date,
        author = author,
        message = message,
      })
    end
  end
  return commits, description
end

-- Get commits that modified a specific file
-- Returns table of { hash, date, author, message }
function M.get_file_commits(filepath)
  if not filepath or filepath == "" then
    filepath = vim.fn.expand("%:p")
  end

  -- Get relative path from git root
  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel 2>/dev/null")[1]
  if vim.v.shell_error ~= 0 or not git_root then
    return {}
  end

  local rel_path = filepath
  if filepath:sub(1, #git_root) == git_root then
    rel_path = filepath:sub(#git_root + 2) -- +2 to skip the trailing slash
  end

  local cmd = string.format("git log --format='%%h|%%ad|%%an|%%s' --date=short --follow -- '%s' 2>/dev/null", rel_path)

  local result = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    return {}
  end

  local commits = {}
  for _, line in ipairs(result) do
    local hash, date, author, message = line:match("^([^|]+)|([^|]+)|([^|]+)|(.*)$")
    if hash then
      table.insert(commits, {
        hash = hash,
        date = date,
        author = author,
        message = message,
      })
    end
  end
  return commits
end

-- Open CodeDiff for the commit under cursor in quickfix
function M.open_codediff_for_qf_entry()
  local qf_list = vim.fn.getqflist()
  local idx = vim.fn.line(".")
  if idx > #qf_list or idx < 1 then
    return
  end

  local entry = qf_list[idx]
  -- The commit hash is stored in the filename field
  local commit_hash = entry.filename

  if commit_hash and commit_hash ~= "" then
    -- Close quickfix temporarily for cleaner view
    vim.cmd("cclose")
    -- Open CodeDiff history for this commit (shows commit vs its parent)
    vim.cmd("CodeDiff history " .. commit_hash)
  end
end

-- State for commit range selection
M.range_selection = M.range_selection or {
  first_commit = nil,
  qf_title = nil,
}

-- Mark first commit for range comparison
function M.mark_commit_for_range()
  local qf_list = vim.fn.getqflist()
  local idx = vim.fn.line(".")
  if idx > #qf_list or idx < 1 then
    return
  end

  local entry = qf_list[idx]
  local commit_hash = entry.filename

  if commit_hash and commit_hash ~= "" then
    M.range_selection.first_commit = commit_hash
    M.range_selection.qf_title = vim.fn.getqflist({ title = 1 }).title
    vim.notify(
      string.format("Marked commit %s. Navigate to second commit and press <CR> to compare.", commit_hash),
      vim.log.levels.INFO
    )
  end
end

-- Open CodeDiff comparing two commits (for range selection mode)
function M.open_codediff_range()
  local qf_list = vim.fn.getqflist()
  local idx = vim.fn.line(".")
  if idx > #qf_list or idx < 1 then
    return
  end

  local entry = qf_list[idx]
  local second_commit = entry.filename

  if not M.range_selection.first_commit then
    -- No first commit marked, just show single commit diff
    M.open_codediff_for_qf_entry()
    return
  end

  local first_commit = M.range_selection.first_commit

  -- Clear selection state
  M.range_selection.first_commit = nil
  M.range_selection.qf_title = nil

  if second_commit and second_commit ~= "" then
    vim.cmd("cclose")
    -- CodeDiff supports two-revision comparison
    vim.cmd(string.format("CodeDiff %s %s", first_commit, second_commit))
  end
end

-- Check if current quickfix title is one of ours
function M.is_codediff_qf()
  local qf_title = vim.fn.getqflist({ title = 1 }).title or ""
  local is_branch_commits = qf_title:match("^Branch Commits:")
  local is_file_history = qf_title:match("^File History:")
  local is_commit_range = qf_title:match("^Commit Range:")
  return is_branch_commits or is_file_history or is_commit_range, qf_title:match("^Commit Range:")
end

-- Handle <CR> in quickfix - intercepts and checks if it's our list
function M.handle_qf_enter()
  local is_ours, is_range = M.is_codediff_qf()
  if not is_ours then
    -- Not our quickfix list, use standard quickfix behavior
    -- Get current line index and jump to that entry
    local idx = vim.fn.line(".")
    vim.cmd("cclose")
    vim.cmd("cc " .. idx)
    return
  end

  -- It's our quickfix list
  if is_range and M.range_selection.first_commit then
    M.open_codediff_range()
  else
    M.open_codediff_for_qf_entry()
  end
end

-- Handle 'm' in quickfix for marking commits
function M.handle_qf_mark()
  local is_ours = M.is_codediff_qf()
  if not is_ours then
    -- Not our list, pass through default 'm' behavior
    vim.cmd("normal! m")
    return
  end
  M.mark_commit_for_range()
end

-- Setup keymaps for quickfix buffer (called on FileType qf)
function M.setup_qf_keymaps()
  local bufnr = vim.api.nvim_get_current_buf()

  -- Use vim.keymap.set with buffer option - this sets our mapping
  -- We always set the mapping, but our handler checks if it's our qf list
  vim.keymap.set("n", "<CR>", function()
    M.handle_qf_enter()
  end, {
    buffer = bufnr,
    desc = "CodeDiff: Open commit or default qf action",
    noremap = true,
    silent = true,
  })

  vim.keymap.set("n", "m", function()
    M.handle_qf_mark()
  end, {
    buffer = bufnr,
    desc = "CodeDiff: Mark commit for range",
    noremap = true,
    silent = true,
  })
end

-- Populate quickfix with branch commits
function M.populate_branch_commits_qf()
  local commits, description = M.get_branch_commits()
  if #commits == 0 then
    vim.notify("No commits found", vim.log.levels.WARN)
    return
  end

  local branch = M.get_current_branch()

  local qf_items = {}
  for _, commit in ipairs(commits) do
    table.insert(qf_items, {
      text = string.format("%s %s %-20s %s", commit.hash, commit.date, commit.author:sub(1, 20), commit.message),
      -- Store hash in filename field for easy retrieval
      filename = commit.hash,
    })
  end

  vim.fn.setqflist({}, "r", {
    title = string.format("Branch Commits: %s (%s)", branch, description),
    items = qf_items,
  })

  vim.cmd("copen")
  -- Keymaps are set by after/ftplugin/qf.lua automatically

  vim.notify(string.format("Loaded %d commits. Press <CR> to view commit diff.", #commits), vim.log.levels.INFO)
end

-- Populate quickfix with file history commits
function M.populate_file_commits_qf(filepath)
  filepath = filepath or vim.fn.expand("%:p")
  local commits = M.get_file_commits(filepath)

  if #commits == 0 then
    vim.notify("No commits found for this file", vim.log.levels.WARN)
    return
  end

  local filename = vim.fn.fnamemodify(filepath, ":t")

  local qf_items = {}
  for _, commit in ipairs(commits) do
    table.insert(qf_items, {
      text = string.format("%s %s %-20s %s", commit.hash, commit.date, commit.author:sub(1, 20), commit.message),
      -- Store hash in filename field for easy retrieval
      filename = commit.hash,
    })
  end

  vim.fn.setqflist({}, "r", {
    title = string.format("File History: %s (%d commits)", filename, #commits),
    items = qf_items,
  })

  vim.cmd("copen")
  -- Keymaps are set by after/ftplugin/qf.lua automatically

  vim.notify(
    string.format("Loaded %d commits for %s. Press <CR> to view diff.", #commits, filename),
    vim.log.levels.INFO
  )
end

-- Populate quickfix for commit range selection
function M.populate_commit_range_qf()
  local commits, description = M.get_branch_commits()
  if #commits == 0 then
    vim.notify("No commits found", vim.log.levels.WARN)
    return
  end

  local branch = M.get_current_branch()

  local qf_items = {}
  for _, commit in ipairs(commits) do
    table.insert(qf_items, {
      text = string.format("%s %s %-20s %s", commit.hash, commit.date, commit.author:sub(1, 20), commit.message),
      filename = commit.hash,
    })
  end

  vim.fn.setqflist({}, "r", {
    title = string.format("Commit Range: %s (%s) - Press 'm' to mark, <CR> to compare", branch, description),
    items = qf_items,
  })

  vim.cmd("copen")
  -- Keymaps are set by after/ftplugin/qf.lua automatically

  vim.notify("Press 'm' to mark first commit, then <CR> on second commit to compare range.", vim.log.levels.INFO)
end

-- User commands
local function setup_commands()
  -- :DiffBranchCommits - List branch commits in quickfix
  vim.api.nvim_create_user_command("DiffBranchCommits", function()
    M.populate_branch_commits_qf()
  end, { desc = "List branch commits in quickfix for CodeDiff navigation" })

  -- :DiffFileHistory - List commits for current file in quickfix
  vim.api.nvim_create_user_command("DiffFileHistory", function(opts)
    local filepath = opts.args ~= "" and opts.args or nil
    M.populate_file_commits_qf(filepath)
  end, { desc = "List file history commits in quickfix", nargs = "?" })

  -- :DiffCommitRange [from] [to] - Compare two commits
  vim.api.nvim_create_user_command("DiffCommitRange", function(opts)
    local args = vim.split(opts.args, " ", { trimempty = true })
    if #args >= 2 then
      -- Direct comparison with provided commits
      vim.cmd(string.format("CodeDiff %s %s", args[1], args[2]))
    elseif #args == 1 then
      -- Single commit provided, compare with HEAD
      vim.cmd(string.format("CodeDiff %s HEAD", args[1]))
    else
      -- No args: open branch commits quickfix for selection
      M.populate_commit_range_qf()
    end
  end, { desc = "Compare two commits with CodeDiff", nargs = "*" })
end

-- Initialize the module (called from config)
function M.setup()
  setup_commands()
  -- Keymaps are now handled by after/ftplugin/qf.lua
end

-- Plugin specification
return {
  {
    "esmuellert/codediff.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    cmd = { "CodeDiff", "DiffBranchCommits", "DiffFileHistory", "DiffCommitRange" },
    config = function()
      require("codediff").setup({
        explorer = {
          position = "bottom",
          view_mode = "tree",
        },
        keymaps = {
          view = {
            toggle_explorer = "<localleader>e",
          },
          explorer = {
            toggle_view_mode = "t",
          },
          conflict = {
            accept_incoming = "<localleader>i",
            accept_current = "<localleader>c",
            accept_both = "<localleader>b",
            discard = "<localleader>x",
          },
        },
      })

      -- Setup our custom commands and quickfix integration
      M.setup()
    end,
    keys = {
      -- Existing keymaps
      {
        "<leader>dd",
        function()
          vim.cmd("CodeDiff HEAD")
        end,
        desc = "HEAD",
      },
      {
        "<leader>dm",
        function()
          vim.cmd("CodeDiff main")
        end,
        desc = "Main",
      },
      -- New keymaps for branch history navigation
      {
        "<leader>db",
        function()
          _G.CodeDiffExtensions.populate_branch_commits_qf()
        end,
        desc = "Branch commits",
      },
      {
        "<leader>df",
        function()
          _G.CodeDiffExtensions.populate_file_commits_qf()
        end,
        desc = "File history",
      },
      {
        "<leader>dr",
        function()
          _G.CodeDiffExtensions.populate_commit_range_qf()
        end,
        desc = "Commit range",
      },
    },
  },
}
