local M = {}
local config_path = vim.fn.stdpath("config")

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
			highlight = {
				enable = true,
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
			parser_config.gotmpl = {
				install_info = {
					url = "https://github.com/ngalaiko/tree-sitter-go-template",
					files = { "src/parser.c" },
				},
				filetype = "gotmpl",
				used_by = { "gohtmltmpl", "gotexttmpl", "gotmpl", "yaml" },
			}

			require("nvim-treesitter.configs").setup(opts)

			local crossplane_queries = {
				injections = [[
                ((block_scalar) @injection.content
                        (#contains? @injection.content "{{")
                        (#set! injection.language "gotmpl"))
                ((plain_scalar) @injection.content
                        (#contains? @injection.content "{{")
                        (#set! injection.language "gotmpl"))
                ]],
				highlights = [[
                (block_mapping_pair
                        key: (flow_node (plain_scalar) @keyword)
                        value: (flow_node (plain_scalar) @string))
                ((block_scalar) @string
                        (#contains? @string "{{"))
                ((plain_scalar) @string
                        (#contains? @string "{{"))
                ]],
			}

			local taskfile_queries = {
				injections = [[
                ((block_scalar) @injection.content
                        (#contains? @injection.content "#!/usr/bin/env bash")
                        (#set! injection.language "bash"))
                ]],
			}

			local function is_crossplane_yaml(buf)
				local lines = vim.api.nvim_buf_get_lines(buf, 0, 10, false)
				for _, line in ipairs(lines) do
					if line:match("apiVersion:") or line:match("kind:") then
						return true
					end
				end
				return false
			end

			vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
				pattern = { "composition.yaml", "definition.yaml" },
				callback = function(args)
					if is_crossplane_yaml(args.buf) then
						for group, content in pairs(crossplane_queries) do
							vim.treesitter.query.set("yaml", group, content, args.buf)
						end

						vim.cmd("redraw!")
					end
				end,
			})

			vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
				pattern = "Taskfile.yml",
				callback = function(args)
					for group, content in pairs(taskfile_queries) do
						vim.treesitter.query.set("yaml", group, content, args.buf)
					end
				end,
			})
		end,
	},
}

return M
