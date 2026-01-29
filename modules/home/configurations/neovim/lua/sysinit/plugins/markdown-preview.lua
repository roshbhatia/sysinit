return {
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle" },
    build = "cd app && yarn install --force --pure-lockfile",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    ft = {
      "markdown",
    },
    keys = {
      {
        "<localleader>p",
        "<cmd>MarkdownPreviewToggle<cr>",
        desc = "Toggle preview",
        ft = "markdown",
      },
    },
  },
}
