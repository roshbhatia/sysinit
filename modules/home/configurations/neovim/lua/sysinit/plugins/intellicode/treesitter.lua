local M = {}

local filetypes = {
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
  "jsonc",
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
}

M.plugins = {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    branch = "main",
    lazy = false,
    opts = {
      highlight = {
        enable = true,
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "gnn",
          node_incremental = "grn",
          scope_incremental = "grc",
          node_decremental = "grm",
        },
      },
      ensure_installed = filetypes,
    },
    config = function(_, opts)
      require("nvim-treesitter").setup(opts)

      vim.filetype.add({
        extension = {
          gotmpl = "gotmpl",
          ["yaml.tmpl"] = "yaml",
          ["yaml.tpl"] = "yaml",
          ["yml.tmpl"] = "yaml",
          ["yml.tpl"] = "yaml",
        },
        pattern = {
          [".*/templates/.*%.tpl"] = "helm",
          [".*/templates/.*%.ya?ml"] = "helm",
          ["helmfile.*%.ya?ml"] = "helm",
          -- Crossplane composition patterns
          [".*composition.*%.ya?ml"] = "yaml",
          [".*function.*%.ya?ml"] = "yaml",
          -- Files containing Crossplane API versions
          [".*crossplane%.io.*%.ya?ml"] = "yaml",
          [".*fn%.crossplane%.io.*%.ya?ml"] = "yaml",
          -- Kustomize patterns
          ["kustomization%.ya?ml"] = "yaml",
          [".*kustomize.*%.ya?ml"] = "yaml",
          -- Helm values files
          ["values.*%.ya?ml"] = "yaml",
          [".*values%.ya?ml"] = "yaml",
          ["Chart%.ya?ml"] = "yaml",
          -- Additional patterns for files with Go templating
          [".*%.gotmpl%.ya?ml"] = "yaml",
          [".*%.tpl%.ya?ml"] = "yaml",
        },
      })

      for _, ft in ipairs(filetypes) do
        vim.api.nvim_create_autocmd("FileType", {
          pattern = ft,
          callback = function()
            local ok = pcall(vim.treesitter.start)
            if not ok then
              vim.cmd("syntax on")
            end
          end,
        })
      end
    end,
  },
}

return M
