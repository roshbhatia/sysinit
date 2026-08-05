return {
  {
    "kevinhwang91/nvim-bqf",
    event = "VeryLazy",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      auto_resize_height = true,
      func_map = {
        split = "<localleader>s",
        vsplit = "<localleader>v",
        tabb = "",
        tabc = "",
      },
      preview = {
        auto_preview = false,
        win_height = 12,
        win_vheight = 12,
        winblend = 12,
        buf_label = true,
        should_preview_cb = function(bufnr)
          local filename = vim.api.nvim_buf_get_name(bufnr)
          local ok, stat = pcall(vim.uv.fs_stat, filename)
          return ok and stat and stat.size < 100 * 1024
        end,
      },
      show_title = {
        default = false,
      },
      filter = {
        fzf = {
          extra_opts = { "--bind", "ctrl-o:toggle-all", "--delimiter", "│" },
          action_for = {
            ["ctrl-v"] = "vsplit",
            ["ctrl-x"] = "split",
          },
        },
      },
    },
  },
}
