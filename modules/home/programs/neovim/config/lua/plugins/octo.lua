return {
  {
    "pwntester/octo.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "folke/snacks.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    cmd = "Octo",
    opts = {
      picker = "snacks",
      enable_builtin = true,
      default_merge_method = "squash",
      default_delete_branch = true,
      reviews = { auto_show_threads = true },
      pull_requests = { use_branch_name_as_title = true },
      mappings = {
        issue = {
          reload = { lhs = "<localleader>R", desc = "reload issue" },
          open_in_browser = { lhs = "<localleader>ob", desc = "open in browser" },
          copy_url = { lhs = "<localleader>oy", desc = "copy URL" },
        },
        pull_request = {
          reload = { lhs = "<localleader>R", desc = "reload PR" },
          open_in_browser = { lhs = "<localleader>ob", desc = "open in browser" },
          copy_url = { lhs = "<localleader>oy", desc = "copy URL" },
          copy_sha = { lhs = "<localleader>oe", desc = "copy commit SHA" },
          approve_review = { lhs = "<localleader>qa", desc = "approve PR" },
        },
        review_diff = {
          close_review_tab = { lhs = "<localleader>qq", desc = "close review" },
          copy_sha = { lhs = "<localleader>oe", desc = "copy commit SHA" },
        },
        file_panel = {
          close_review_tab = { lhs = "<localleader>qq", desc = "close review" },
        },
        review_thread = {
          close_review_tab = { lhs = "<localleader>qq", desc = "close review" },
        },
        submit_win = {
          approve_review = { lhs = "<localleader>a", desc = "approve review" },
          comment_review = { lhs = "<localleader>m", desc = "comment review" },
          request_changes = { lhs = "<localleader>r", desc = "request changes" },
          close_review_tab = { lhs = "<localleader>q", desc = "close review" },
        },
        workflow = {
          open_in_browser = { lhs = "<localleader>ob", desc = "open in browser" },
          copy_url = { lhs = "<localleader>oy", desc = "copy URL" },
          refresh_workflow = { lhs = "<localleader>R", desc = "refresh" },
          rerun_workflow = { lhs = "<localleader>wr", desc = "rerun workflow" },
          rerun_failed_workflow = { lhs = "<localleader>wf", desc = "rerun failed jobs" },
          cancel_workflow = { lhs = "<localleader>wx", desc = "cancel workflow" },
        },
        discussion = {
          open_in_browser = { lhs = "<localleader>ob", desc = "open in browser" },
          copy_url = { lhs = "<localleader>oy", desc = "copy URL" },
        },
      },
    },
    config = function(_, opts)
      require("octo").setup(opts)
      vim.treesitter.language.register("markdown", "octo")
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "octo",
        callback = function(ev)
          vim.keymap.set("i", "@", "@<C-x><C-o>", { silent = true, buffer = ev.buf })
          vim.keymap.set("i", "#", "#<C-x><C-o>", { silent = true, buffer = ev.buf })
        end,
      })
    end,
    keys = {
      { "<leader>gr", "<Cmd>Octo<CR>", desc = "GitHub" },
    },
  },
}
