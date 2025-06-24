local wezterm = require("wezterm")
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
local lib = wezterm.plugin.require("https://github.com/chrisgve/lib.wezterm")
local M = {}

local function is_vim(pane)
	return pane:get_user_vars().IS_NVIM == "true"
end

local function get_username()
	local success, username = lib.file_io.execute("whoami")
	if success then
		return username:gsub("%s+", "")
	end
	return "unknown"
end

local function get_gh_username()
	local username = get_username()
	local gh_whoami_path = "/Users/" .. username .. "/.config/zsh/bin/gh-whoami"
	local success, gh_user = lib.file_io.execute(gh_whoami_path)
	if success then
		return gh_user:gsub("%s+", "")
	end
	return "unknown"
end

local function setup_tab_bar_visibility()
	wezterm.on("update-status", function(window, pane)
		local tab_bar_hidden = is_vim(pane)
		local overrides = window:get_config_overrides() or {}
		if tab_bar_hidden ~= (overrides.enable_tab_bar == false) then
			overrides.enable_tab_bar = not tab_bar_hidden
			window:set_config_overrides(overrides)
		end
	end)
end

function M.setup(config)
	tabline.setup({
		options = {
			icons_enabled = true,
			theme = "Catppuccin Latte",
			tabs_enabled = true,
			theme_overrides = {},
			section_separators = {
				left = wezterm.nerdfonts.pl_left_hard_divider,
				right = wezterm.nerdfonts.pl_right_hard_divider,
			},
			component_separators = {
				left = wezterm.nerdfonts.pl_left_soft_divider,
				right = wezterm.nerdfonts.pl_right_soft_divider,
			},
			tab_separators = {
				left = wezterm.nerdfonts.pl_left_hard_divider,
				right = wezterm.nerdfonts.pl_right_hard_divider,
			},
		},
		sections = {
			tabline_a = { "mode" },
			tabline_b = { "workspace" },
			tabline_c = { " " },
			tab_active = {
				"index",
				{ "parent", padding = 0 },
				"/",
				{ "cwd", padding = { left = 0, right = 1 } },
				{ "zoomed", padding = 0 },
			},
			tab_inactive = { "index", { "process", padding = { left = 0, right = 1 } } },
			tabline_x = { get_gh_username },
			tabline_y = {},
			tabline_z = { "domain" },
		},
		extensions = {},
	})
	setup_tab_bar_visibility()
	return config
end

return M

