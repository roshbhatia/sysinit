-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/stevearc/conform.nvim/master/doc/conform.txt"
local M = {}

M.plugins = {{
    "stevearc/conform.nvim",
    event = "VeryLazy", -- Load lazily
    dependencies = {"mason.nvim"},
    config = function()
        local conform = require("conform")

        -- Enable format on save globally by default (can be toggled)
        vim.g.format_on_save = true

        conform.setup({
            formatters_by_ft = {
                lua = {"stylua"},
                python = {"isort", "black"},
                javascript = {{"prettierd", "prettier"}},
                typescript = {{"prettierd", "prettier"}},
                javascriptreact = {{"prettierd", "prettier"}},
                typescriptreact = {{"prettierd", "prettier"}},
                go = {"goimports", "gofmt"},
                json = {{"prettierd", "prettier"}},
                jsonc = {{"prettierd", "prettier"}},
                yaml = {{"prettierd", "prettier"}},
                markdown = {{"prettierd", "prettier"}},
                ["markdown.mdx"] = {{"prettierd", "prettier"}},
                html = {{"prettierd", "prettier"}},
                css = {{"prettierd", "prettier"}},
                scss = {{"prettierd", "prettier"}},
                sh = {"shfmt"},
                bash = {"shfmt"},
                zsh = {"shfmt"},
                terraform = {"terraform_fmt"},
                rust = {"rustfmt"},
                toml = {"taplo"},
                nix = {"nixfmt"}
            },

            -- Format command configuration
            format_on_save = function(bufnr)
                if not vim.g.format_on_save then
                    return
                end

                -- Only format specific file types
                local file_type = vim.bo[bufnr].filetype
                local formatters = conform.formatters_by_ft[file_type]
                if not formatters or #formatters == 0 then
                    return
                end

                -- Avoid formatting large files
                local max_filesize = 100 * 1024 -- 100 KB
                local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(bufnr))
                if ok and stats and stats.size > max_filesize then
                    vim.notify("File too large for formatting on save", vim.log.levels.WARN)
                    return
                end

                -- Use the slow formatter only for user formatting
                return {
                    timeout_ms = 500,
                    lsp_fallback = true
                }
            end,

            -- Formatters configuration
            formatters = {
                stylua = {
                    prepend_args = {"--indent-type", "spaces", "--indent-width", "2"}
                },
                shfmt = {
                    prepend_args = {"-i", "2", "-ci"}
                }
            }
        })

        -- Format command
        vim.api.nvim_create_user_command("Format", function(args)
            local range = nil
            if args.count ~= -1 then
                range = {
                    start = {args.line1, 0},
                    ["end"] = {args.line2, 999999}
                }
            end
            conform.format({
                async = true,
                lsp_fallback = true,
                range = range
            })
        end, {
            range = true
        })

        local function toggle_format_on_save()
            vim.g.format_on_save = not vim.g.format_on_save
            if vim.g.format_on_save then
                vim.notify("Format on save enabled", vim.log.levels.INFO)
            else
                vim.notify("Format on save disabled", vim.log.levels.INFO)
            end
        end

        vim.api.nvim_create_user_command("ToggleFormatOnSave", toggle_format_on_save, {})
    end
}}

return M
