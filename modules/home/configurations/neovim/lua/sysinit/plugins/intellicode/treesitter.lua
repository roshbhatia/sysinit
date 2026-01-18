return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = "VimEnter",
    branch = "master",
    init = function(plugin)
      require("lazy.core.loader").add_to_rtp(plugin)
      require("nvim-treesitter.query_predicates")
    end,
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "bash",
          "c",
          "comment",
          "css",
          "csv",
          "cue",
          "diff",
          "dockerfile",
          "git_config",
          "git_rebase",
          "gitattributes",
          "gitcommit",
          "gitignore",
          "go",
          "gomod",
          "gosum",
          "gotmpl",
          "gowork",
          "hcl",
          "helm",
          "html",
          "java",
          "javascript",
          "jinja",
          "jinja_inline",
          "jq",
          "jsdoc",
          "json",
          "lua",
          "luadoc",
          "luap",
          "markdown",
          "markdown_inline",
          "nix",
          "nu",
          "python",
          "query",
          "regex",
          "ruby",
          "rust",
          "scss",
          "terraform",
          "toml",
          "tsv",
          "typescript",
          "vim",
          "vimdoc",
          "xml",
          "yaml",
        },
        sync_install = false,
        auto_install = true,
        ignore_install = {
          "org",
        },
        modules = {},
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
          disable = function(lang, buf)
            -- Disable treesitter for very large files
            local line_count = vim.api.nvim_buf_line_count(buf)
            local file_size = vim.fn.getfsize(vim.api.nvim_buf_get_name(buf))

            -- Disable for files > 5000 lines or > 2MB
            if line_count > 5000 or file_size > 2 * 1024 * 1024 then
              return true
            end

            -- Disable for certain filetypes that don't benefit much
            local disable_ft = { "log", "txt", "csv", "json" }
            return vim.tbl_contains(disable_ft, lang)
          end,
        },
        rainbow = {
          enable = true,
          extended_mode = true,
          max_file_lines = nil,
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "gx",
            node_incremental = "gx",
            scope_incremental = false,
            node_decremental = "gX",
          },
        },
        indent = {
          enable = true,
        },
        textobjects = {
          move = {
            enable = true,
            goto_next_start = {
              ["]m"] = "@function.outer",
              ["]c"] = "@class.outer",
              ["]a"] = "@parameter.inner",
            },
            goto_next_end = {
              ["]M"] = "@function.outer",
              ["]C"] = "@class.outer",
              ["]A"] = "@parameter.inner",
            },
            goto_previous_start = {
              ["[m"] = "@function.outer",
              ["[c"] = "@class.outer",
              ["[a"] = "@parameter.inner",
            },
            goto_previous_end = {
              ["[M"] = "@function.outer",
              ["[C"] = "@class.outer",
              ["[A"] = "@parameter.inner",
            },
          },
        },
      })

      -- Auto-fix treesitter highlighting if not active
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter" }, {
        group = vim.api.nvim_create_augroup("TreesitterHighlightFix", { clear = true }),
        callback = function(args)
          local buf = args.buf

          -- Skip if we've already tried to fix this buffer
          if vim.b[buf].treesitter_highlight_fixed then
            return
          end

          -- Only process real files
          local bufname = vim.api.nvim_buf_get_name(buf)
          if bufname == "" or vim.fn.filereadable(bufname) ~= 1 then
            return
          end

          -- Skip special buffer types
          local buftype = vim.bo[buf].buftype
          if buftype ~= "" and buftype ~= "acwrite" then
            return
          end

          -- Check if treesitter highlighting is active
          vim.defer_fn(function()
            if not vim.api.nvim_buf_is_valid(buf) then
              return
            end

            local has_ts = vim.treesitter.highlighter.active[buf] ~= nil
            if not has_ts then
              -- Mark that we've attempted to fix this buffer
              vim.b[buf].treesitter_highlight_fixed = true

              -- Reload the buffer to trigger treesitter
              pcall(vim.cmd.edit)
            else
              -- Highlighting is active, mark as fixed to skip future checks
              vim.b[buf].treesitter_highlight_fixed = true
            end
          end, 100)
        end,
      })
    end,
    keys = {
      {
        "gx",
        desc = "Selection init or increment",
      },
      {
        "gX",
        desc = "Selection decrement",
      },
    },
  },
}
