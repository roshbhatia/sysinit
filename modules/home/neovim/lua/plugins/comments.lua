return {
  {
    "terrortylor/nvim-comment",
    config = function()
      require("nvim_comment").setup({
        line_mapping = "<leader>cl", -- Remap to avoid overlap
        operator_mapping = "<leader>c", -- Remap to avoid overlap
      })
    end,
  },
}
