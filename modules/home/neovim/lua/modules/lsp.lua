local M = {}

-- Define module dependencies
M.depends_on = { "keybindings" }

M.plugins = {
  -- LSP Configuration
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      -- Useful status updates for LSP
      "j-hui/fidget.nvim",
      "folke/neodev.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
  },
  
  -- Autocompletion
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-buffer", -- Buffer completions
      "hrsh7th/cmp-path", -- Path completions
      "hrsh7th/cmp-cmdline", -- Cmdline completions
      "saadparwaiz1/cmp_luasnip", -- Snippet completions
      "onsails/lspkind.nvim" -- VSCode-like pictograms
    },
  },
  
  -- Snippets
  {
    "L3MON4D3/LuaSnip",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
  },
  
  -- Formatting & linting
  {
    "jose-elias-alvarez/null-ls.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
  
  -- LSP symbol outline
  {
    "stevearc/aerial.nvim",
    opts = {
      attach_mode = "global",
      backends = { "lsp", "treesitter", "markdown", "man" },
      layout = {
        min_width = 30,
        default_direction = "prefer_right",
      },
      show_guides = true,
      filter_kind = false,
      guides = {
        mid_item = "├─",
        last_item = "└─",
        nested_top = "│ ",
        whitespace = "  ",
      },
      keymaps = {
        ["<CR>"] = "actions.jump",
        ["<C-v>"] = "actions.jump_vsplit",
        ["<C-s>"] = "actions.jump_split",
        ["p"] = "actions.scroll",
        ["<C-j>"] = "actions.down_and_scroll",
        ["<C-k>"] = "actions.up_and_scroll",
      },
    },
    keys = {
      { "<leader>lo", "<cmd>AerialToggle<CR>", desc = "LSP Outline" },
    },
  },
  
  -- Improved LSP UI
  {
    "glepnir/lspsaga.nvim",
    event = "LspAttach",
    opts = {
      lightbulb = {
        enable = false,
      },
      symbol_in_winbar = {
        enable = false,
      },
    },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
  },
}

-- LSP on_attach function to setup keymaps for each buffer
function M.on_attach(client, bufnr)
  -- Get keybindings module
  local core = require("core")
  local keybindings = core.get_module("keybindings")
  local state = require("core.state")
  
  -- Set keymap options
  local opts = { noremap = true, silent = true, buffer = bufnr }
  
  -- Register LSP keybindings
  keybindings.register_context_keymap("lsp_attached", "gd", "<cmd>Lspsaga goto_definition<CR>", 
    vim.tbl_deep_extend("force", opts, { desc = "Go to Definition" }))
    
  keybindings.register_context_keymap("lsp_attached", "gr", "<cmd>Lspsaga finder<CR>", 
    vim.tbl_deep_extend("force", opts, { desc = "Go to References" }))
    
  keybindings.register_context_keymap("lsp_attached", "gD", "<cmd>Lspsaga peek_definition<CR>", 
    vim.tbl_deep_extend("force", opts, { desc = "Peek Definition" }))
    
  keybindings.register_context_keymap("lsp_attached", "K", "<cmd>Lspsaga hover_doc<CR>", 
    vim.tbl_deep_extend("force", opts, { desc = "Hover Documentation" }))
    
  keybindings.register_context_keymap("lsp_attached", "<leader>lf", 
    function() vim.lsp.buf.format({ async = true }) end, 
    vim.tbl_deep_extend("force", opts, { desc = "Format" }))
    
  keybindings.register_context_keymap("lsp_attached", "<leader>la", "<cmd>Lspsaga code_action<CR>", 
    vim.tbl_deep_extend("force", opts, { desc = "Code Actions" }))
    
  keybindings.register_context_keymap("lsp_attached", "<leader>lr", "<cmd>Lspsaga rename<CR>", 
    vim.tbl_deep_extend("force", opts, { desc = "Rename" }))
    
  keybindings.register_context_keymap("lsp_attached", "<leader>ls", "<cmd>Lspsaga show_line_diagnostics<CR>", 
    vim.tbl_deep_extend("force", opts, { desc = "Show Line Diagnostics" }))
    
  keybindings.register_context_keymap("lsp_attached", "[d", "<cmd>Lspsaga diagnostic_jump_prev<CR>", 
    vim.tbl_deep_extend("force", opts, { desc = "Previous Diagnostic" }))
    
  keybindings.register_context_keymap("lsp_attached", "]d", "<cmd>Lspsaga diagnostic_jump_next<CR>", 
    vim.tbl_deep_extend("force", opts, { desc = "Next Diagnostic" }))
  
  -- Emit event for plugins that depend on LSP
  state.emit("lsp.attached", {
    client = client,
    bufnr = bufnr,
    client_name = client.name,
    filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
  })
