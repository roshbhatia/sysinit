local Entrypoint = {}

function Entrypoint.setup_actions()
    -- Set up key mappings for Neovim
    vim.keymap.set("n", "<C-h>", "<C-w>h", {
        noremap = true,
        silent = true,
        desc = "Move to left window"
    })

    vim.keymap.set("n", "<C-j>", "<C-w>j", {
        noremap = true,
        silent = true,
        desc = "Move to lower window"
    })

    vim.keymap.set("n", "<C-k>", "<C-w>k", {
        noremap = true,
        silent = true,
        desc = "Move to upper window"
    })

    vim.keymap.set("n", "<C-l>", "<C-w>l", {
        noremap = true,
        silent = true,
        desc = "Move to right window"
    })

    vim.keymap.set("n", "<A-b>", "<cmd>Neotree toggle<CR>", {
        noremap = true,
        silent = true,
        desc = "Toggle file explorer"
    })

    vim.keymap.set("n", "<D-b>", "<cmd>Neotree toggle<CR>", {
        noremap = true,
        silent = true,
        desc = "Toggle file explorer"
    })

    vim.keymap.set("n", "<A-D-jkb>", "<cmd>CopilotChatToggle<CR>", {
        noremap = true,
        silent = true,
        desc = "Toggle Copilot Chat"
    })

    vim.keymap.set("n", "<S-CR>", "<cmd>HopWord<CR>", {
        noremap = true,
        silent = true,
        desc = "Hop to word"
    })

    vim.keymap.set("i", "<S-CR>", "<Esc><cmd>HopWord<CR>", {
        noremap = true,
        silent = true,
        desc = "Hop to word"
    })

    vim.keymap.set("n", "<D-/>", "<Plug>(comment_toggle_linewise_current)", {
        desc = "Toggle comment"
    })

    vim.keymap.set("v", "<D-/>", "<Plug>(comment_toggle_linewise_visual)", {
        desc = "Toggle comment"
    })

    for i = 1, 9 do
        vim.keymap.set("n", "<C-" .. i .. ">", "<cmd>buffer " .. i .. "<CR>", {
            noremap = true,
            silent = true,
            desc = "Switch to buffer " .. i
        })
    end

    vim.keymap.set({"n", "i", "v"}, "<D-s>", "<cmd>w<CR>", {
        noremap = true,
        silent = true,
        desc = "Save file"
    })

    vim.keymap.set({"n", "i", "v"}, "<D-w>", function()
        local buf_count = 0
        for _ in pairs(vim.fn.getbufinfo({
            buflisted = 1
        })) do
            buf_count = buf_count + 1
        end

        if buf_count <= 1 then
            vim.cmd("q")
        else
            vim.cmd("bd")
        end
    end, {
        noremap = true,
        silent = true,
        desc = "Close buffer or quit"
    })

    vim.keymap.set({"n", "i", "v"}, "<D-n>", "<cmd>enew<CR>", {
        noremap = true,
        silent = true,
        desc = "New file"
    })

    vim.keymap.set("v", "<D-c>", '"+y', {
        noremap = true,
        silent = true,
        desc = "Copy to clipboard"
    })

    vim.keymap.set({"n", "i"}, "<D-c>", '<cmd>let @+=@"<CR>', {
        noremap = true,
        silent = true,
        desc = "Copy to clipboard"
    })

    vim.keymap.set("v", "<D-x>", '"+d', {
        noremap = true,
        silent = true,
        desc = "Cut to clipboard"
    })

    vim.keymap.set({"n", "i", "v"}, "<D-p>", '"+p', {
        noremap = true,
        silent = true,
        desc = "Paste from clipboard"
    })

    vim.keymap.set({"n", "i"}, "<D-z>", "<cmd>undo<CR>", {
        noremap = true,
        silent = true,
        desc = "Undo"
    })

    vim.keymap.set({"n", "i"}, "<D-S-z>", "<cmd>redo<CR>", {
        noremap = true,
        silent = true,
        desc = "Redo"
    })

    vim.keymap.set({"n", "v", "i"}, "<D-a>", function()
        if vim.fn.mode() == 'i' then
            return "<Esc>ggVG"
        else
            return "ggVG"
        end
    end, {
        noremap = true,
        expr = true,
        desc = "Select all"
    })

    vim.keymap.set({"n", "i"}, "<D-f>", function()
        if vim.fn.mode() == 'i' then
            return "<Esc>/"
        else
            return "/"
        end
    end, {
        noremap = true,
        expr = true,
        desc = "Find"
    })

    vim.keymap.set("n", "<D-S-f>", "<cmd>Telescope live_grep<CR>", {
        noremap = true,
        silent = true,
        desc = "Find in files"
    })

    vim.keymap.set("n", "<D-p>", "<cmd>Telescope find_files<CR>", {
        noremap = true,
        silent = true,
        desc = "Quick open"
    })

    vim.keymap.set("n", "<D-S-p>", "<cmd>Telescope commands<CR>", {
        noremap = true,
        silent = true,
        desc = "Command palette"
    })

    vim.keymap.set({"n", "i"}, "<D-f>", "/", {
        noremap = true,
        desc = "Find"
    })
