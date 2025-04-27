-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/folke/lazy.nvim/refs/heads/main/doc/lazy.nvim.txt"
local M = {}

function M.setup()
    require("lazy").setup({
        root = vim.fn.stdpath("data") .. "/lazy",
        lockfile = vim.fn.stdpath("data") .. "/lazy/lazy-lock.json",

        spec = {{
            "vhyrro/luarocks.nvim",
            priority = 1000,
            config = true,
            opts = {
                rocks = {}
            }
        }},

        performance = {
            rtp = {
                disabled_plugins = {"gzip", "matchit", "matchparen", "netrwPlugin", "tarPlugin", "tohtml", "tutor",
                                    "zipPlugin"}
            }
        },
        change_detection = {
            notify = false
        }
    })
end

return M
