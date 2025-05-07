local M = {}

M.plugins = {
    {
        'VonHeikemen/fine-cmdline.nvim',
        event = "VeryLazy",
        dependencies = {'MunifTanjim/nui.nvim'},
        config = function()
            require('fine-cmdline').setup({
                popup = {
                    position = {
                        row = "50%",
                        col = "50%",
                    },
                    size = {
                        width = "60%",
                    },
                    border = {
                        style = "rounded",
                    },
                    win_options = {
                        winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder",
                    },
                },
                hooks = {
                    before_mount = function(input)
                        -- This runs before the input field is rendered
                    end,
                    after_mount = function(input)
                        -- This runs after the input field is rendered
                        vim.cmd("set winblend=10") -- Add some transparency
                    end,
                    set_keymaps = function(imap, feedkeys)
                        -- Keymaps here will override the default keymaps
                        imap("<Esc>", function()
                            require('fine-cmdline').close()
                        end)
                        imap("<Up>", function() 
                            feedkeys("<C-p>")
                        end)
                        imap("<Down>", function() 
                            feedkeys("<C-n>")
                        end)
                    end,
                }
            })
            
            -- Replace the default command line with fine-cmdline
            vim.api.nvim_set_keymap('n', ':', '<cmd>FineCmdline<CR>', { noremap = true })
        end
    }
}

return M