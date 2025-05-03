-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/stevearc/conform.nvim/master/doc/conform.txt"
local plugin_family = {}

M.plugins = {{
    "stevearc/conform.nvim",
    event = "VeryLazy",
    dependencies = {"mason.nvim"},
    config = function()
        local conform = require("conform")
        local util = require("conform.util")

        -- Format toggle state storage
        vim.g.format_state = {
            global = true, -- Global toggle state
            buffer = {}, -- Buffer-specific toggle: buffer_number -> boolean
            filetype = {}, -- Filetype-specific toggle: filetype -> boolean
            workspace = {}, -- Workspace-specific toggle: workspace_path -> boolean
            extension = {} -- Extension-specific toggle: extension -> boolean
        }

        -- Helper function to check if formatter is available
        local function formatter_exists(formatter_name)
            if formatter_name == "prettierd" or formatter_name == "prettier" then
                return util.find_executable({"prettierd", "prettier"}) ~= nil
            else
                return util.find_executable(formatter_name) ~= nil
            end
        end

        -- Helper function to check missing formatters and notify only once
        local missing_formatters_notified = {}
        local function check_and_notify_missing_formatters(formatters)
            if type(formatters) == "string" then
                formatters = {formatters}
            end

            for _, formatter in ipairs(formatters) do
                if type(formatter) == "string" and not missing_formatters_notified[formatter] then
                    if not formatter_exists(formatter) then
                        vim.notify("Formatter '" .. formatter .. "' not found. Please install it.", vim.log.levels.WARN)
                        missing_formatters_notified[formatter] = true
                    end
                end
            end
        end

        -- Helper function to filter available formatters
        local function get_available_formatters(formatters)
            if type(formatters) == "string" then
                return formatter_exists(formatters) and formatters or nil
            end

            local result = {}
            for _, formatter in ipairs(formatters) do
                if type(formatter) == "string" then
                    if formatter_exists(formatter) then
                        table.insert(result, formatter)
                    end
                elseif type(formatter) == "table" then
                    local available = {}
                    for _, f in ipairs(formatter) do
                        if formatter_exists(f) then
                            table.insert(available, f)
                        end
                    end
                    if #available > 0 then
                        table.insert(result, available)
                    end
                end
            end

            return #result > 0 and result or nil
        end

        -- Define formatters by filetype
        local formatters_by_ft = {
            lua = {"stylua"},
            python = {"black"},
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
        }

        -- Check for missing formatters on startup
        for _, formatters in pairs(formatters_by_ft) do
            check_and_notify_missing_formatters(formatters)
        end

        -- Filter formatters_by_ft to include only available formatters
        local available_formatters_by_ft = {}
        for ft, formatters in pairs(formatters_by_ft) do
            local available = get_available_formatters(formatters)
            if available then
                available_formatters_by_ft[ft] = available
            end
        end

        -- Check if formatting is enabled for the current buffer
        local function is_format_enabled(bufnr)
            local buffer_num = bufnr or vim.api.nvim_get_current_buf()
            local filetype = vim.bo[buffer_num].filetype
            local extension = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buffer_num), ":e")
            local workspace = vim.fn.getcwd()

            -- Check buffer-specific setting
            if vim.g.format_state.buffer[buffer_num] ~= nil then
                return vim.g.format_state.buffer[buffer_num]
            end

            -- Check extension-specific setting
            if extension ~= "" and vim.g.format_state.extension[extension] ~= nil then
                return vim.g.format_state.extension[extension]
            end

            -- Check filetype-specific setting
            if vim.g.format_state.filetype[filetype] ~= nil then
                return vim.g.format_state.filetype[filetype]
            end

            -- Check workspace-specific setting
            if vim.g.format_state.workspace[workspace] ~= nil then
                return vim.g.format_state.workspace[workspace]
            end

            -- Fall back to global setting
            return vim.g.format_state.global
        end

        conform.setup({
            formatters_by_ft = available_formatters_by_ft,

            -- Format command configuration
            format_on_save = function(bufnr)
                -- Check if formatting is enabled for this buffer
                if not is_format_enabled(bufnr) then
                    return
                end

                -- Only format specific file types
                local file_type = vim.bo[bufnr].filetype
                local formatters = available_formatters_by_ft[file_type]
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

                -- Continue saving if formatting fails
                return {
                    timeout_ms = 500,
                    lsp_fallback = true,
                    quiet = true -- Don't show errors from the formatter itself
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
            },

            -- Don't show error notifications from formatters
            notify_on_error = false
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
                range = range,
                quiet = true -- Don't show errors
            })
        end, {
            range = true
        })

        -- Toggle Format On Save with scope options
        vim.api.nvim_create_user_command("ToggleFormatOnSave", function(args)
            local scope = args.args

            -- Default to global scope if no argument provided
            if scope == "" then
                scope = "global"
            end

            if scope == "global" then
                vim.g.format_state.global = not vim.g.format_state.global
                local status = vim.g.format_state.global and "enabled" or "disabled"
                vim.notify(string.format("Format on save %s globally", status), vim.log.levels.INFO)

            elseif scope == "buffer" or scope == "file" then
                local bufnr = vim.api.nvim_get_current_buf()
                vim.g.format_state.buffer[bufnr] = not (vim.g.format_state.buffer[bufnr] or vim.g.format_state.global)
                local status = vim.g.format_state.buffer[bufnr] and "enabled" or "disabled"
                vim.notify(string.format("Format on save %s for current buffer", status), vim.log.levels.INFO)

            elseif scope == "filetype" or scope == "ft" then
                local filetype = vim.bo.filetype
                vim.g.format_state.filetype[filetype] = not (vim.g.format_state.filetype[filetype] or
                                                            vim.g.format_state.global)
                local status = vim.g.format_state.filetype[filetype] and "enabled" or "disabled"
                vim.notify(string.format("Format on save %s for filetype '%s'", status, filetype), vim.log.levels.INFO)

            elseif scope == "extension" or scope == "ext" then
                local extension = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":e")
                if extension ~= "" then
                    vim.g.format_state.extension[extension] =
                        not (vim.g.format_state.extension[extension] or vim.g.format_state.global)
                    local status = vim.g.format_state.extension[extension] and "enabled" or "disabled"
                    vim.notify(string.format("Format on save %s for extension '.%s'", status, extension),
                        vim.log.levels.INFO)
                else
                    vim.notify("Current file has no extension", vim.log.levels.WARN)
                end

            elseif scope == "workspace" or scope == "cwd" then
                local workspace = vim.fn.getcwd()
                vim.g.format_state.workspace[workspace] = not (vim.g.format_state.workspace[workspace] or
                                                              vim.g.format_state.global)
                local status = vim.g.format_state.workspace[workspace] and "enabled" or "disabled"
                vim.notify(string.format("Format on save %s for workspace '%s'", status, workspace), vim.log.levels.INFO)

            else
                vim.notify(string.format("Unknown scope '%s'. Use global, buffer, filetype, extension, or workspace",
                    scope), vim.log.levels.ERROR)
            end
        end, {
            nargs = "?",
            complete = function(ArgLead, CmdLine, CursorPos)
                return vim.tbl_filter(function(s)
                    return string.match(s, "^" .. ArgLead)
                end, {"global", "buffer", "file", "filetype", "ft", "extension", "ext", "workspace", "cwd"})
            end
        })

        -- Add command to show formatting status
        vim.api.nvim_create_user_command("FormatStatus", function()
            local bufnr = vim.api.nvim_get_current_buf()
            local filetype = vim.bo[bufnr].filetype
            local extension = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":e")
            local workspace = vim.fn.getcwd()

            local status_lines = {"Formatting Status:",
                                  string.format("  Global: %s", vim.g.format_state.global and "enabled" or "disabled"),
                                  string.format("  Current buffer (#%d): %s", bufnr,
                vim.g.format_state.buffer[bufnr] == nil and "using default" or
                    (vim.g.format_state.buffer[bufnr] and "enabled" or "disabled")),
                                  string.format("  Filetype '%s': %s", filetype,
                vim.g.format_state.filetype[filetype] == nil and "using default" or
                    (vim.g.format_state.filetype[filetype] and "enabled" or "disabled"))}

            if extension ~= "" then
                table.insert(status_lines,
                    string.format("  Extension '.%s': %s", extension,
                        vim.g.format_state.extension[extension] == nil and "using default" or
                            (vim.g.format_state.extension[extension] and "enabled" or "disabled")))
            end

            table.insert(status_lines,
                string.format("  Workspace '%s': %s", workspace,
                    vim.g.format_state.workspace[workspace] == nil and "using default" or
                        (vim.g.format_state.workspace[workspace] and "enabled" or "disabled")))

            table.insert(status_lines, string.format("  Current effective status: %s",
                is_format_enabled(bufnr) and "enabled" or "disabled"))

            vim.notify(table.concat(status_lines, "\n"), vim.log.levels.INFO)
        end, {})
    end
}}

return plugin_family
