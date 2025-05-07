-- NvChad UI configuration for statusline, CMP, and other UI components
local M = {}

-- Default configurations
M.config = {
    statusline = {
        theme = "default", -- Options: default, vscode, minimal, arrow
        separator_style = "block", -- Options: default, round, block, arrow
        overriden_modules = nil,
    },
    
    cmp = {
        style = "default", -- Options: default, flat, atom, atom_colored
        border_color = "grey",
        selected_item_bg = "colored", -- Options: colored, simple
    },
    
    tabufline = {
        enabled = true,
        lazyload = true,
        overriden_modules = nil,
    },
    
    lsp = {
        signature = {
            enabled = true,
            silent = false, -- if true, doesn't show when signature appears/updates
        },
        renamer = {
            enabled = true,
            border = "rounded",
            min_width = 30,
            max_width = 60,
        },
    },
}

function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})
    
    -- Initialize Base46 (main theme system)
    vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46_cache/"
    vim.opt.termguicolors = true

    -- Load NvChad UI components
    local present, ui = pcall(require, "nvchad.ui")
    if not present then
        vim.notify("NvChad UI not available", vim.log.levels.WARN)
        return
    end
    
    -- Configure statusline based on options
    ui.statusline.config.theme = M.config.statusline.theme
    ui.statusline.config.separator_style = M.config.statusline.separator_style
    if M.config.statusline.overriden_modules then
        ui.statusline.config.overriden_modules = M.config.statusline.overriden_modules
    end
    ui.statusline.setup()
    
    -- Configure tabufline
    if M.config.tabufline.enabled then
        ui.tabufline.setup()
    end
    
    -- Configure CMP theming
    if ui.cmp_themes then
        ui.cmp_themes.setup({
            style = M.config.cmp.style,
            border_color = M.config.cmp.border_color,
            selected_item_bg = M.config.cmp.selected_item_bg,
        })
    end
    
    -- Configure LSP signature
    if M.config.lsp.signature.enabled then
        local lsp = require("nvchad.ui.lsp")
        if lsp and lsp.signature then
            lsp.signature.setup({
                silent = M.config.lsp.signature.silent,
            })
        end
    end
    
    -- Configure LSP renamer
    if M.config.lsp.renamer.enabled then
        local renamer = require("nvchad.ui.lsp.renamer")
        if renamer then
            renamer.setup({
                border = M.config.lsp.renamer.border,
                min_width = M.config.lsp.renamer.min_width,
                max_width = M.config.lsp.renamer.max_width,
            })
        end
    end
    
    -- Load essential theme components
    vim.schedule(function()
        -- Load required theme components
        dofile(vim.g.base46_cache .. "defaults")
        dofile(vim.g.base46_cache .. "statusline")
        dofile(vim.g.base46_cache .. "lsp")
        dofile(vim.g.base46_cache .. "cmp")
    end)
end

-- Function to toggle between statusline styles
function M.toggle_statusline_style()
    local styles = {"default", "vscode", "minimal", "arrow"}
    local current_style = M.config.statusline.separator_style
    
    -- Find the current style index
    local current_index = 1
    for i, style in ipairs(styles) do
        if style == current_style then
            current_index = i
            break
        end
    end
    
    -- Get the next style
    local next_index = (current_index % #styles) + 1
    local next_style = styles[next_index]
    
    -- Update the style
    M.config.statusline.separator_style = next_style
    
    -- Apply the change
    local present, ui = pcall(require, "nvchad.ui")
    if present and ui.statusline then
        ui.statusline.config.separator_style = next_style
        vim.cmd("redrawstatus")
        vim.notify("Statusline style: " .. next_style, vim.log.levels.INFO)
    end
end

return M
