-- sysinit.nvim.doc-url="https://github.com/stevearc/aerial.nvim"
local plugin_spec = {}

M.plugins = {{
    "stevearc/aerial.nvim",
    lazy = false,
    dependencies = {"nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons"},
    config = function()
        require("aerial").setup({
            -- Priority list of preferred backends for aerial
            backends = {"treesitter", "lsp", "markdown"},

            layout = {
                -- Control the width of the aerial window
                max_width = {40, 0.2}, -- 40 columns or 20% of editor width
                width = nil,
                min_width = 10,

                -- Determines the default direction to open the aerial window
                default_direction = "prefer_right",

                -- When symbols change, resize the aerial window
                resize_to_content = true
            },

            -- Show box drawing characters for the tree hierarchy
            show_guides = true,

            -- Customize the characters used when show_guides = true
            guides = {
                mid_item = "├─",
                last_item = "└─",
                nested_top = "│ ",
                whitespace = "  "
            },

            -- Set default symbol icons to use patched font icons
            nerd_font = "auto",

            -- Keymaps in aerial window
            keymaps = {
                ["<CR>"] = "actions.jump",
                ["<2-LeftMouse>"] = "actions.jump",
                ["<C-v>"] = "actions.jump_vsplit",
                ["<C-s>"] = "actions.jump_split",
                ["p"] = "actions.scroll",
                ["{"] = "actions.prev",
                ["}"] = "actions.next",
                ["[["] = "actions.prev_up",
                ["]]"] = "actions.next_up",
                ["q"] = "actions.close",
                ["o"] = "actions.tree_toggle",
                ["O"] = "actions.tree_toggle_recursive",
                ["l"] = "actions.tree_open",
                ["h"] = "actions.tree_close"
            },

            -- Filter symbols display
            filter_kind = {"Class", "Constructor", "Enum", "Function", "Interface", "Module", "Method", "Struct"},

            -- Jump to symbol in source window when cursor moves
            autojump = false,

            -- When true, aerial will automatically close after jumping to a symbol
            close_on_select = false,

            -- Run this command after jumping to a symbol
            post_jump_cmd = "normal! zz",

            -- Automatically open aerial when entering supported buffers
            open_automatic = false
        })
    end
}}

function plugin_spec.setup()
    -- Command to navigate to the most important symbols in a file
    vim.api.nvim_create_user_command("OutlineFind", function()
        -- Check if aerial is available
        local aerial_status, aerial = pcall(require, 'aerial')
        if not aerial_status then
            vim.notify("aerial.nvim not available", vim.log.levels.ERROR)
            return
        end

        -- Open Telescope with aerial if available
        local telescope_status, telescope = pcall(require, 'telescope')
        if telescope_status and telescope.extensions and telescope.extensions.aerial then
            telescope.extensions.aerial.aerial()
        else
            -- Fallback to regular aerial navigation
            aerial.nav_toggle()
        end
    end, {})

    -- Create a helper command to toggle focus on aerial window
    vim.api.nvim_create_user_command("OutlineFocus", function()
        local aerial_status, aerial = pcall(require, 'aerial')
        if not aerial_status then
            vim.notify("aerial.nvim not available", vim.log.levels.ERROR)
            return
        end

        if aerial.is_open() then
            aerial.focus()
        else
            aerial.open()
            aerial.focus()
        end
    end, {})
end

return plugin_spec
