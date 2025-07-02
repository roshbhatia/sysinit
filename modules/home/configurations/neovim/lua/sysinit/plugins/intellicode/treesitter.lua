local M = {}

M.plugins = {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		branch = "master",
		lazy = false,
		opts = {
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "gnn",
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
			local parser_config = require("nvim-treesitter.parsers").get_parser_configs()

			---@diagnostic disable-next-line: inject-field
			parser_config.gotmpl = {
				install_info = {
					url = "https://github.com/ngalaiko/tree-sitter-go-template",
					files = { "src/parser.c" },
				},
				filetype = "gotmpl",
				used_by = { "gohtmltmpl", "gotexttmpl", "gotmpl", "yaml" },
			}
			require("nvim-treesitter.configs").setup(opts)

			-- Auto-sync and update the queries
			require("nvim-treesitter.install").update({ with_sync = true })
			vim.cmd([[hi def link @go_template Identifier]])
		end,
	},
}

return M
