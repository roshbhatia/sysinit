local M = {}

local function get_config_path()
	local home = vim.fn.expand("~")
	return home .. "/.sysinit.nvim.conf.yaml"
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
		dual_boost = {},
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
	local ok, yaml = pcall(require, "yaml")
	if not ok then
		vim.notify("YAML parser not available (install lua-yaml)", vim.log.levels.WARN)
		return default_config()
	end

	local path = get_config_path()
	local f = io.open(path, "r")
	if not f then
		return default_config()
	end

	local content = f:read("*a")
	f:close()
	local ok2, parsed = pcall(yaml.load, content)
	if not ok2 or type(parsed) ~= "table" then
		vim.notify("Malformed ~/.sysinit.nvim.conf.yaml, using defaults", vim.log.levels.WARN)
		return default_config()
	end

	return deep_merge(default_config(), parsed)
end

return M

