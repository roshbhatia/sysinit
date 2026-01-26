-- codediff.lua
-- Enhanced codediff.nvim configuration with branch history navigation via quickfix

-- Git helper functions for branch commit navigation
local M = {}

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

-- Get commits since merge-base (or last N commits as fallback)
-- Returns table of { hash, date, author, message }
function M.get_branch_commits()
  local merge_base = M.get_merge_base()
  local cmd
  if merge_base then
    cmd = string.format("git log --format='%%h|%%ad|%%an|%%s' --date=short %s..HEAD 2>/dev/null", merge_base)
  else
    -- Fallback: show last 50 commits
    cmd = "git log --format='%h|%ad|%an|%s' --date=short -50 2>/dev/null"
  end

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

-- Populate quickfix with branch commits
function M.populate_branch_commits_qf()
  local commits = M.get_branch_commits()
  if #commits == 0 then
    vim.notify("No commits found in current branch", vim.log.levels.WARN)
    return
  end

  local branch = M.get_current_branch()
  local default_branch = M.get_default_branch() or "unknown"

  local qf_items = {}
  for _, commit in ipairs(commits) do
    table.insert(qf_items, {
      text = string.format("%s %s %-20s %s", commit.hash, commit.date, commit.author:sub(1, 20), commit.message),
      -- Store hash in filename field for easy retrieval
      filename = commit.hash,
    })
  end

  vim.fn.setqflist({}, "r", {
    title = string.format("Branch Commits: %s (%d since %s)", branch, #commits, default_branch),
    items = qf_items,
  })

  vim.cmd("copen")
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
  vim.notify(
    string.format("Loaded %d commits for %s. Press <CR> to view diff.", #commits, filename),
    vim.log.levels.INFO
  )
end

-- Open CodeDiff for the commit under cursor in quickfix
function M.open_codediff_for_qf_entry()
  local qf_list = vim.fn.getqflist()
  local idx = vim.fn.line(".")
  if idx > #qf_list then
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
M.range_selection = {
  first_commit = nil,
  qf_title = nil,
}

-- Mark first commit for range comparison
function M.mark_commit_for_range()
  local qf_list = vim.fn.getqflist()
  local idx = vim.fn.line(".")
  if idx > #qf_list then
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
  if idx > #qf_list then
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

-- Setup quickfix autocmd for our custom quickfix lists
local function setup_qf_autocmd()
  vim.api.nvim_create_augroup("CodeDiffQF", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = "CodeDiffQF",
    pattern = "qf",
    callback = function()
      -- Check if this is one of our quickfix lists
      local qf_title = vim.fn.getqflist({ title = 1 }).title or ""

      local is_branch_commits = qf_title:match("^Branch Commits:")
      local is_file_history = qf_title:match("^File History:")
      local is_commit_range = qf_title:match("^Commit Range:")

      if is_branch_commits or is_file_history then
        -- Map <CR> to open CodeDiff for the selected commit
        vim.keymap.set("n", "<CR>", function()
          M.open_codediff_for_qf_entry()
        end, { buffer = true, desc = "Open CodeDiff for commit" })

        -- Map 'm' to mark commit for range comparison
        vim.keymap.set("n", "m", function()
          M.mark_commit_for_range()
        end, { buffer = true, desc = "Mark commit for range comparison" })
      elseif is_commit_range then
        -- In range selection mode, <CR> completes the selection
        vim.keymap.set("n", "<CR>", function()
          M.open_codediff_range()
        end, { buffer = true, desc = "Compare with marked commit" })

        vim.keymap.set("n", "m", function()
          M.mark_commit_for_range()
        end, { buffer = true, desc = "Mark commit for range comparison" })
      end
    end,
  })
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
      -- User can mark first commit with 'm', then navigate and press <CR> to compare
      local commits = M.get_branch_commits()
      if #commits == 0 then
        vim.notify("No commits found in current branch", vim.log.levels.WARN)
        return
      end

      local branch = M.get_current_branch()
      local default_branch = M.get_default_branch() or "unknown"

      local qf_items = {}
      for _, commit in ipairs(commits) do
        table.insert(qf_items, {
          text = string.format("%s %s %-20s %s", commit.hash, commit.date, commit.author:sub(1, 20), commit.message),
          filename = commit.hash,
        })
      end

      vim.fn.setqflist({}, "r", {
        title = string.format(
          "Commit Range: %s (%d since %s) - Press 'm' to mark, <CR> to compare",
          branch,
          #commits,
          default_branch
        ),
        items = qf_items,
      })

      vim.cmd("copen")
      vim.notify("Press 'm' to mark first commit, then <CR> on second commit to compare range.", vim.log.levels.INFO)
    end
  end, { desc = "Compare two commits with CodeDiff", nargs = "*" })
end

-- Initialize the module (called from config)
function M.setup()
  setup_qf_autocmd()
  setup_commands()
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
          M.populate_branch_commits_qf()
        end,
        desc = "Branch commits",
      },
      {
        "<leader>df",
        function()
          M.populate_file_commits_qf()
        end,
        desc = "File history",
      },
      {
        "<leader>dr",
        function()
          vim.cmd("DiffCommitRange")
        end,
        desc = "Commit range",
      },
    },
  },
}
