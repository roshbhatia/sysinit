local M = {}

M.plugins = {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		branch = "master",
		lazy = false,
		opts = {
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = false,
			},
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "gnn", -- set to `false` to disable one of the mappings
					node_incremental = "grn",
					scope_incremental = "grc",
					node_decremental = "grm",
				},
			},
			sync_install = true,
			ensure_installed = {
				"bash",
				"c",
				"comment",
				"css",
				"csv",
				"cue",
				"diff",
				"dockerfile",
				"git_config",
				"git_rebase",
				"gitattributes",
				"gitcommit",
				"gitignore",
				"go",
				"gomod",
				"gosum",
				"gotmpl",
				"gowork",
				"hcl",
				"helm",
				"html",
				"java",
				"javascript",
				"jinja",
				"jinja_inline",
				"jq",
				"jsdoc",
				"json",
				"jsonc",
				"lua",
				"luadoc",
				"luap",
				"markdown",
				"markdown_inline",
				"nix",
				"python",
				"query",
				"regex",
				"ruby",
				"rust",
				"scss",
				"terraform",
				"toml",
				"tsv",
				"typescript",
				"vim",
				"vimdoc",
				"xml",
				"yaml",
			},
		},
		config = function(_, opts)
			require("nvim-treesitter.configs").setup(opts)
			vim.cmd("TSInstall all")

			vim.api.nvim_create_autocmd("WinEnter", {
				callback = function()
					local config = vim.api.nvim_win_get_config(0)
					if config.relative == "" then
						local bufname = vim.api.nvim_buf_get_name(0)
						if bufname ~= "" and vim.fn.filereadable(bufname) == 1 then
							vim.cmd("e!")
							vim.cmd("syntax enable")
						end
					end
				end,
			})
		end,
	},
}

return M

