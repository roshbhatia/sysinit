-- git.lua
-- Git operations keybindings
local M = {}

-- Reference to the main keymaps module
local keymaps = require("sysinit.plugins.keymaps")

function M.setup()
    -- Register git group with the main keymaps module
    keymaps.register_group("g", keymaps.group_icons.git .. " Git", {
        {
            key = "g",
            desc = "LazyGit",
            neovim_cmd = "<cmd>LazyGit<CR>",
            vscode_cmd = "workbench.view.scm"
        },
        {
            key = "b",
            desc = "Git Blame Toggle",
            neovim_cmd = "<cmd>BlamerToggle<CR>",
            vscode_cmd = "git.toggleBlame"
        },
        {
            key = "p",
            desc = "Open PR",
            neovim_cmd = "<cmd>Octo pr list<CR>",
            vscode_cmd = "pr.openPullsWebsite"
        },
        {
            key = "r",
            desc = "Review PR",
            neovim_cmd = "<cmd>Octo review start<CR>",
            vscode_cmd = "pr.openReview"
        },
        {
            key = "c",
            desc = "Create PR",
            neovim_cmd = "<cmd>Octo pr create<CR>",
            vscode_cmd = "pr.create"
        },
        {
            key = "d",
            desc = "View Diff",
            neovim_cmd = "<cmd>Octo pr diff<CR>",
            vscode_cmd = "pr.openDiffView"
        },
        {
            key = "m",
            desc = "Merge PR",
            neovim_cmd = "<cmd>Octo pr merge<CR>",
            vscode_cmd = "pr.merge"
        }
    })
end

-- Add any git-specific plugins here
M.plugins = {}

return M