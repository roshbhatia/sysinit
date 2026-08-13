return {
  {
    "georgeguimaraes/review.nvim",
    version = "*",
    dependencies = { "esmuellert/codediff.nvim", "MunifTanjim/nui.nvim" },
    cmd = { "Review" },
    opts = {
      -- review.nvim's default is `readonly = true`, which maps `i`, `d`, `e`, and `F`
      -- to comment actions. That is safe in a scratch diff buffer and wrong here:
      -- codediff's inline mode puts the *real file* on the modified side, listed and
      -- modifiable, so `i` opened a comment popup instead of inserting and `d` deleted
      -- a comment instead of text. Edit mode moves those to `<localleader>c…` and hands
      -- the operators back.
      codediff = {
        readonly = false,
      },
      keymaps = {
        send_sidekick = false,
        -- Same reason, for the keys edit mode still leaves on bare letters. `c` and `d`
        -- are operators, `f` and `t` are motions, and `q` records a macro. A review is
        -- not a mode the owner is trapped in: they read a diff and then fix the thing
        -- they just read, in the same buffer.
        list_comments = "<localleader>cl",
        export_clipboard = "<localleader>cy",
        toggle_file_panel = "<localleader>cF",
        toggle_readonly = "<localleader>cr",
        show_help = "<localleader>c?",
        close = false,
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
      -- It breaks `<leader>dd` and `<leader>dR` identically, which is why the guard
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
        -- Declared on this spec, not on codediff's, because lazy loads only the spec
        -- the key belongs to. review.nvim lists codediff as a dependency, so this
        -- loads both and the diff arrives with its comment layer; the same key on the
        -- codediff spec loaded codediff alone and opened a diff nothing could annotate.
        --
        -- Was a bare `<Cmd>Review<CR>`, which made review.nvim resolve its own root
        -- with `git rev-parse` in the process cwd (`lua/review/storage.lua:18`) and
        -- so review exactly one repository. It now takes the same path the scoped
        -- review takes, so the two agree about what is under review.
        "<leader>dd",
        function()
          require("harness.api").review_workspace()
        end,
        desc = "Review: annotate workspace diff",
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