end

-- Setup LSP servers
function M.setup_lsp_servers()
  local lspconfig = require("lspconfig")
  local capabilities = require("cmp_nvim_lsp").default_capabilities()
  
  -- Configure lua for Neovim development
  require("neodev").setup({})
  
  -- Lua
  lspconfig.lua_ls.setup({
    capabilities = capabilities,
    on_attach = M.on_attach,
    settings = {
      Lua = {
        diagnostics = {
          globals = { "vim" },
        },
        workspace = {
          library = {
            [vim.fn.expand("$VIMRUNTIME/lua")] = true,
            [vim.fn.stdpath("config") .. "/lua"] = true,
          },
        },
      },
    },
  })
  
  -- TypeScript/JavaScript
  lspconfig.tsserver.setup({
    capabilities = capabilities,
    on_attach = M.on_attach,
    filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  })
  
  -- Python
  lspconfig.pyright.setup({
    capabilities = capabilities,
    on_attach = M.on_attach,
  })
  
  -- Rust
  lspconfig.rust_analyzer.setup({
    capabilities = capabilities,
    on_attach = M.on_attach,
    settings = {
      ["rust-analyzer"] = {
        checkOnSave = {
          command = "clippy",
        },
      },
    },
  })
  
  -- Go
  lspconfig.gopls.setup({
    capabilities = capabilities,
    on_attach = M.on_attach,
  })
  
  -- HTML, CSS, JSON
  lspconfig.html.setup({
    capabilities = capabilities,
    on_attach = M.on_attach,
  })
  
  lspconfig.cssls.setup({
    capabilities = capabilities,
    on_attach = M.on_attach,
  })
  
  lspconfig.jsonls.setup({
    capabilities = capabilities,
    on_attach = M.on_attach,
  })
end

-- Setup completion
function M.setup_completion()
  local cmp = require("cmp")
  local luasnip = require("luasnip")
  local lspkind = require("lspkind")
  
  -- Load snippets
  require("luasnip.loaders.from_vscode").lazy_load()
  
  cmp.setup({
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },
    window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
      ["<C-b>"] = cmp.mapping.scroll_docs(-4),
      ["<C-f>"] = cmp.mapping.scroll_docs(4),
      ["<C-Space>"] = cmp.mapping.complete(),
      ["<C-e>"] = cmp.mapping.abort(),
      ["<CR>"] = cmp.mapping.confirm({ select = false }),
      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        else
          fallback()
        end
      end, { "i", "s" }),
      ["<S-Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { "i", "s" }),
    }),
    sources = cmp.config.sources({
      { name = "nvim_lsp" },
      { name = "luasnip" },
      { name = "buffer" },
      { name = "path" },
    }),
    formatting = {
      format = lspkind.cmp_format({
        mode = "symbol_text",
        maxwidth = 50,
        ellipsis_char = "...",
      }),
    },
  })
  
  -- Set up special configuration for command mode
  cmp.setup.cmdline(":", {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = "path" },
      { name = "cmdline" },
    }),
  })
  
  -- Set up for search mode
  cmp.setup.cmdline("/", {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = "buffer" },
    },
  })
end

