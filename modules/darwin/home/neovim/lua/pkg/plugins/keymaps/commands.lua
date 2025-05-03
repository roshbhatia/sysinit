local plugin_spec = {}

local cmd_map = {
    w = "workbench.action.files.save",
    wa = "workbench.action.files.saveAll",
    q = "workbench.action.closeActiveEditor",
    qa = "workbench.action.quit",
    enew = "workbench.action.files.newUntitledFile",
    bdelete = "workbench.action.closeActiveEditor",
    bd = "workbench.action.closeActiveEditor",
    bn = "workbench.action.nextEditor",
    bp = "workbench.action.previousEditor",
    split = "workbench.action.splitEditorDown",
    vsplit = "workbench.action.splitEditorRight",
    term = "workbench.action.terminal.toggleTerminal",
    find = "actions.find",
    grep = "workbench.action.findInFiles",
    cmd = "workbench.action.showCommands",
    Ex = "workbench.view.explorer"
}

local function map_cmd(mode, lhs, cmd, opts)
    local vscode = require('vscode')

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

function plugin_spec.setup()
    if not vim.g.vscode then
        return
    end

    local vscode = require('vscode')

    map_cmd("n", "<leader>w", "w")
    map_cmd("n", "<leader>q", "q")
    map_cmd("n", "<leader>wa", "wa")
    map_cmd("n", "<leader>bd", "bd")
    map_cmd("n", "<leader>bn", "bn")
    map_cmd("n", "<leader>bp", "bp")

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

    vim.keymap.set({"n", "i", "v"}, "<D-s>", function()
        vscode.action("workbench.action.files.save")
    end, {
        noremap = true,
        silent = true,
        desc = "Save file"
    })

    vim.keymap.set({"n", "i", "v"}, "<D-w>", function()
        vscode.action("workbench.action.closeActiveEditor")
    end, {
        noremap = true,
        silent = true,
        desc = "Close editor"
    })

    vim.keymap.set({"n", "i", "v"}, "<D-n>", function()
        vscode.action("workbench.action.files.newUntitledFile")
    end, {
        noremap = true,
        silent = true,
        desc = "New file"
    })

    vim.keymap.set("v", "<D-c>", function()
        vscode.action("editor.action.clipboardCopyAction")
    end, {
        noremap = true,
        silent = true,
        desc = "Copy to clipboard"
    })

    vim.keymap.set("v", "<D-x>", function()
        vscode.action("editor.action.clipboardCutAction")
    end, {
        noremap = true,
        silent = true,
        desc = "Cut to clipboard"
    })

    vim.keymap.set({"n", "i", "v"}, "<D-p>", function()
        vscode.action("editor.action.clipboardPasteAction")
    end, {
        noremap = true,
        silent = true,
        desc = "Paste from clipboard"
    })

    vim.keymap.set("n", "<D-/>", function()
        vscode.action("editor.action.commentLine")
    end, {
        noremap = true,
        silent = true,
        desc = "Toggle comment"
    })

    vim.keymap.set("v", "<D-/>", function()
        vscode.action("editor.action.commentLine")
    end, {
        noremap = true,
        silent = true,
        desc = "Toggle comment"
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

return plugin_spec
