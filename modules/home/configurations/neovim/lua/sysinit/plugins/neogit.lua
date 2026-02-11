-- Find git repositories in the current directory
local function find_git_repos()
  local cwd = vim.fn.getcwd()
  local repos = {}

  -- Check if current directory is a git repo
  local current_is_git = vim.fn.isdirectory(cwd .. "/.git") == 1
  if current_is_git then
    table.insert(repos, { path = cwd, name = vim.fn.fnamemodify(cwd, ":t") })
  end

  -- Check immediate subdirectories for git repos
  local subdirs = vim.fn.glob(cwd .. "/*", false, true)
  for _, subdir in ipairs(subdirs) do
    if vim.fn.isdirectory(subdir) == 1 and vim.fn.isdirectory(subdir .. "/.git") == 1 then
      local name = vim.fn.fnamemodify(subdir, ":t")
      table.insert(repos, { path = subdir, name = name })
    end
  end

  return repos
end

-- Open Neogit with optional arguments, handling multiple git repos
local function open_neogit_smart(args)
  args = args or {}
  local repos = find_git_repos()

  -- If only one repo, open directly
  if #repos == 1 then
    args.cwd = repos[1].path
    require("neogit").open(args)
    return
  end

  -- If multiple repos, show selection UI
  if #repos > 1 then
    vim.ui.select(repos, {
      prompt = "Select git repository:",
      format_item = function(item)
        return item.name
      end,
    }, function(choice)
      if choice then
        args.cwd = choice.path
        require("neogit").open(args)
      end
    end)
    return
  end

  -- No repos found, open with default behavior
  require("neogit").open(args)
end

return {
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    lazy = false,
    config = function()
      require("neogit").setup({
        graph_style = "kitty",
        commit_editor = {
          staged_diff_split_kind = "auto",
        },
        mappings = {
          commit_editor = {
            ["<localleader>s"] = "Submit",
            ["<localleader>q"] = "Abort",
            ["<localleader>mp"] = "PrevMessage",
            ["<localleader>mn"] = "NextMessage",
            ["<localleader>mr"] = "ResetMessage",
          },
          commit_editor_I = {
            ["<localleader>s"] = "Submit",
            ["<localleader>q"] = "Abort",
          },
          rebase_editor = {
            ["<localleader>s"] = "Submit",
            ["<localleader>q"] = "Abort",
            ["[uu"] = "OpenOrScrollUp",
            ["]ud"] = "OpenOrScrollDown",
          },
          rebase_editor_I = {
            ["<localleader>s"] = "Submit",
            ["<localleader>q"] = "Abort",
          },
          finder = {
            ["<localleader>q"] = "Close",
            ["<localleader>n"] = "Next",
            ["<localleader>p"] = "Previous",
            ["<down>"] = "Next",
            ["<up>"] = "Previous",
            ["<localleader>y"] = "CopySelection",
          },
          status = {
            ["<localleader>S"] = "StageAll",
            ["<localleader>r"] = "RefreshBuffer",
            ["<localleader>v"] = "VSplitOpen",
            ["<localleader>s"] = "SplitOpen",
            ["<localleader>t"] = "TabOpen",
            ["[uu"] = "OpenOrScrollUp",
            ["]ud"] = "OpenOrScrollDown",
            ["<localleader>k"] = "PeekUp",
            ["<localleader>j"] = "PeekDown",
            ["<localleader>n"] = "NextSection",
            ["<localleader>p"] = "PreviousSection",
          },
        },
      })
    end,
    keys = {
      {
        "<leader>gg",
        function()
          open_neogit_smart()
        end,
        desc = "Toggle",
        mode = "n",
      },
      {
        "<leader>gc",
        function()
          open_neogit_smart({ "commit" })
        end,
        desc = "Commit",
        mode = "n",
      },
      {
        "<leader>gp",
        function()
          open_neogit_smart({ "push" })
        end,
        desc = "Push",
        mode = "n",
      },
      {
        "<leader>gP",
        function()
          open_neogit_smart({ "pull" })
        end,
        desc = "Pull",
        mode = "n",
      },
      {
        "<leader>ge",
        function()
          open_neogit_smart({ "branch" })
        end,
        desc = "Branch",
        mode = "n",
      },
      {
        "<leader>gl",
        function()
          open_neogit_smart({ "log" })
        end,
        desc = "Log",
        mode = "n",
      },
    },
  },
}
