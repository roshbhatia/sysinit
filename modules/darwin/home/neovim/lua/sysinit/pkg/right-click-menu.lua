-- Right-click menu implementation
local M = {}

-- Stores all menu configurations
local config = {
	explorer_menu = {},
	editor_menu = {},
	general_menu = {},
}

-- Modes where context menu will be available
local MODES = { "n" }

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

--- Create a menu item
---@param options table
---@return table
M.item = function(options)
	return {
		id = options.id or "PopUp",
		label = options.label or "",
		command = options.command or "<Nop>",
		condition = options.condition,
		items = options.items,
	}
end

--- Render menu item
---@param item table
local function render_menu_item(item)
	-- Skip if condition isn't met
	if item.condition and not item.condition() then
		return
	end

	-- Ensure we have a valid ID and label
	if not item.id or item.id == "" then
		item.id = "PopUp"
	end

	if not item.label or item.label == "" then
		return -- Skip items with empty labels
	end

	-- Create menu entries for each mode
	for _, mode in ipairs(MODES) do
		local menu_cmd = mode .. "menu " .. item.id .. "." .. escape_label(item.label) .. " " .. item.command
		pcall(vim.cmd, menu_cmd)
	end
end

--- Render a complete menu
---@param menu table
local function render_menu(menu)
	-- Skip if there's no valid ID
	if not menu.id or menu.id == "" then
		return
	end

	-- Clear existing menu first
	clear_menu(menu.id)

	-- Skip if condition isn't met
	if menu.condition and not menu.condition() then
		return
	end

	-- Skip if there are no items
	if not menu.items or #menu.items == 0 then
		return
	end

	-- Render all menu items
	for _, item in ipairs(menu.items) do
		-- Update the id to include parent id
		item.id = menu.id
		render_menu_item(item)
	end

	-- Skip adding to popup if menu has no label
	if not menu.label or menu.label == "" then
		return
	end

	-- Add menu to popup
	pcall(function()
		render_menu_item({
			id = "PopUp",
			label = menu.label,
			command = "<cmd>popup " .. menu.id .. "<cr>",
		})
	end)
end

-- Initialize popup menu
pcall(function()
	clear_menu("PopUp")
end)

-- Helper function to check if we're in Neotree
local function is_neotree()
	return vim.tbl_contains({ "neo-tree", "neo-tree-popup" }, vim.bo.filetype)
end

-- Helper function to check if we're in a regular editor buffer
local function is_editor()
	local ft = vim.bo.filetype
	return ft ~= "neo-tree" and ft ~= "neo-tree-popup" and ft ~= "" and ft ~= "NvimTree"
end

--- Create a context menu
---@param menu table
M.menu = function(menu)
	-- Skip items with invalid data
	if not menu or not menu.label or menu.label == "" then
		return
	end

	-- Create autocommand to update the menu
	vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
		callback = function()
			-- Skip execution if there are issues
			pcall(function()
				-- Clear existing menu entry
				clear_menu("PopUp." .. escape_label(menu.label))

				-- Check condition if exists
				local should_render = true
				if menu.condition then
					should_render = menu.condition()
				end

				-- Render menu if condition passes
				if should_render then
					if menu.items and #menu.items > 0 then
						render_menu(menu)
					else
						render_menu_item({
							id = "PopUp",
							label = menu.label,
							command = menu.command,
							condition = menu.condition,
						})
					end
				end

				-- Special handling for special filetypes like neo-tree
				if is_neotree() then
					-- Clean up default entries that might interfere
					pcall(function()
						vim.cmd([[
                            silent! aunmenu PopUp.\.
                            silent! aunmenu PopUp.-1-
                        ]])
					end)

					-- Re-attach menu for special filetypes
					if should_render and menu.neotree ~= false then
						if menu.items and #menu.items > 0 then
							render_menu(menu)
						else
							render_menu_item({
								id = "PopUp",
								label = menu.label,
								command = menu.command,
							})
						end
					end
				end
			end)
		end,
	})
end

-- Create a separator
M.separator = function(id)
	return {
		id = id or "PopUp",
		label = "-",
		command = "<Nop>",
	}
end

-- Register menus with appropriate context conditions
local function register_menus()
	-- Clear all existing menus first
	pcall(function()
		clear_menu("PopUp")
	end)

	-- Register file explorer context menu (neotree)
	for _, item in ipairs(config.explorer_menu) do
		-- Only show in Neotree
		local orig_condition = item.condition
		item.condition = function()
			return is_neotree() and (not orig_condition or orig_condition())
		end
		item.editor = false
		M.menu(item)
	end

	-- Register editor context menu
	for _, item in ipairs(config.editor_menu) do
		-- Only show in editor
		local orig_condition = item.condition
		item.condition = function()
			return is_editor() and (not orig_condition or orig_condition())
		end
		item.neotree = false
		M.menu(item)
	end

	-- Register shared/general context menu
	for _, item in ipairs(config.general_menu) do
		M.menu(item)
	end
end

-- Add menu items
M.add = function(cfg)
	cfg = cfg or {}

	-- Add new menu items to our config
	if cfg.explorer_menu then
		for _, item in ipairs(cfg.explorer_menu) do
			if item and item.label and item.label ~= "" then
				table.insert(config.explorer_menu, item)
			end
		end
	end

	if cfg.editor_menu then
		for _, item in ipairs(cfg.editor_menu) do
			if item and item.label and item.label ~= "" then
				table.insert(config.editor_menu, item)
			end
		end
	end

	if cfg.general_menu then
		for _, item in ipairs(cfg.general_menu) do
			if item and item.label and item.label ~= "" then
				table.insert(config.general_menu, item)
			end
		end
	end

	-- Re-register all menus with the new additions
	pcall(function()
		register_menus()
	end)
end

-- Initialize the right-click menu system
M.setup = M.add

return M
