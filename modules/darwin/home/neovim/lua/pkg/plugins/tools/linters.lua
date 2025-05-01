-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/mfussenegger/nvim-lint/master/doc/lint.txt"
local M = {}

M.plugins = {{
    "mfussenegger/nvim-lint",
    event = "VeryLazy",
    dependencies = {"mason.nvim", "echasnovski/mini.trailspace", "sQVe/sort.nvim"},
    config = function()
        -- Setup mini.trailspace for trailing whitespace handling
        require('mini.trailspace').setup()
        require("sort").setup()

        local lint = require("lint")

        local linters_by_ft = {
            javascript = {"eslint"},
            typescript = {"eslint"},
            javascriptreact = {"eslint"},
            typescriptreact = {"eslint"},
            go = {"golangcilint"},
            sh = {"shellcheck"},
            bash = {"shellcheck"},
            zsh = {"shellcheck"},
            json = {"jsonlint"},
            markdown = {"markdownlint"},
            terraform = {"tflint"}
        }
        lint.linters_by_ft = linters_by_ft

        lint.linters.pylint.args = {"--output-format=text", "--score=no",
                                    "--msg-template='{line}:{column}:{category}:{msg} ({symbol})'"}

        lint.linters.shellcheck.args = {"--format=gcc", "--external-sources", "--shell=bash"}

        -- Create augroup for linting
        local lint_augroup = vim.api.nvim_create_augroup("nvim_lint_augroup", {
            clear = true
        })

        -- Setup lint autocmd
        vim.api.nvim_create_autocmd({"BufWritePost", "BufEnter"}, {
            group = lint_augroup,
            callback = function()
                require("lint").try_lint()
            end
        })

        -- Create Lint command
        vim.api.nvim_create_user_command("Lint", function()
            require("lint").try_lint()
        end, {})

        -- Setup toggle for auto linting
        local auto_linting_enabled = true

        local function toggle_auto_lint()
            auto_linting_enabled = not auto_linting_enabled

            if auto_linting_enabled then
                vim.api.nvim_clear_autocmds({
                    group = lint_augroup
                })
                vim.api.nvim_create_autocmd({"BufWritePost", "BufEnter"}, {
                    callback = function()
                        require("lint").try_lint()
                    end,
                    group = lint_augroup
                })
                vim.notify("Automatic linting enabled", vim.log.levels.INFO)
            else
                vim.api.nvim_clear_autocmds({
                    group = lint_augroup
                })
                vim.notify("Automatic linting disabled", vim.log.levels.INFO)
            end
        end

        vim.api.nvim_create_user_command("ToggleAutoLint", toggle_auto_lint, {})

        -- Setup whitespace trimming functionality
        local whitespace_augroup = vim.api.nvim_create_augroup("whitespace_trim_augroup", {
            clear = true
        })
        local trim_whitespace_enabled = true

        -- Function to ensure file ends with exactly one newline
        local function ensure_trailing_newline()
            local last_line = vim.fn.line("$")
            local last_line_text = vim.fn.getline(last_line)

            if last_line_text ~= "" then
                -- Add newline if the last line is not empty
                vim.fn.append(last_line, "")
            elseif last_line > 1 and vim.fn.getline(last_line - 1) == "" then
                -- Remove extra empty lines at the end (keep only one)
                while last_line > 1 and vim.fn.getline(last_line - 1) == "" do
                    vim.api.nvim_buf_set_lines(0, last_line - 1, last_line, false, {})
                    last_line = last_line - 1
                end
            end
        end

        -- Function to trim trailing whitespace using mini.trailspace
        local function trim_trailing_whitespace()
            MiniTrailspace.trim()
        end

        -- Function to handle both operations
        local function trim_whitespace_and_ensure_newline()
            if not trim_whitespace_enabled then
                return
            end

            -- Save cursor position
            local cursor_pos = vim.fn.getpos(".")

            -- Trim whitespace and ensure newline
            trim_trailing_whitespace()
            ensure_trailing_newline()

            -- Restore cursor position
            vim.fn.setpos(".", cursor_pos)
        end

        -- Setup autocmd for trimming
        vim.api.nvim_create_autocmd("BufWritePre", {
            group = whitespace_augroup,
            callback = trim_whitespace_and_ensure_newline
        })

        -- Function to toggle whitespace trimming
        local function toggle_whitespace_trim()
            trim_whitespace_enabled = not trim_whitespace_enabled

            if trim_whitespace_enabled then
                vim.api.nvim_clear_autocmds({
                    group = whitespace_augroup
                })
                vim.api.nvim_create_autocmd("BufWritePre", {
                    group = whitespace_augroup,
                    callback = trim_whitespace_and_ensure_newline
                })
                vim.notify("Automatic whitespace trimming enabled", vim.log.levels.INFO)
            else
                vim.api.nvim_clear_autocmds({
                    group = whitespace_augroup
                })
                vim.notify("Automatic whitespace trimming disabled", vim.log.levels.INFO)
            end
        end

        -- Create command to toggle whitespace trimming
        vim.api.nvim_create_user_command("ToggleWhitespaceTrim", toggle_whitespace_trim, {})
    end
}}

return M
