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
      -- The same mismatch, second site. `review/hooks.lua:68` hands the record to
      -- `vim.fn.fnamemodify(path, ":p")` inside `relativize_path`, which throws
      -- `E731: Using a Dictionary as a String`. It is reached from `marks.refresh`
      -- through `hooks.get_paths`, so it fires on every refresh rather than once,
      -- and the comment layer creates its augroup and then cannot place a mark.
      --
      -- Patched here rather than at codediff's `lifecycle.get_paths`, which is where
      -- the record originates, because codediff's own `gf` handler reads
      -- `ref.absolute` off that return value (`ui/view/actions/panes.lua:85-91`).
      -- Making it a string to satisfy review.nvim would break the plugin it came
      -- from. Unwrapping at the argument satisfies both.
      local fnamemodify = vim.fn.fnamemodify
      vim.fn.fnamemodify = function(path, mods)
        if type(path) == "table" then
          path = path.absolute or path.relative or ""
        end
        return fnamemodify(path, mods)
      end

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
      {
        -- Was a bare `<Cmd>Review<CR>`, which made review.nvim resolve its own root
        -- with `git rev-parse` in the process cwd (`lua/review/storage.lua:18`) and
        -- so review exactly one repository. It now takes the same path the scoped
        -- review takes, so the two agree about what is under review.
        "<leader>dr",
        function()
          require("harness.api").review_workspace()
        end,
        desc = "Review: annotate workspace diff",
      },
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
