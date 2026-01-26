-- diffview.lua
-- Enhanced diffview.nvim configuration with branch history navigation via quickfix

_G.DiffviewExtensions = _G.DiffviewExtensions or {}
local M = _G.DiffviewExtensions

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

function M.get_current_branch()
  local result = vim.fn.systemlist("git branch --show-current 2>/dev/null")
  if vim.v.shell_error ~= 0 or #result == 0 then
    return "HEAD"
  end
  return result[1]
end

function M.get_branch_commits()
  local current_branch = M.get_current_branch()
  local default_branch = M.get_default_branch()
  local cmd
  local description

  if current_branch == default_branch then
    cmd = "git log --format='%h|%ad|%an|%s' --date=short -50 2>/dev/null"
    description = "last 50"
  else
    local merge_base = M.get_merge_base()
    if merge_base then
      local count_result = vim.fn.systemlist(string.format("git rev-list --count %s..HEAD 2>/dev/null", merge_base))
      local count = tonumber(count_result[1] or "0") or 0

      if count > 0 then
        cmd = string.format("git log --format='%%h|%%ad|%%an|%%s' --date=short %s..HEAD 2>/dev/null", merge_base)
        description = string.format("%d since %s", count, default_branch or "base")
      else
        cmd = "git log --format='%h|%ad|%an|%s' --date=short -50 2>/dev/null"
        description = "last 50"
      end
    else
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

function M.get_file_commits(filepath)
  if not filepath or filepath == "" then
    filepath = vim.fn.expand("%:p")
  end

  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel 2>/dev/null")[1]
  if vim.v.shell_error ~= 0 or not git_root then
    return {}
  end

  local rel_path = filepath
  if filepath:sub(1, #git_root) == git_root then
    rel_path = filepath:sub(#git_root + 2)
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

function M.open_diffview_for_qf_entry()
  local qf_list = vim.fn.getqflist()
  local idx = vim.fn.line(".")

  if idx > #qf_list or idx < 1 then
    return
  end

  local entry = qf_list[idx]
  local commit_hash = entry.user_data

  if commit_hash and commit_hash ~= "" then
    vim.cmd("cclose")
    vim.cmd("DiffviewOpen " .. commit_hash .. "^.." .. commit_hash)
  end
end

function M.open_file_history_for_qf_entry()
  local qf_list = vim.fn.getqflist()
  local qf_info = vim.fn.getqflist({ title = 1 })
  local idx = vim.fn.line(".")

  if idx > #qf_list or idx < 1 then
    return
  end

  local entry = qf_list[idx]
  local commit_hash = entry.user_data

  if not commit_hash or commit_hash == "" then
    return
  end

  local filename = qf_info.title:match("^File History: ([^%(]+)")
  if filename then
    filename = vim.trim(filename)
  else
    return
  end

  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel 2>/dev/null")[1]
  if vim.v.shell_error ~= 0 or not git_root then
    return
  end

  vim.cmd("cclose")
  vim.cmd(string.format("DiffviewOpen %s^..%s -- %s", commit_hash, commit_hash, filename))
end

M.range_selection = M.range_selection or {
  first_commit = nil,
  qf_title = nil,
}

function M.mark_commit_for_range()
  local qf_list = vim.fn.getqflist()
  local idx = vim.fn.line(".")
  if idx > #qf_list or idx < 1 then
    return
  end

  local entry = qf_list[idx]
  local commit_hash = entry.user_data

  if commit_hash and commit_hash ~= "" then
    M.range_selection.first_commit = commit_hash
    M.range_selection.qf_title = vim.fn.getqflist({ title = 1 }).title
    vim.notify(
      string.format("Marked commit %s. Navigate to second commit and press <CR> to compare.", commit_hash),
      vim.log.levels.INFO
    )
  end
end

function M.open_diffview_range()
  local qf_list = vim.fn.getqflist()
  local idx = vim.fn.line(".")
  if idx > #qf_list or idx < 1 then
    return
  end

  local entry = qf_list[idx]
  local second_commit = entry.user_data

  if not M.range_selection.first_commit then
    M.open_diffview_for_qf_entry()
    return
  end

  local first_commit = M.range_selection.first_commit

  M.range_selection.first_commit = nil
  M.range_selection.qf_title = nil

  if second_commit and second_commit ~= "" then
    vim.cmd("cclose")
    vim.cmd(string.format("DiffviewOpen %s..%s", first_commit, second_commit))
  end
end

function M.is_diffview_qf()
  local qf_title = vim.fn.getqflist({ title = 1 }).title or ""
  local is_branch_commits = qf_title:match("^Branch Commits:")
  local is_file_history = qf_title:match("^File History:")
  local is_commit_range = qf_title:match("^Commit Range:")
  return is_branch_commits or is_file_history or is_commit_range, qf_title:match("^Commit Range:"), is_file_history
end

function M.handle_qf_enter()
  local is_ours, is_range, is_file = M.is_diffview_qf()

  if not is_ours then
    local idx = vim.fn.line(".")
    vim.cmd("cclose")
    vim.cmd("cc " .. idx)
    return
  end

  if is_file then
    M.open_file_history_for_qf_entry()
  elseif is_range and M.range_selection.first_commit then
    M.open_diffview_range()
  else
    M.open_diffview_for_qf_entry()
  end
end

function M.handle_qf_mark()
  local is_ours = M.is_diffview_qf()
  if not is_ours then
    vim.cmd("normal! m")
    return
  end
  M.mark_commit_for_range()
end

function M.setup_qf_keymaps()
  local bufnr = vim.api.nvim_get_current_buf()

  vim.keymap.set("n", "<CR>", function()
    M.handle_qf_enter()
  end, {
    buffer = bufnr,
    desc = "Diffview: Open commit or default qf action",
    noremap = true,
    silent = true,
  })

  vim.keymap.set("n", "m", function()
    M.handle_qf_mark()
  end, {
    buffer = bufnr,
    desc = "Diffview: Mark commit for range",
    noremap = true,
    silent = true,
  })
end

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
      user_data = commit.hash,
    })
  end

  vim.fn.setqflist({}, "r", {
    title = string.format("Branch Commits: %s (%s)", branch, description),
    items = qf_items,
  })

  vim.cmd("copen")
  vim.notify(string.format("Loaded %d commits. Press <CR> to view diff.", #commits), vim.log.levels.INFO)
end

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
      user_data = commit.hash,
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
      user_data = commit.hash,
    })
  end

  vim.fn.setqflist({}, "r", {
    title = string.format("Commit Range: %s (%s) - Press 'm' to mark, <CR> to compare", branch, description),
    items = qf_items,
  })

  vim.cmd("copen")
  vim.notify("Press 'm' to mark first commit, then <CR> on second commit to compare range.", vim.log.levels.INFO)
