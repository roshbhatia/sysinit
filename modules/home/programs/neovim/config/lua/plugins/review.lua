return {
  {
    "georgeguimaraes/review.nvim",
    version = "*",
    dependencies = { "esmuellert/codediff.nvim", "MunifTanjim/nui.nvim" },
    cmd = { "Review" },
    opts = {
      keymaps = {
        send_sidekick = false,
      },
    },
    config = function(_, opts)
      require("review").setup(opts)

      -- Upstream defect, live on review.nvim 8e4bc16 with codediff.nvim 31510a9:
      -- codediff's `explorer` session holds `{ absolute, relative }` in
      -- `session.original` and `session.modified`, where review.nvim still expects a
      -- path string. `hooks.set_buffer_filetype` guards nil and "" but not a table, so
      -- it hands one to `vim.filetype.match`, which throws inside `normalize_path`.
      -- The throw aborts `on_session_created` before it creates its augroup or its
      -- keymaps, so the diff opens with no comment layer and looks like a plain diff.
      -- It breaks `<leader>dr` and `<leader>dR` identically, which is why the guard
      -- sits here rather than beside the scoped open.
      --
      -- The record's own `absolute` field is what the caller meant, so detection still
      -- happens rather than being skipped. Remove this when review.nvim reads the
      -- record itself.
      local match = vim.filetype.match
      vim.filetype.match = function(args)
        if type(args) ~= "table" or args.filename == nil or type(args.filename) == "string" then
          return match(args)
        end
        local copy = {}
        for key, value in pairs(args) do
          copy[key] = value
        end
        copy.filename = type(args.filename) == "table" and args.filename.absolute or nil
        if type(copy.filename) ~= "string" then
          copy.filename = nil
          if copy.buf == nil then
            return nil
          end
        end
        return match(copy)
      end
    end,
    keys = {
      { "<leader>dr", "<Cmd>Review<CR>", desc = "Review: annotate working diff" },
      {
        -- Declared here rather than beside the watcher so lazy loads this plugin
        -- first: the scoped open attaches review.nvim to a codediff session, and a
        -- keymap that ran before the plugin existed would open a plain diff.
        "<leader>dR",
        function()
          require("harness.api").review_touched()
        end,
        desc = "Review: annotate only the files an agent wrote",
      },
      {
        "<leader>jR",
        function()
          require("harness.api").send_review()
        end,
        desc = "Harness: send review comments to active agent",
      },
    },
  },
}
