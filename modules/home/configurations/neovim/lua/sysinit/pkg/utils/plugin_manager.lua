local plugin_manager = {}

function plugin_manager.setup_package_manager()
	local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
	if not vim.loop.fs_stat(lazypath) then
		vim.fn.system({
			"git",
			"clone",
			"--filter=blob:none",
			"https://github.com/folke/lazy.nvim.git",
			"--branch=stable",
			lazypath,
		})
	end
	vim.opt.rtp:prepend(lazypath)
end

function plugin_manager.setup_plugins(modules)
	local specs = {}
	for _, M in ipairs(modules) do
		if M.plugins then
			for _, plugin in ipairs(M.plugins) do
				table.insert(specs, plugin)
			end
		end
	end

	local core_specs = {
		{
			"catppuccin/nvim",
			name = "catppuccin",
			lazy = false,
			priority = 1500,
			config = function()
				require("catppuccin").setup({
					flavour = "frappe",
					show_end_of_buffer = false,
					transparent_background = true,
					term_colors = true,
					styles = { comments = { "italic" } },
					integrations = {
						alpha = true,
						aerial = true,
						cmp = true,
						gitsigns = true,
						grug_far = true,
						mason = true,
						neotree = true,
						copilot_vim = true,
						dap = true,
						dap_ui = true,
						dropbar = { enabled = true },
						fzf = true,
						hop = true,
						native_lsp = {
							enabled = true,
						},
						nvim_notify = false,
						render_markdown = true,
						snacks = { enabled = true },
						telescope = { enabled = true },
						treesitter = true,
						lsp_trouble = true,
						which_key = true,
					},
				})

				vim.cmd.colorscheme("catppuccin")
			end,
		},
		{
			"vhyrro/luarocks.nvim",
			priority = 1000,
			dependencies = {
				"nvim-lua/plenary.nvim",
			},
			opts = {
				rocks_path = vim.fn.stdpath("data") .. "/luarocks",
				lua_path = vim.fn.stdpath("data")
					.. "/luarocks/share/lua/5.1/?.lua;"
					.. vim.fn.stdpath("data")
					.. "/luarocks/share/lua/5.1/?/init.lua",
				lua_cpath = vim.fn.stdpath("data") .. "/luarocks/lib/lua/5.1/?.so",
				create_dirs = true,
				install = {
					only_deps = false,
					flags = { "--local", "--force-config" },
				},
				show_progress = true,
				rocks = {
					"tiktoken_core",
				},
			},
		},
	}

	for _, spec in ipairs(specs) do
		table.insert(core_specs, spec)
	end

	require("lazy").setup({
		root = vim.fn.stdpath("data") .. "/lazy",
		lockfile = vim.fn.stdpath("data") .. "/lazy/lazy-lock.json",
		rocks = {
			enabled = true,
			root = vim.fn.stdpath("data") .. "/lazy-rocks",
		},
		spec = core_specs,
		performance = {
			rtp = {
				disabled_plugins = {
					"gzip",
					"matchit",
					"matchparen",
					"netrwPlugin",
					"tarPlugin",
					"tohtml",
					"tutor",
					"zipPlugin",
				},
			},
		},
		change_detection = {
			notify = false,
		},
		install = {
			colorscheme = { "catppuccin" },
		},
	})
end

return plugin_manager

