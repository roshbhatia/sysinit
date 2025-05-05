local M = {}

-- Basic defaults for the menu
local DEFAULTS = {
    menu_item_width = 30,
    submenu_indicator = "▸"
}

-- Modes where context menu will be available
local MODES = {"n", "i"}

--- Clear all entries from a menu
---@param menu string
local function clear_menu(menu)
    pcall(function()
        vim.cmd("aunmenu " .. menu)
    end)
end

--- Format menu label to escape special characters
---@param label string
---@return string
local function escape_label(label)
    local res = string.gsub(label, " ", [[\ ]])
    res = string.gsub(res, "<", [[\<]])
    res = string.gsub(res, ">", [[\>]])
    return res
end

--- Format menu item label with proper spacing
---@param menu table
local function format_menu_label(menu)
    local padding = DEFAULTS.menu_item_width - #menu.label

    -- Add submenu indicator if needed
    if menu.items ~= nil then
        menu.label = menu.label .. string.rep(" ", padding - 2) .. DEFAULTS.submenu_indicator
        return
    end

    -- Format regular menu item
    local command_display = menu.command and menu.command or ""
    menu.label = menu.label .. string.rep(" ", math.max(2, padding - #command_display)) .. command_display
end

--- Create a menu item
---@param options table
---@return table
M.menu_item = function(options)
    return {
        id = options.id,
        label = options.label,
        command = options.command or "<Nop>",
        condition = options.condition,
        items = options.items
    }
end

--- Render menu item
---@param item table
local function render_menu_item(item)
    -- Skip if condition isn't met
    if item.condition and not item.condition() then
        return
    end

    -- Create menu entries for each mode
    for _, mode in ipairs(MODES) do
        vim.cmd(mode .. "menu " .. item.id .. "." .. escape_label(item.label) .. " " .. item.command)
    end
end

--- Render a complete menu
---@param menu table
local function render_menu(menu)
    -- Clear existing menu first
    clear_menu(menu.id)

    -- Skip if condition isn't met
    if menu.condition and not menu.condition() then
        return
    end

    -- Render all menu items
    for _, item in ipairs(menu.items or {}) do
        -- Update the id to include parent id
        item.id = menu.id
        render_menu_item(item)
    end

    -- Add menu to popup
    render_menu_item({
        id = "PopUp",
        label = menu.label,
        command = "<cmd>popup " .. menu.id .. "<cr>"
    })
end

-- Initialize popup menu
clear_menu("PopUp")

--- Create a context menu
---@param menu table
M.menu = function(menu)
    -- Format labels
    format_menu_label(menu)
    if menu.items then
        for _, item in ipairs(menu.items) do
            format_menu_label(item)
        end
    end

    -- Create autocommand to update the menu
    vim.api.nvim_create_autocmd({"BufEnter", "FileType"}, {
        callback = function()
            -- Clear existing menu entry
            clear_menu("PopUp." .. escape_label(menu.label))

            -- Check condition if exists
            local should_render = true
            if menu.condition then
                should_render = menu.condition()
            end

            -- Render menu if condition passes
            if should_render then
                if menu.items then
                    render_menu(menu)
                else
                    render_menu_item({
                        id = "PopUp",
                        label = menu.label,
                        command = menu.command,
                        condition = menu.condition
                    })
                end
            end

            -- Special handling for special filetypes like neo-tree
            if vim.tbl_contains({"neo-tree", "NvimTree", "neo-tree-popup"}, vim.bo.filetype) then
                -- Clean up default entries that might interfere
                pcall(function()
                    vim.cmd([[
                        silent! aunmenu PopUp.\.
                        silent! aunmenu PopUp.-1-
                    ]])
                end)

                -- Re-attach menu for special filetypes
                if should_render then
                    if menu.items then
                        render_menu(menu)
                    else
                        render_menu_item({
                            id = "PopUp",
                            label = menu.label,
                            command = menu.command
                        })
                    end
                end
            end
        end
    })
end

return M