end

function Entrypoint.setup_options()
    -- Basic settings
    vim.opt.clipboard = "unnamedplus"
    vim.opt.mouse = "a"
    vim.opt.number = true
    vim.opt.signcolumn = "number"

    -- UI settings
    vim.opt.pumheight = 10
    vim.opt.cmdheight = 1
    vim.opt.showtabline = 2
    vim.opt.timeoutlen = 500
    vim.opt.updatetime = 300
    vim.opt.laststatus = 3

    vim.opt.guicursor = {"n-v-c:block-Cursor/lCursor", -- Block cursor in normal, visual, and command modes
    "i:ver25-blinkwait700-blinkoff400-blinkon250-Cursor/lCursor", -- Blinking vertical line in insert mode
    "r-cr-o:hor20-Cursor/lCursor", -- Horizontal line cursor in replace, command-line replace, and operator-pending modes
                         "a:blinkwait700-blinkoff400-blinkon250" -- Global blinking settings for all modes
    }

    -- Completion settings
    vim.opt.shortmess:append("c")
    vim.opt.completeopt = {"menuone", "noselect"}

    -- Visual settings
    vim.opt.fillchars:append({
        eob = " ",
        vert = "│",
        fold = "⤷"
    })

    -- Folding settings
    vim.wo.foldmethod = 'expr'
    vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

    vim.env.PATH = vim.fn.getenv("PATH")
end

function Entrypoint.get_plugins()
    return {require("sysinit.plugins.ui.cmdline"), require("sysinit.plugins.ui.notifications"),
            require("sysinit.plugins.ui.live-command"), require("sysinit.plugins.ui.alpha"),
            require("sysinit.plugins.ui.devicons"), require("sysinit.plugins.ui.minimap"),
            require("sysinit.plugins.ui.nui"), require("sysinit.plugins.ui.scrollbar"),
            require("sysinit.plugins.ui.smart-splits"), require("sysinit.plugins.ui.statusbar"),
            require("sysinit.plugins.ui.tab"), require("sysinit.plugins.ui.theme"),
            require("sysinit.plugins.ui.transparent"), require("sysinit.plugins.editor.hop"),
            require("sysinit.plugins.keymaps.pallete"), require("sysinit.plugins.editor.comment"),
            require("sysinit.plugins.editor.commentstring"), require("sysinit.plugins.editor.formatter"),
            require("sysinit.plugins.editor.ibl"), require("sysinit.plugins.file.diffview"),
            require("sysinit.plugins.file.editor"), require("sysinit.plugins.file.session"),
            require("sysinit.plugins.file.telescope"), require("sysinit.plugins.ui.dressing"),
            require("sysinit.plugins.file.tree"), require("sysinit.plugins.git.blame"),
            require("sysinit.plugins.git.client"), require("sysinit.plugins.git.octo"),
            require("sysinit.plugins.git.fugitive"), require("sysinit.plugins.git.signs"),
            require("sysinit.plugins.intellicode.avante"), require("sysinit.plugins.intellicode.cmp-buffer"),
            require("sysinit.plugins.intellicode.cmp-cmdline"), require("sysinit.plugins.intellicode.cmp-git"),
            require("sysinit.plugins.intellicode.cmp-nvim-lsp"), require("sysinit.plugins.intellicode.cmp-nvim-lua"),
            require("sysinit.plugins.intellicode.cmp-path"), require("sysinit.plugins.intellicode.copilot-cmp"),
            require("sysinit.plugins.intellicode.copilot"), require("sysinit.plugins.intellicode.copilot-chat"),
            require("sysinit.plugins.intellicode.friendly-snippets"),
            require("sysinit.plugins.intellicode.guess-indent"), require("sysinit.plugins.intellicode.img-clip"),
            require("sysinit.plugins.intellicode.linters"), require("sysinit.plugins.intellicode.luasnip"),
            require("sysinit.plugins.intellicode.mason-lspconfig"), require("sysinit.plugins.intellicode.mason"),
            require("sysinit.plugins.intellicode.nvim-autopairs"), require("sysinit.plugins.intellicode.nvim-cmp"),
            require("sysinit.plugins.intellicode.nvim-lspconfig"), require("sysinit.plugins.intellicode.outline"),
            require("sysinit.plugins.editor.render-markdown"), require("sysinit.plugins.intellicode.sort"),
            require("sysinit.plugins.intellicode.trailspace"),
            require("sysinit.plugins.intellicode.treesitter-textobjects"),
            require("sysinit.plugins.intellicode.treesitter"), require("sysinit.plugins.intellicode.trouble"),
            require("sysinit.plugins.debugger.dap")}
end

return Entrypoint
