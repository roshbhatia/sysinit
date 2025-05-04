local vscode = require('vscode')

local Entrypoint = {}

function Entrypoint.setup_actions()
    -- Set up key mappings for VSCode
    vim.keymap.set("n", "<C-h>", function()
        vscode.action("workbench.action.focusLeftGroup")
    end, {
        noremap = true,
        silent = true,
        desc = "Move to left window"
    })

    vim.keymap.set("n", "<C-j>", function()
        vscode.action("workbench.action.focusBelowGroup")
    end, {
        noremap = true,
        silent = true,
        desc = "Move to lower window"
    })

    vim.keymap.set("n", "<C-k>", function()
        vscode.action("workbench.action.focusAboveGroup")
    end, {
        noremap = true,
        silent = true,
        desc = "Move to upper window"
    })

    vim.keymap.set("n", "<C-l>", function()
        vscode.action("workbench.action.focusRightGroup")
    end, {
        noremap = true,
        silent = true,
        desc = "Move to right window"
    })

    vim.keymap.set("n", "<D-b>", function()
        vscode.action("workbench.view.explorer")
    end, {
        noremap = true,
        silent = true,
        desc = "Toggle explorer"
    })

    vim.keymap.set("n", "<A-b>", function()
        vscode.action("workbench.view.explorer")
    end, {
        noremap = true,
        silent = true,
        desc = "Toggle explorer"
    })

    vim.keymap.set("n", "<A-D-jkb>", function()
        vscode.action("workbench.action.chat.openInSidebar")
    end, {
        noremap = true,
        silent = true,
        desc = "Toggle chat"
    })

    for i = 1, 9 do
        vim.keymap.set("n", "<C-" .. i .. ">", function()
            vscode.action("workbench.action.openEditorAtIndex" .. i)
        end, {
            noremap = true,
            silent = true,
            desc = "Switch to editor " .. i
        })
    end

    vim.keymap.set({"n", "i"}, "<D-z>", function()
        vscode.action("undo")
    end, {
        noremap = true,
        silent = true,
        desc = "Undo"
    })

    vim.keymap.set({"n", "i"}, "<D-S-z>", function()
        vscode.action("redo")
    end, {
        noremap = true,
        silent = true,
        desc = "Redo"
    })

    vim.keymap.set({"n", "v", "i"}, "<D-a>", function()
        vscode.action("editor.action.selectAll")
    end, {
        noremap = true,
        silent = true,
        desc = "Select all"
    })

    vim.keymap.set({"n", "i"}, "<D-f>", function()
        vscode.action("actions.find")
    end, {
        noremap = true,
        silent = true,
        desc = "Find"
    })

    vim.keymap.set("n", "<D-S-f>", function()
        vscode.action("workbench.action.findInFiles")
    end, {
        noremap = true,
        silent = true,
        desc = "Find in files"
    })

    vim.keymap.set("n", "<D-p>", function()
        vscode.action("workbench.action.quickOpen")
    end, {
        noremap = true,
        silent = true,
        desc = "Quick open"
    })

    vim.keymap.set("n", "<D-S-p>", function()
        vscode.action("workbench.action.showCommands")
    end, {
        noremap = true,
        silent = true,
        desc = "Show commands"
    })

    local function map_cmd(mode, lhs, cmd, opts)
        cmd_map = {
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

function Entrypoint.setup_options()
    vim.opt.foldmethod = "manual"
    vim.notify = require('vscode').notify
    vim.g.clipboard = vim.g.vscode_clipboard
end

function Entrypoint.get_plugins()
    return {require("sysinit.plugins.ui.statusbar"), require("sysinit.plugins.keymaps.pallete")}
end

return Entrypoint