-- Setup null-ls for formatting and linting
function M.setup_null_ls()
  local null_ls = require("null-ls")
  
  null_ls.setup({
    sources = {
      -- Formatting
      null_ls.builtins.formatting.prettier.with({
        filetypes = {
          "javascript", "javascriptreact", "typescript", "typescriptreact",
          "css", "scss", "html", "json", "yaml", "markdown", "graphql"
        },
      }),
      null_ls.builtins.formatting.black.with({ extra_args = { "--fast" } }),
      null_ls.builtins.formatting.stylua,
      
      -- Diagnostics
      null_ls.builtins.diagnostics.eslint,
      null_ls.builtins.diagnostics.flake8,
      
      -- Code actions
      null_ls.builtins.code_actions.gitsigns,
    },
    on_attach = M.on_attach,
  })
end

-- Setup LSP status indicator
function M.setup_fidget()
  require("fidget").setup({
    notification = {
      window = {
        winblend = 0,
      },
    },
  })
end

-- Configure LSP diagnostics
function M.setup_diagnostics()
  -- Set up diagnostic signs
  local signs = {
    { name = "DiagnosticSignError", text = "󰅙" },
    { name = "DiagnosticSignWarn", text = "󰀦" },
    { name = "DiagnosticSignHint", text = "󰌵" },
    { name = "DiagnosticSignInfo", text = "󰋼" },
  }
  
  for _, sign in ipairs(signs) do
    vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
  end
  
  vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    update_in_insert = false,
    underline = true,
    severity_sort = true,
    float = {
      focusable = false,
      style = "minimal",
      border = "rounded",
      source = "always",
      header = "",
      prefix = "",
    },
  })
end

-- Register test cases
local test = require("core.test")
test.register_test("lsp", function()
  local tests = {
    function()
      print("Testing LSP configuration...")
      -- Check if lspconfig is available
      local has_lspconfig = pcall(require, "lspconfig")
      assert(has_lspconfig, "lspconfig plugin should be available")
      return true, "LSP configuration is available"
    end,
    
    function()
      print("Testing completion setup...")
      local has_cmp = pcall(require, "cmp")
      assert(has_cmp, "nvim-cmp plugin should be available")
      return true, "Completion system is available"
    end,
  }
  
  for i, test_fn in ipairs(tests) do
    local success, msg = pcall(test_fn)
    if not success then
      return false, "Test " .. i .. " failed: " .. msg
    end
  end
  
  return true, "All LSP tests passed"
end)

-- Add verification steps
local verify = require("core.verify")
verify.register_verification("lsp", {
  {
    desc = "Check LSP server availability",
    command = "Open a Lua file and check :LspInfo",
    expected = "Should show lua_ls server attached",
  },
  {
    desc = "Test completion",
    command = "Type 'vim.' in a Lua file",
    expected = "Should show completion popup with Neovim API functions",
  },
  {
    desc = "Test code actions",
    command = "<leader>la on a diagnostics line",
    expected = "Should show code actions popup from LSP",
  },
  {
    desc = "Test symbol outline",
    command = "<leader>lo",
    expected = "Should toggle symbol outline panel with code structure",
  },
  {
    desc = "Test formatting",
    command = "<leader>lf",
    expected = "Should format the current buffer according to LSP settings",
  },
})

function M.setup()
  -- Set up LSP diagnostics config first
  M.setup_diagnostics()
  
  -- Set up components after plugins are loaded
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local bufnr = args.buf
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      M.on_attach(client, bufnr)
    end,
  })
  
  -- Lazily initialize LSP servers
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
      -- Start LSP server setup with delay to ensure all plugins are loaded
      vim.defer_fn(function()
        M.setup_lsp_servers()
        M.setup_completion()
        M.setup_null_ls()
        M.setup_fidget()
      end, 100)
    end,
  })
  
  -- Register aerial with the layout module
  local core = require("core")
  local layout = core.get_module("layout")
  if layout and layout.register_panel then
    layout.register_panel("outline", {
      open_cmd = "AerialToggle",
      position = "right",
      size = 30,
      icon = "󰙅",
      title = "Outline",
    })
  end
end

require("core").register("lsp", M)

return M