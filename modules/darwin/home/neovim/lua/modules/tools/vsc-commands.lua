local M = {}

local cmd_map = {
    w = "workbench.action.files.save",
    wa = "workbench.action.files.saveAll",
    q = "workbench.action.closeActiveEditor",
    qa = "workbench.action.quit",
    enew = "workbench.action.files.newUntitledFile",
    bdelete = "workbench.action.closeActiveEditor",
    bn = "workbench.action.nextEditor",
    bp = "workbench.action.previousEditor",
    split = "workbench.action.splitEditorDown",
    vsplit = "workbench.action.splitEditorRight"
}

local function map_cmd(mode, lhs, cmd, opts)
    opts = opts or {
        noremap = true,
        silent = true
    }
    local action = cmd_map[cmd]
    if action then
        vim.keymap.set(mode, lhs, function()
            vscode.action(action)
        end, opts)
    else
        vim.keymap.set(mode, lhs, '<cmd>' .. cmd .. '<cr>', opts)
    end
end

function M.setup()
    map_cmd("n", "<leader>w", "w")
    map_cmd("n", "<leader>q", "q")
    map_cmd("n", "<leader>wa", "wa")

    vim.keymap.set("n", "gd", function()
        vscode.action("editor.action.revealDefinition")
    end, {
        noremap = true,
        silent = true,
        desc = "Go to Definition"
    })

    vim.keymap.set("n", "gr", function()
        vscode.action("editor.action.goToReferences")
    end, {
        noremap = true,
        silent = true,
        desc = "Go to References"
    })

    vim.keymap.set("n", "gi", function()
        vscode.action("editor.action.goToImplementation")
    end, {
        noremap = true,
        silent = true,
        desc = "Go to Implementation"
    })

    vim.keymap.set("n", "K", function()
        vscode.action("editor.action.showHover")
    end, {
        noremap = true,
        silent = true,
        desc = "Show Hover"
    })

    vim.keymap.set("n", "gcc", function()
        vscode.action("editor.action.commentLine")
    end, {
        noremap = true,
        silent = true,
        desc = "Toggle Comment"
    })

    vim.keymap.set("v", "gc", function()
        vscode.action("editor.action.commentLine")
    end, {
        noremap = true,
        silent = true,
        desc = "Toggle Comment"
    })

    vim.keymap.set("n", "<Esc><Esc>", function()
        vscode.action("workbench.action.focusActiveEditorGroup")
    end, {
        noremap = true,
        silent = true,
        desc = "Focus Editor"
    })

    vim.api.nvim_create_user_command("VSCodeNotify", function(opts)
        local args = opts.args
        if args and args ~= "" then
            vscode.action(args)
        end
    end, {
        nargs = 1
    })

    vim.api.nvim_create_user_command("Explorer", function()
        vscode.action("workbench.view.explorer")
    end, {})

    vim.api.nvim_create_user_command("Terminal", function()
        vscode.action("workbench.action.terminal.toggleTerminal")
    end, {})

    vim.api.nvim_create_user_command("Problems", function()
        vscode.action("workbench.actions.view.problems")
    end, {})
end

return M
