local M = {}

M.plugins = {
    "j-hui/fidget.nvim",
    lazy = false,
    dependenceis = {"nvim-telescope/telescope.nvim"},
    config = function()
        require("fidget").setup({})

        require("telescope").load_extension("fidget")
    end
}

return M