end

local function setup_qf_autocmd()
  vim.api.nvim_create_augroup("DiffviewQF", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = "DiffviewQF",
    pattern = "qf",
    callback = function()
      vim.defer_fn(function()
        if vim.bo.filetype == "qf" then
          M.setup_qf_keymaps()
        end
      end, 100)
    end,
  })
end

local function setup_commands()
  vim.api.nvim_create_user_command("DiffBranchCommits", function()
    M.populate_branch_commits_qf()
  end, { desc = "List branch commits in quickfix for Diffview navigation" })

  vim.api.nvim_create_user_command("DiffFileHistory", function(opts)
    local filepath = opts.args ~= "" and opts.args or nil
    M.populate_file_commits_qf(filepath)
  end, { desc = "List file history commits in quickfix", nargs = "?" })

  vim.api.nvim_create_user_command("DiffCommitRange", function(opts)
    local args = vim.split(opts.args, " ", { trimempty = true })
    if #args >= 2 then
      vim.cmd(string.format("DiffviewOpen %s..%s", args[1], args[2]))
    elseif #args == 1 then
      vim.cmd(string.format("DiffviewOpen %s..HEAD", args[1]))
    else
      M.populate_commit_range_qf()
    end
  end, { desc = "Compare two commits with Diffview", nargs = "*" })
end

function M.setup()
  setup_qf_autocmd()
  setup_commands()
end

