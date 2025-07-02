local M = {}

local function get_config_path()
	local home = vim.fn.expand("~")
	return home .. "/.sysinit.nvim.conf.json"
end

local function default_config()
	return {
		copilot = {
			enabled = true,
		},
		avante = {
			provider = "copilot",
			providers = {
				copilot = {
					model = "gpt-4.1",
				},
			},
		},
		goose = {
			providers = {
				github_copilot = {
					"github_copilot/gemini-2.0-flash-001",
					"github_copilot/gpt-4.1",
					"github_copilot/claude-3.7-sonnet",
					"github_copilot/claude-3.5-sonnet",
				},
			},
		},
	}
end

local function deep_merge(defaults, overrides)
	for k, v in pairs(overrides) do
		if type(v) == "table" and type(defaults[k]) == "table" then
			defaults[k] = deep_merge(defaults[k], v)
		else
			defaults[k] = v
		end
	end
	return defaults
end

function M.load_config()
	local path = get_config_path()
	local f = io.open(path, "r")
	if not f then
		return default_config()
	end

	local content = f:read("*a")
	f:close()
	local ok2, parsed = pcall(vim.fn.json_decode, content)
	if not ok2 or type(parsed) ~= "table" then
		vim.notify("Malformed ~/.sysinit.nvim.conf.json, using defaults", vim.log.levels.WARN)
		return default_config()
	end

	return deep_merge(default_config(), parsed)
end

return M
