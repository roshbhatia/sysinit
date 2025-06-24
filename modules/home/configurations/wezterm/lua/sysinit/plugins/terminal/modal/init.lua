local wezterm = require("wezterm")
local modal = wezterm.plugin.require("https://github.com/MLFlexer/modal.wezterm")
local M = {}

local function setup_custom_modes()
	modal.enable_defaults("https://github.com/MLFlexer/modal.wezterm")

	local icons = {
		left_seperator = wezterm.nerdfonts.ple_left_half_circle_thick,
		key_hint_seperator = " | ",
		mod_seperator = "-",
	}

	local hint_colors = {
		key_hint_seperator = "#fab387",
		key = "#a6e3a1",
		hint = "#f38ba8",
		bg = "#45475a",
		left_bg = "#585b70",
	}

	local ui_mode_colors = { bg = "#cba6f7", fg = "#45475a" }
	local copy_mode_colors = { bg = "#89b4fa", fg = "#45475a" }
	local scroll_mode_colors = { bg = "#94e2d5", fg = "#45475a" }

	local ui_key_table = require("ui_mode").key_table
	local ui_status_text = require("ui_mode").get_hint_status_text(icons, hint_colors, ui_mode_colors)
	modal.add_mode("UI", ui_key_table, ui_status_text)

	local copy_key_table = require("copy_mode").key_table
	local copy_status_text = require("copy_mode").get_hint_status_text(icons, hint_colors, copy_mode_colors)
	modal.add_mode("Copy", copy_key_table, copy_status_text)

	local scroll_key_table = require("scroll_mode").key_table
	local scroll_status_text = require("scroll_mode").get_hint_status_text(icons, hint_colors, scroll_mode_colors)
	modal.add_mode("Scroll", scroll_key_table, scroll_status_text)
end

function M.setup(config)
	setup_custom_modes()

	config.keys = config.keys or {}
	local modal_keys = {
		{
			key = "u",
			mods = "CTRL|SHIFT",
			action = modal.activate_mode("UI"),
		},
		{
			key = "c",
			mods = "CTRL|SHIFT",
			action = modal.activate_mode("Copy"),
		},
		{
			key = "n",
			mods = "CTRL|SHIFT",
			action = modal.activate_mode("Scroll"),
		},
	}

	for _, key in ipairs(modal_keys) do
		table.insert(config.keys, key)
	end

	config.key_tables = modal.key_tables

	return config
end

return M