return {
  {
    "sindrets/diffview.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
      "DiffviewFileHistory",
      "DiffBranchCommits",
      "DiffFileHistory",
      "DiffCommitRange",
    },
    config = function()
      require("diffview").setup({
        enhanced_diff_hl = true,
        use_icons = true,
        show_help_hints = true,
        view = {
          default = {
            layout = "diff2_horizontal",
          },
          merge_tool = {
            layout = "diff3_horizontal",
          },
          file_history = {
            layout = "diff2_horizontal",
          },
        },
        file_panel = {
          listing_style = "tree",
          tree_options = {
            flatten_dirs = true,
            folder_statuses = "only_folded",
          },
          win_config = {
            position = "left",
            width = 35,
          },
        },
        keymaps = {
          view = {
            ["<tab>"] = false,
            ["<s-tab>"] = false,
            ["gf"] = false,
            ["<leader>e"] = "<Cmd>DiffviewToggleFiles<CR>",
            ["<leader>co"] = "<Cmd>DiffviewConflictChooseOurs<CR>",
            ["<leader>ct"] = "<Cmd>DiffviewConflictChooseTheirs<CR>",
            ["<leader>cb"] = "<Cmd>DiffviewConflictChooseBoth<CR>",
            ["<leader>cx"] = "<Cmd>DiffviewConflictChooseNone<CR>",
          },
          file_panel = {
            ["j"] = "<Cmd>lua require('diffview.actions').next_entry()<CR>",
            ["k"] = "<Cmd>lua require('diffview.actions').prev_entry()<CR>",
            ["<cr>"] = "<Cmd>lua require('diffview.actions').select_entry()<CR>",
            ["o"] = "<Cmd>lua require('diffview.actions').select_entry()<CR>",
            ["<2-LeftMouse>"] = "<Cmd>lua require('diffview.actions').select_entry()<CR>",
            ["<leader>e"] = "<Cmd>DiffviewToggleFiles<CR>",
            ["g<C-x>"] = "<Cmd>lua require('diffview.actions').cycle_layout()<CR>",
            ["[x"] = "<Cmd>lua require('diffview.actions').prev_conflict()<CR>",
            ["]x"] = "<Cmd>lua require('diffview.actions').next_conflict()<CR>",
          },
          file_history_panel = {
            ["j"] = "<Cmd>lua require('diffview.actions').next_entry()<CR>",
            ["k"] = "<Cmd>lua require('diffview.actions').prev_entry()<CR>",
            ["<cr>"] = "<Cmd>lua require('diffview.actions').select_entry()<CR>",
            ["o"] = "<Cmd>lua require('diffview.actions').select_entry()<CR>",
            ["<2-LeftMouse>"] = "<Cmd>lua require('diffview.actions').select_entry()<CR>",
            ["g!"] = "<Cmd>lua require('diffview.actions').options()<CR>",
            ["<leader>e"] = "<Cmd>DiffviewToggleFiles<CR>",
            ["g<C-x>"] = "<Cmd>lua require('diffview.actions').cycle_layout()<CR>",
          },
          option_panel = {
            ["<tab>"] = "<Cmd>lua require('diffview.actions').select_entry()<CR>",
            ["q"] = "<Cmd>lua require('diffview.actions').close()<CR>",
          },
        },
      })

      M.setup()
    end,
    keys = {
      {
        "<leader>dd",
        function()
          vim.cmd("DiffviewOpen")
        end,
        desc = "Diff HEAD",
      },
      {
        "<leader>dm",
        function()
          local default_branch = _G.DiffviewExtensions.get_default_branch() or "main"
          vim.cmd("DiffviewOpen " .. default_branch)
        end,
        desc = "Diff main",
      },
      {
        "<leader>db",
        function()
          _G.DiffviewExtensions.populate_branch_commits_qf()
        end,
        desc = "Branch commits",
      },
      {
        "<leader>df",
        function()
          _G.DiffviewExtensions.populate_file_commits_qf()
        end,
        desc = "File history",
      },
      {
        "<leader>dr",
        function()
          _G.DiffviewExtensions.populate_commit_range_qf()
        end,
        desc = "Commit range",
      },
      {
        "<leader>dh",
        function()
          vim.cmd("DiffviewFileHistory %")
        end,
        desc = "Current file history",
      },
      {
        "<leader>dc",
        "<Cmd>DiffviewClose<CR>",
        desc = "Close Diffview",
      },
    },
  },
}
