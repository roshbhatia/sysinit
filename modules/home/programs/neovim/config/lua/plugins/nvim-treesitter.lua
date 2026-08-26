return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    branch = "main",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({})

      require("nvim-treesitter").install({
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
        "html",
        "java",
        "javascript",
        "jq",
        "jsdoc",
        "json",
        "lua",
        "luadoc",
        "luap",
        "nix",
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
      })

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("TreesitterSetup", { clear = true }),
        callback = function(args)
          local ft = args.match
          local buf = args.buf

          if ft == "markdown" or ft == "markdown_inline" then
            return
          end

          local line_count = vim.api.nvim_buf_line_count(buf)
          local file_size = vim.fn.getfsize(vim.api.nvim_buf_get_name(buf))
          if line_count > 5000 or file_size > 2 * 1024 * 1024 then
            return
          end

          local disable_ft = { "log", "txt", "csv", "json" }
          if vim.tbl_contains(disable_ft, ft) then
            return
          end

          pcall(vim.treesitter.start, buf)

          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    lazy = false,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        move = { set_jumps = true },
      })

      local move = require("nvim-treesitter-textobjects.move")
      local function map(lhs, method, capture, description)
        vim.keymap.set({ "n", "x", "o" }, lhs, function()
          move[method](capture, "textobjects")
        end, { desc = description })
      end

      map("]m", "goto_next_start", "@function.outer", "Next function start")
      map("]M", "goto_next_end", "@function.outer", "Next function end")
      map("[m", "goto_previous_start", "@function.outer", "Previous function start")
      map("[M", "goto_previous_end", "@function.outer", "Previous function end")
      map("]C", "goto_next_start", "@class.outer", "Next class start")
      map("[C", "goto_previous_start", "@class.outer", "Previous class start")
      map("]a", "goto_next_start", "@parameter.inner", "Next parameter start")
      map("]A", "goto_next_end", "@parameter.inner", "Next parameter end")
      map("[a", "goto_previous_start", "@parameter.inner", "Previous parameter start")
      map("[A", "goto_previous_end", "@parameter.inner", "Previous parameter end")
    end,
  },
}
