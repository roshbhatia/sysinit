
-- Init lazy plugin manager
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({
        'git', 'clone', '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git', '--branch=stable', lazypath
    })
end
vim.opt.rtp:prepend(lazypath)

-- Install external plugins
require('lazy').setup({
    -- File explorer/navigator
    {'stevearc/oil.nvim',
      opts = {
        default_file_explorer = true,
        view_options = {
          show_hidden = true,
        },
        keymaps = {
          ["g?"] = "actions.show_help",
          ["<CR>"] = "actions.select",
          ["<C-v>"] = "actions.select_vsplit",
          ["<C-s>"] = "actions.select_split",
          ["<C-t>"] = "actions.select_tab",
          ["<C-p>"] = "actions.preview",
          ["<C-c>"] = "actions.close",
          ["<C-r>"] = "actions.refresh",
          ["-"] = "actions.parent",
          ["_"] = "actions.open_cwd",
          ["`"] = "actions.cd",
          ["~"] = "actions.tcd",
          ["gs"] = "actions.change_sort",
          ["gx"] = "actions.open_external",
          ["g."] = "actions.toggle_hidden",
        },
        use_default_keymaps = true,
      },
      keys = {
        { "-", "<cmd>Oil<cr>", desc = "Open parent directory with Oil" },
      },
    },
    
    -- Colorschemes
    {'kepano/flexoki-neovim', name = 'flexoki', priority = 1000},
    {'catppuccin/nvim', name = 'catppuccin', priority = 1000, config = function()
        require('catppuccin').setup({
            flavour = 'mocha', -- Choose: latte, frappe, macchiato, mocha
            term_colors = true,
            transparent_background = false,
            dim_inactive = {
                enabled = true,
                percentage = 0.15,
            },
            integrations = {
                aerial = true,
                cmp = true,
                gitsigns = true,
                mason = true,
                nvimtree = true,
                telescope = true,
                treesitter = true,
                treesitter_context = true,
                which_key = true,
            },
        })
    end},
    {'folke/tokyonight.nvim', priority = 1000},
    
    -- Keystroke display
    {'folke/noice.nvim',
      event = "VeryLazy",
      dependencies = {
        'MunifTanjim/nui.nvim',
        'rcarriga/nvim-notify',
      },
    },
    
    -- Git integration
    {'lewis6991/gitsigns.nvim',
      opts = {
        signs = {
          add = { text = "│" },
          change = { text = "│" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
          untracked = { text = "┆" },
        },
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns
          
          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end
          
          -- Navigation
          map('n', ']c', function()
            if vim.wo.diff then return ']c' end
            vim.schedule(function() gs.next_hunk() end)
            return '<Ignore>'
          end, {expr=true})
          
          map('n', '[c', function()
            if vim.wo.diff then return '[c' end
            vim.schedule(function() gs.prev_hunk() end)
            return '<Ignore>'
          end, {expr=true})
          
          -- Actions
          map('n', '<leader>hs', gs.stage_hunk)
          map('n', '<leader>hr', gs.reset_hunk)
          map('v', '<leader>hs', function() gs.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
          map('v', '<leader>hr', function() gs.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
          map('n', '<leader>hS', gs.stage_buffer)
          map('n', '<leader>hu', gs.undo_stage_hunk)
          map('n', '<leader>hR', gs.reset_buffer)
          map('n', '<leader>hp', gs.preview_hunk)
          map('n', '<leader>hb', function() gs.blame_line{full=true} end)
          map('n', '<leader>tb', gs.toggle_current_line_blame)
          map('n', '<leader>hd', gs.diffthis)
          map('n', '<leader>hD', function() gs.diffthis('~') end)
          map('n', '<leader>td', gs.toggle_deleted)
        end
      }
    },
    
    -- File explorer
    {'nvim-tree/nvim-web-devicons', lazy = true},
    {'nvim-tree/nvim-tree.lua',
      version = '*',
      lazy = false,
      dependencies = {'nvim-tree/nvim-web-devicons'},
      keys = {
        { "<F2>", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file explorer" },
        { "<leader>pv", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file explorer" },
        { "<leader>pf", "<cmd>NvimTreeFindFile<CR>", desc = "Find file in explorer" },
      },
      opts = {
        on_attach = function(bufnr)
          local api = require('nvim-tree.api')
          
          local function opts(desc)
            return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
          end
          
          -- Default mappings
          api.config.mappings.default_on_attach(bufnr)
          
          -- Custom mappings
          vim.keymap.set('n', 'l', api.node.open.edit, opts('Open'))
          vim.keymap.set('n', 'h', api.node.navigate.parent_close, opts('Close Directory'))
          vim.keymap.set('n', 'v', api.node.open.vertical, opts('Open: Vertical Split'))
          vim.keymap.set('n', 's', api.node.open.horizontal, opts('Open: Horizontal Split'))
        end,
        filters = {
          dotfiles = false,
        },
        renderer = {
          group_empty = true,
          highlight_git = true,
          icons = {
            git_placement = "after",
            show = {
              file = true,
              folder = true,
              folder_arrow = true,
              git = true,
            },
          },
        },
        update_focused_file = {
          enable = true,
        },
        view = {
          width = 35,
        },
      },
    },
    
    -- Buffer management like VS Code tabs
    {'romgrk/barbar.nvim',
      dependencies = {
        'lewis6991/gitsigns.nvim',
        'nvim-tree/nvim-web-devicons'
      },
      init = function() vim.g.barbar_auto_setup = false end,
      opts = {
        animation = true,
        clickable = true,
        icons = {
          buffer_index = true,
          button = '',
          modified = {button = '●'},
          pinned = {button = '', filename = true},
          separator = {left = '▎', right = ''},
          inactive = {separator = {left = '▎', right = ''}},
        },
      },
      keys = {
        { '<leader>bp', '<Cmd>BufferPrevious<CR>', desc = 'Previous buffer' },
        { '<leader>bn', '<Cmd>BufferNext<CR>', desc = 'Next buffer' },
        { '<leader>bc', '<Cmd>BufferClose<CR>', desc = 'Close buffer' },
        { '<C-s>', '<Cmd>BufferPick<CR>', desc = 'Pick buffer' },
        { '<leader>1', '<Cmd>BufferGoto 1<CR>', desc = 'Go to buffer 1' },
        { '<leader>2', '<Cmd>BufferGoto 2<CR>', desc = 'Go to buffer 2' },
        { '<leader>3', '<Cmd>BufferGoto 3<CR>', desc = 'Go to buffer 3' },
        { '<leader>4', '<Cmd>BufferGoto 4<CR>', desc = 'Go to buffer 4' },
        { '<leader>5', '<Cmd>BufferGoto 5<CR>', desc = 'Go to buffer 5' },
        { '<leader>6', '<Cmd>BufferGoto 6<CR>', desc = 'Go to buffer 6' },
        { '<leader>7', '<Cmd>BufferGoto 7<CR>', desc = 'Go to buffer 7' },
        { '<leader>8', '<Cmd>BufferGoto 8<CR>', desc = 'Go to buffer 8' },
        { '<leader>9', '<Cmd>BufferGoto 9<CR>', desc = 'Go to buffer 9' },
        { '<leader>bb', '<Cmd>BufferOrderByBufferNumber<CR>', desc = 'Order by buffer number' },
        { '<leader>bd', '<Cmd>BufferOrderByDirectory<CR>', desc = 'Order by directory' },
        { '<leader>bl', '<Cmd>BufferOrderByLanguage<CR>', desc = 'Order by language' },
      },
    },
    
    -- Syntax highlighting and text objects
    {'nvim-treesitter/nvim-treesitter',
      build = ':TSUpdate',
      event = {'BufReadPost', 'BufNewFile'},
      cmd = {'TSUpdateSync', 'TSUpdate', 'TSInstall'},
      keys = {
        { '<leader>ts', '<cmd>TSModuleInfo<cr>', desc = 'Treesitter info' },
      },
      opts = {
        ensure_installed = {
          "bash", "c", "cpp", "go", "javascript", "json", "lua", "markdown", 
          "python", "rust", "terraform", "vim", "vimdoc", "yaml", "nix", "dockerfile",
          "hcl", "make", "toml"
        },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = '<CR>',
            node_incremental = '<CR>',
            scope_incremental = '<S-CR>',
            node_decremental = '<BS>',
          },
        },
      },
      config = function(_, opts)
        require('nvim-treesitter.configs').setup(opts)
      end,
    },
    {'nvim-treesitter/nvim-treesitter-textobjects',
      dependencies = {'nvim-treesitter/nvim-treesitter'},
      config = function()
        require('nvim-treesitter.configs').setup({
          textobjects = {
            select = {
              enable = true,
              lookahead = true,
              keymaps = {
                ["af"] = "@function.outer",
                ["if"] = "@function.inner",
                ["ac"] = "@class.outer",
                ["ic"] = "@class.inner",
                ["aa"] = "@parameter.outer",
                ["ia"] = "@parameter.inner",
              },
            },
            move = {
              enable = true,
              set_jumps = true,
              goto_next_start = {
                ["]f"] = "@function.outer",
                ["]c"] = "@class.outer",
              },
              goto_next_end = {
                ["]F"] = "@function.outer",
                ["]C"] = "@class.outer",
              },
              goto_previous_start = {
                ["[f"] = "@function.outer",
                ["[c"] = "@class.outer",
              },
              goto_previous_end = {
                ["[F"] = "@function.outer",
                ["[C"] = "@class.outer",
              },
            },
          },
        })
      end,
    },
    {'nvim-treesitter/nvim-treesitter-context',
      dependencies = {'nvim-treesitter/nvim-treesitter'},
      enabled = true,
      opts = {
        enable = true,
        max_lines = 3,
        min_window_height = 15,
        line_numbers = true,
        multiline_threshold = 5,
        trim_scope = 'outer',
        mode = 'topline',
      },
    },
    
    -- Session management like VS Code workspaces
    {'mhinz/vim-startify',
      lazy = false, -- Important! Don't load lazily
      priority = 9000, -- Load with extremely high priority
      init = function()
        -- Add these settings before plugin loads
        vim.g.startify_disable_at_vimenter = 0
        vim.g.startify_custom_header_quotes = {}
      end,
      config = function()
        vim.g.startify_session_autoload = 1
        vim.g.startify_session_persistence = 1
        vim.g.startify_session_delete_buffers = 1
        vim.g.startify_change_to_vcs_root = 1
        vim.g.startify_fortune_use_unicode = 1
        vim.g.startify_session_dir = '~/.config/nvim/sessions'
        vim.g.startify_lists = {
          { type = 'sessions',  header = {'   Sessions'} },
          { type = 'files',     header = {'   Recent Files'} },
          { type = 'dir',       header = {'   Current Directory: '..vim.fn.getcwd()} },
          { type = 'bookmarks', header = {'   Bookmarks'} },
          { type = 'commands',  header = {'   Commands'} },
        }
        vim.g.startify_commands = {
          { t = {'Open Terminal', 'ToggleTerm'} },
          { f = {'Find File', 'Telescope find_files'} },
          { g = {'Find Word', 'Telescope live_grep'} },
          { s = {'New Session', 'Startify'} },
        }
        vim.g.startify_bookmarks = {
          { c = '~/.config/nvim/init.lua' },
          { z = '~/.zshrc' },
        }
        
        -- Disable line numbers and sign column in Startify for clean ASCII art
        vim.g.startify_custom_indices = {}
        
        -- Let the init.lua handle Startify launch with proper number settings
      end,
      keys = {
        { '<F1>', '<cmd>Startify<CR>', desc = 'Open Startify' },
        { '<leader>ss', '<cmd>SSave<CR>', desc = 'Save session' },
        { '<leader>sl', '<cmd>SLoad<CR>', desc = 'Load session' },
        { '<leader>sd', '<cmd>SDelete<CR>', desc = 'Delete session' },
        { '<leader>sc', '<cmd>SClose<CR>', desc = 'Close session' },
      },
    },
    
    -- Mini-map / code preview
    {'gorbit99/codewindow.nvim',
      enabled = true,
      config = function()
        local has_treesitter = pcall(require, 'nvim-treesitter')
        if has_treesitter then
          require('codewindow').setup({
            auto_enable = true,
            use_treesitter = true,
            exclude_filetypes = {
              'help', 'dashboard', 'NvimTree', 'Trouble', 'TelescopePrompt', 'Float',
            },
          })
          vim.keymap.set('n', '<leader>mm', function()
            require('codewindow').toggle_minimap()
          end, { desc = 'Toggle minimap' })
        end
      end,
      dependencies = {'nvim-treesitter/nvim-treesitter'},
    },
    
    -- Command palette and search like VS Code
    {'gelguy/wilder.nvim',
      config = function()
        local wilder = require('wilder')
        wilder.setup({modes = {':', '/', '?'}})
        
        wilder.set_option('renderer', wilder.popupmenu_renderer(
          wilder.popupmenu_border_theme({
            highlights = {
              border = 'Normal', -- highlight to use for the border
            },
            border = 'rounded',
            max_height = '30%',
            min_width = '30%',
            prompt_position = 'top',
            reverse = 0,
          })
        ))
        
        wilder.set_option('pipeline', {
          wilder.branch(
            wilder.cmdline_pipeline(),
            wilder.search_pipeline()
          ),
        })
        
        -- Enable fuzzy matching for commands and files
        wilder.set_option('renderer', wilder.popupmenu_renderer(
          wilder.popupmenu_border_theme({
            highlights = {
              border = 'Normal',
              accent = wilder.make_hl('WilderAccent', 'Pmenu', {{a = 1}, {a = 1}, {foreground = '#f4468f'}}),
            },
            border = 'rounded',
            highlighter = wilder.basic_highlighter(),
            left = {' ', wilder.popupmenu_devicons()},
            right = {' ', wilder.popupmenu_scrollbar()},
          })
        ))
      end,
      dependencies = {'nvim-tree/nvim-web-devicons'},
    },
    
    -- Fuzzy finder and its extensions
    {'nvim-telescope/telescope.nvim',
      dependencies = {
        'nvim-lua/plenary.nvim',
        {'nvim-telescope/telescope-fzf-native.nvim', build = 'make'},
        'nvim-telescope/telescope-file-browser.nvim',
        'nvim-telescope/telescope-project.nvim',
        'nvim-telescope/telescope-ui-select.nvim',
        'Piotr1215/telescope-crossplane.nvim',
        'nvim-tree/nvim-web-devicons',
      },
      cmd = 'Telescope',
      keys = {
        { '<leader>ff', '<cmd>Telescope find_files<cr>', desc = 'Find files' },
        { '<leader>fg', '<cmd>Telescope live_grep<cr>', desc = 'Find word' },
        { '<leader>fb', '<cmd>Telescope buffers<cr>', desc = 'Find buffers' },
        { '<leader>fh', '<cmd>Telescope help_tags<cr>', desc = 'Find help' },
        { '<leader>fc', '<cmd>Telescope commands<cr>', desc = 'Find commands' },
        { '<leader>fs', '<cmd>Telescope lsp_document_symbols<cr>', desc = 'Find symbols' },
        { '<leader>fr', '<cmd>Telescope oldfiles<cr>', desc = 'Recent files' },
        { '<leader>fp', '<cmd>Telescope projects<cr>', desc = 'Projects' },
        { '<leader>fd', '<cmd>Telescope diagnostics<cr>', desc = 'Diagnostics' },
        { '<leader>ft', '<cmd>TodoTelescope<cr>', desc = 'Find TODOs' },
        { '<leader>p', '<cmd>Telescope commands<cr>', desc = 'Command palette' },
        { '<C-p>', '<cmd>Telescope find_files<cr>', desc = 'Find files (Ctrl+P)' },
      },
      config = function()
        local telescope = require('telescope')
        local actions = require('telescope.actions')
        
        telescope.setup({
          defaults = {
            layout_strategy = 'horizontal',
            layout_config = {
              width = 0.95,
              height = 0.85,
              preview_width = 0.55,
              preview_cutoff = 120, -- Only show preview when window width is larger than this
            },
            -- Default to using the right side for previews when they are shown
            mirror = false,
            sorting_strategy = 'ascending',
            winblend = 0,
            mappings = {
              i = {
                ['<C-j>'] = actions.move_selection_next,
                ['<C-k>'] = actions.move_selection_previous,
                ['<esc>'] = actions.close,
                ['<C-u>'] = false,
                ['<C-d>'] = false,
              },
            },
            file_ignore_patterns = { "node_modules", ".git", "dist", "build" },
            path_display = { "truncate" },
          },
          pickers = {
            find_files = {
              hidden = true,
              previewer = false, -- Disable preview for find_files by default
            },
            buffers = {
              show_all_buffers = true,
              sort_lastused = true,
              previewer = false, -- Disable preview for buffers by default
              mappings = {
                i = {
                  ["<c-d>"] = actions.delete_buffer,
                },
              },
            },
          },
          extensions = {
            fzf = {
              fuzzy = true,
              override_generic_sorter = true,
              override_file_sorter = true,
              case_mode = "smart_case",
            },
            ["ui-select"] = {
              require("telescope.themes").get_dropdown({}),
            },
          },
        })
        
        telescope.load_extension('fzf')
        telescope.load_extension('file_browser')
        telescope.load_extension('project')
        telescope.load_extension('ui-select')
        telescope.load_extension('crossplane')
      end,
    },
    
    -- LSP setup (VSCode-like)
    {'neovim/nvim-lspconfig',
      dependencies = {
        'williamboman/mason.nvim',
        'williamboman/mason-lspconfig.nvim',
        'WhoIsSethDaniel/mason-tool-installer.nvim',
        {'j-hui/fidget.nvim', opts = {}},
        {'folke/neodev.nvim', opts = {}},
      },
      config = function()
        -- Setup Mason first
        require('mason').setup({
          ui = {
            border = "rounded",
            icons = {
              package_installed = "✓",
              package_pending = "➜",
              package_uninstalled = "✗"
            }
          }
        })
        
        require('mason-lspconfig').setup({
          ensure_installed = {
            "lua_ls", "pyright", "gopls", "rust_analyzer", "terraformls", "bashls",
            "nixls", "dockerls", "yamlls", "kubernetes_ls"
          },
          automatic_installation = true,
        })
        
        require('mason-tool-installer').setup({
          ensure_installed = {
            "prettier", "stylua", "isort", "black", "eslint_d"
          }
        })
        
        -- LSP setup
        local lspconfig = require('lspconfig')
        
        -- Global mappings
        vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open diagnostic float' })
        vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Previous diagnostic' })
        vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })
        vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Add diagnostics to location list' })
        
        -- Use LspAttach autocommand to set up mappings
        vim.api.nvim_create_autocmd('LspAttach', {
          group = vim.api.nvim_create_augroup('UserLspConfig', {}),
          callback = function(ev)
            local client = vim.lsp.get_client_by_id(ev.data.client_id)
            local opts = { buffer = ev.buf, silent = true }
            
            vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
            vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
            vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
            vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
            vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
            vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
            vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
            vim.keymap.set('n', '<leader>wl', function()
              print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
            end, opts)
            vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, opts)
            vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
            vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts)
            vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
            vim.keymap.set('n', '<leader>fm', function()
              vim.lsp.buf.format { async = true }
            end, opts)
          end,
        })
        
        -- Configure specific LSPs
        lspconfig.lua_ls.setup({
          settings = {
            Lua = {
              diagnostics = {
                globals = { 'vim' }
              },
              workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false,
              },
              telemetry = { enable = false },
            }
          }
        })
        
        -- Add more server configurations as needed
        lspconfig.pyright.setup({})
        
        lspconfig.gopls.setup({})
        lspconfig.rust_analyzer.setup({})
        lspconfig.terraformls.setup({})
        lspconfig.bashls.setup({})
        lspconfig.nixls.setup({})
        lspconfig.dockerls.setup({})
        lspconfig.yamlls.setup({})
        lspconfig.kubernetes_ls.setup({})
      end,
    },
    
    -- Autocompletion system similar to VS Code
    {'hrsh7th/nvim-cmp',
      dependencies = {
        'hrsh7th/cmp-nvim-lsp',
        'hrsh7th/cmp-buffer',
        'hrsh7th/cmp-path',
        'hrsh7th/cmp-cmdline',
        'L3MON4D3/LuaSnip',
        'saadparwaiz1/cmp_luasnip',
        'rafamadriz/friendly-snippets',
        'onsails/lspkind.nvim',
        'zbirenbaum/copilot-cmp',
      },
      config = function()
        local cmp = require('cmp')
        local luasnip = require('luasnip')
        local lspkind = require('lspkind')
        
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
            ['<C-Space>'] = cmp.mapping.complete(),
            ['<C-e>'] = cmp.mapping.abort(),
            ['<CR>'] = cmp.mapping.confirm({ select = true }),
            ['<Tab>'] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
              else
                fallback()
              end
            end, { 'i', 's' }),
            ['<S-Tab>'] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_prev_item()
              elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end, { 'i', 's' }),
          }),
          sources = cmp.config.sources({
            { name = 'copilot', group_index = 2 },
            { name = 'nvim_lsp', group_index = 2 },
            { name = 'luasnip', group_index = 2 },
            { name = 'buffer', group_index = 3 },
            { name = 'path', group_index = 3 },
          }),
          formatting = {
            format = lspkind.cmp_format({
              mode = 'symbol_text',
              maxwidth = 50,
              ellipsis_char = '...',
              symbol_map = { Copilot = "" }
            })
          },
          experimental = {
            ghost_text = true,
          },
        })
        
        -- Set up cmdline completion
        cmp.setup.cmdline('/', {
          mapping = cmp.mapping.preset.cmdline(),
          sources = {
            { name = 'buffer' }
          }
        })
        
        cmp.setup.cmdline(':', {
          mapping = cmp.mapping.preset.cmdline(),
          sources = cmp.config.sources({
            { name = 'path' }
          }, {
            { name = 'cmdline' }
          })
        })
      end,
    },
    
    -- GitHub Copilot integration (VS Code's most popular extension)
    {'zbirenbaum/copilot.lua',
      cmd = "Copilot",
      event = "InsertEnter",
      config = function()
        require('copilot').setup({
          panel = {
            enabled = true,
            auto_refresh = true,
            keymap = {
              jump_prev = "[[",
              jump_next = "]]",
              accept = "<CR>",
              refresh = "gr",
              open = "<M-CR>"
            },
            layout = {
              position = "bottom",
              ratio = 0.4
            },
          },
          suggestion = {
            enabled = true,
            auto_trigger = true,
            debounce = 75,
            keymap = {
              accept = "<M-l>",
              accept_word = "<M-w>",
              accept_line = "<M-j>",
              next = "<M-]>",
              prev = "<M-[>",
              dismiss = "<C-]>",
            },
          },
          filetypes = {
            yaml = false,
            markdown = false,
            help = false,
            gitcommit = false,
            gitrebase = false,
            hgcommit = false,
            svn = false,
            cvs = false,
            ["."] = false,
          },
          copilot_node_command = 'node',
          server_opts_overrides = {},
        })
      end,
    },
    {'zbirenbaum/copilot-cmp',
      dependencies = {'zbirenbaum/copilot.lua'},
      config = function()
        require('copilot_cmp').setup()
      end,
    },
    
    -- VS Code-like diagnostic list
    {'folke/trouble.nvim',
      dependencies = {'nvim-tree/nvim-web-devicons'},
      keys = {
        { '<leader>xx', '<cmd>TroubleToggle<cr>', desc = 'Toggle trouble' },
        { '<leader>xw', '<cmd>TroubleToggle workspace_diagnostics<cr>', desc = 'Workspace diagnostics' },
        { '<leader>xd', '<cmd>TroubleToggle document_diagnostics<cr>', desc = 'Document diagnostics' },
        { '<leader>xq', '<cmd>TroubleToggle quickfix<cr>', desc = 'Quickfix' },
        { '<leader>xl', '<cmd>TroubleToggle loclist<cr>', desc = 'Location list' },
        { '<leader>tt', '<cmd>TroubleToggle<cr>', desc = 'Toggle trouble' },
      },
      opts = {
        position = "bottom",
        height = 10,
        width = 50,
        icons = true,
        mode = "workspace_diagnostics",
        fold_open = "",
        fold_closed = "",
        group = true,
        padding = true,
        action_keys = {
          close = "q", 
          cancel = "<esc>", 
          refresh = "r",
          jump = {"<cr>", "<tab>"},
          open_split = {"<c-s>"},
          open_vsplit = {"<c-v>"},
          open_tab = {"<c-t>"},
          jump_close = {"o"},
          toggle_mode = "m",
          toggle_preview = "P",
          hover = "K",
          preview = "p",
          close_folds = {"zM", "zm"},
          open_folds = {"zR", "zr"},
          toggle_fold = {"zA", "za"},
          previous = "k",
          next = "j"
        },
        indent_lines = true,
        auto_open = false,
        auto_close = false,
        auto_preview = true,
        auto_fold = false,
        auto_jump = {"lsp_definitions"},
        signs = {
          error = "",
          warning = "",
          hint = "",
          information = "",
          other = ""
        },
        use_diagnostic_signs = false
      },
    },
    
    -- Symbol outline similar to VS Code
    {'simrat39/symbols-outline.nvim',
      keys = {
        { '<leader>so', '<cmd>SymbolsOutline<cr>', desc = 'Toggle Symbols Outline' },
      },
      config = function() 
        require('symbols-outline').setup({
          highlight_hovered_item = true,
          show_guides = true,
          auto_preview = false,
          position = 'right',
          width = 25,
          keymaps = {
            close = {"<Esc>", "q"},
            goto_location = "<Cr>",
            focus_location = "o",
            hover_symbol = "<C-space>",
            rename_symbol = "r",
            code_actions = "a",
            fold = "h",
            unfold = "l",
            fold_all = "W",
            unfold_all = "E",
            fold_reset = "R",
          },
          symbols = {
            File = {icon = "", hl = "@text.uri"},
            Module = {icon = "", hl = "@namespace"},
            Namespace = {icon = "", hl = "@namespace"},
            Package = {icon = "", hl = "@namespace"},
            Class = {icon = "𝓒", hl = "@type"},
            Method = {icon = "ƒ", hl = "@method"},
            Property = {icon = "", hl = "@method"},
            Field = {icon = "", hl = "@field"},
            Constructor = {icon = "", hl = "@constructor"},
            Enum = {icon = "ℰ", hl = "@type"},
            Interface = {icon = "ﰮ", hl = "@type"},
            Function = {icon = "", hl = "@function"},
            Variable = {icon = "", hl = "@constant"},
            Constant = {icon = "", hl = "@constant"},
            String = {icon = "𝓐", hl = "@string"},
            Number = {icon = "#", hl = "@number"},
            Boolean = {icon = "⊨", hl = "@boolean"},
            Array = {icon = "", hl = "@constant"},
            Object = {icon = "⦿", hl = "@type"},
            Key = {icon = "🔐", hl = "@type"},
            Null = {icon = "NULL", hl = "@type"},
            EnumMember = {icon = "", hl = "@field"},
            Struct = {icon = "𝓢", hl = "@type"},
            Event = {icon = "🗲", hl = "@type"},
            Operator = {icon = "+", hl = "@operator"},
            TypeParameter = {icon = "𝙏", hl = "@parameter"}
          }
        })
      end
    },
    {'stevearc/aerial.nvim',
      keys = {
        { '<leader>to', '<cmd>AerialToggle<cr>', desc = 'Toggle Aerial (Code Outline)' },
      },
      opts = {
        layout = {
          default_direction = "right",
          placement = "edge",
          width = 30,
        },
        on_attach = function(bufnr)
          vim.keymap.set('n', '{', '<cmd>AerialPrev<CR>', {buffer = bufnr})
          vim.keymap.set('n', '}', '<cmd>AerialNext<CR>', {buffer = bufnr})
        end,
      },
    },
    
    -- VS Code-like key binding hints (removed - using the one from init.lua)
    
    -- Terminal integration
    {'akinsho/toggleterm.nvim',
      version = "*",
      keys = {
        { '<C-\\>', '<cmd>ToggleTerm<cr>', desc = 'Toggle Terminal' },
        { '<leader>tf', '<cmd>ToggleTerm direction=float<cr>', desc = 'Float Terminal' },
        { '<leader>th', '<cmd>ToggleTerm size=10 direction=horizontal<cr>', desc = 'Horizontal Terminal' },
        { '<leader>tv', '<cmd>ToggleTerm size=80 direction=vertical<cr>', desc = 'Vertical Terminal' },
      },
      opts = {
        size = function(term)
          if term.direction == "horizontal" then
            return 15
          elseif term.direction == "vertical" then
            return vim.o.columns * 0.4
          end
        end,
        open_mapping = [[<c-\>]],
        hide_numbers = true,
        shade_filetypes = {},
        shade_terminals = true,
        shading_factor = 2,
        start_in_insert = true,
        insert_mappings = true,
        persist_size = true,
        direction = "float",
        close_on_exit = true,
        shell = vim.o.shell,
        float_opts = {
          border = "curved",
          winblend = 0,
          highlights = {
            border = "Normal",
            background = "Normal",
          },
        },
      },
    },
    
    -- Commenting support (like VS Code)
    {'numToStr/Comment.nvim',
      opts = {
        padding = true,
        sticky = true,
        ignore = nil,
        toggler = {
          line = 'gcc',
          block = 'gbc',
        },
        opleader = {
          line = 'gc',
          block = 'gb',
        },
        extra = {
          above = 'gcO',
          below = 'gco',
          eol = 'gcA',
        },
        mappings = {
          basic = true,
          extra = true,
        },
      },
    },
    
    -- Auto-pairing (like VS Code)
    {'windwp/nvim-autopairs',
      event = "InsertEnter",
      opts = {
        check_ts = true,
        ts_config = {
          lua = {'string'},
          javascript = {'template_string'},
        },
        disable_filetype = {'TelescopePrompt', 'vim'},
        fast_wrap = {
          map = '<M-e>',
          chars = {'{', '[', '(', '"', "'"},
          pattern = [=[[%'%"%)%>%]%)%}%,]]=],
          end_key = '$',
          keys = 'qwertyuiopzxcvbnmasdfghjkl',
          check_comma = true,
          highlight = 'Search',
          highlight_grey = 'Comment',
        },
      },
    },
    
    -- Highlight and list TODOs (like VS Code's todo-highlight)
    {'folke/todo-comments.nvim',
      dependencies = {'nvim-lua/plenary.nvim'},
      keys = {
        { '<leader>ft', '<cmd>TodoTelescope<cr>', desc = 'Find TODOs' },
        { '<leader>xt', '<cmd>TroubleToggle todo<cr>', desc = 'TODOs (Trouble)' },
        { ']t', function() require('todo-comments').jump_next() end, desc = 'Next TODO' },
        { '[t', function() require('todo-comments').jump_prev() end, desc = 'Previous TODO' },
      },
      opts = {
        signs = true,
        sign_priority = 8,
        keywords = {
          FIX = {
            icon = " ",
            color = "error", 
            alt = { "FIXME", "BUG", "FIXIT", "ISSUE" },
          },
          TODO = { icon = " ", color = "info" },
          HACK = { icon = " ", color = "warning" },
          WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
          PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
          NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
          TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
        },
        gui_style = {
          fg = "NONE",
          bg = "BOLD",
        },
        merge_keywords = true,
        highlight = {
          multiline = true,
          multiline_pattern = "^.",
          multiline_context = 10,
          before = "",
          keyword = "wide",
          after = "fg",
          pattern = [[.*<(KEYWORDS)\s*:]],
          comments_only = true,
          max_line_len = 400,
          exclude = {},
        },
        colors = {
          error = { "DiagnosticError", "ErrorMsg", "#DC2626" },
          warning = { "DiagnosticWarning", "WarningMsg", "#FBBF24" },
          info = { "DiagnosticInfo", "#2563EB" },
          hint = { "DiagnosticHint", "#10B981" },
          default = { "Identifier", "#7C3AED" },
          test = { "Identifier", "#FF00FF" }
        },
        search = {
          command = "rg",
          args = {
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
          },
          pattern = [[\b(KEYWORDS):]],
        },
      },
    },
    
    -- Status line (like VS Code)
    {'nvim-lualine/lualine.nvim',
      event = "VeryLazy",
      dependencies = {'nvim-tree/nvim-web-devicons'},
      opts = {
        options = {
          icons_enabled = true,
          theme = 'auto',
          component_separators = { left = '', right = ''},
          section_separators = { left = '', right = ''},
          disabled_filetypes = {
            statusline = {'NvimTree', 'Trouble', 'Outline', 'Startify'},
            winbar = {},
          },
          ignore_focus = {},
          always_divide_middle = true,
          globalstatus = true,
          refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
          }
        },
        sections = {
          lualine_a = {'mode'},
          lualine_b = {
            'branch', 
            'diff', 
            {
              'diagnostics',
              sources = {'nvim_diagnostic'},
              symbols = {error = ' ', warn = ' ', info = ' ', hint = ' '},
            }
          },
          lualine_c = {
            {
              'filename',
              path = 1, -- Show relative path
              symbols = {
                modified = '●',
                readonly = '',
                unnamed = '[No Name]',
                newfile = '[New]',
              }
            }
          },
          lualine_x = {
            {
              function()
                local ok, copilot = pcall(require, "copilot.client")
                if ok then
                  local clients = copilot.get_clients()
                  if #clients > 0 then
                    return " " .. (clients[1].stats.show_spinner and "⋯" or "")
                  end
                end
                return ""
              end,
            },
            'encoding',
            'fileformat',
            'filetype'
          },
          lualine_y = {'progress'},
          lualine_z = {'location'}
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {'filename'},
          lualine_x = {'location'},
          lualine_y = {},
          lualine_z = {}
        },
        tabline = {},
        winbar = {},
        inactive_winbar = {},
        extensions = {'nvim-tree', 'toggleterm', 'symbols-outline', 'trouble'}
      },
    },
    
    -- Multiple cursors (like VS Code)
    {'mg979/vim-visual-multi', 
      branch = 'master',
    },
    
    -- Git blame (like VS Code GitLens)
    {'f-person/git-blame.nvim',
      opts = {
        enabled = false,
        date_format = '%Y-%m-%d',
        message_template = '  <author> • <date> • <summary>',
        message_when_not_committed = 'Not committed yet',
        highlight_group = 'Comment',
        display_virtual_text = true,
        delay = 1000,
      },
      keys = {
        { '<leader>gb', '<cmd>GitBlameToggle<cr>', desc = 'Toggle Git Blame' },
      },
    },
    
    -- Formatter
    {'mhartington/formatter.nvim',
      keys = {
        { '<leader>fm', '<cmd>FormatWrite<cr>', desc = 'Format file' },
      },
      config = function()
        require('formatter').setup({
          logging = true,
          log_level = vim.log.levels.WARN,
          filetype = {
            lua = {
              require('formatter.filetypes.lua').stylua,
            },
            javascript = {
              require('formatter.filetypes.javascript').prettier,
            },
            typescript = {
              require('formatter.filetypes.typescript').prettier,
            },
            javascriptreact = {
              require('formatter.filetypes.javascriptreact').prettier,
            },
            typescriptreact = {
              require('formatter.filetypes.typescriptreact').prettier,
            },
            json = {
              require('formatter.filetypes.json').prettier,
            },
            html = {
              require('formatter.filetypes.html').prettier,
            },
            css = {
              require('formatter.filetypes.css').prettier,
            },
            python = {
              require('formatter.filetypes.python').black,
            },
            go = {
              require('formatter.filetypes.go').gofmt,
            },
            rust = {
              require('formatter.filetypes.rust').rustfmt,
            },
            ["*"] = {
              require('formatter.filetypes.any').remove_trailing_whitespace,
            }
          }
        })
      end,
    },
    
    -- Indentation guides
    {'lukas-reineke/indent-blankline.nvim',
      main = "ibl",
      config = function()
        local highlight = {
          "RainbowRed",
          "RainbowYellow",
          "RainbowBlue",
          "RainbowOrange",
          "RainbowGreen",
          "RainbowViolet",
          "RainbowCyan",
        }
        
        local hooks = require "ibl.hooks"
        -- Create the highlight groups in the highlight setup hook
        -- so they are reset whenever the colorscheme changes
        hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
          vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
          vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
          vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
          vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
          vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
          vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
          vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
        end)

        -- Enable scope highlighting with rainbow delimiters integration
        vim.g.rainbow_delimiters = { highlight = highlight }
        
        require("ibl").setup {
          indent = {
            char = "│",
            highlight = highlight,
          },
          scope = {
            enabled = true,
            show_start = true,
            show_end = true,
            highlight = highlight,
          },
        }
        
        -- Handle special buffers like startify
        vim.api.nvim_create_autocmd("FileType", {
          pattern = "startify",
          callback = function(args)
            require("ibl").setup_buffer(args.buf, { enabled = false })
          end,
        })
        
        -- Add IBL commands for Neovim 0.7+ compatibility
        -- These commands are redefined in init.lua to ensure they're available early
        vim.api.nvim_create_user_command('IBLDisable', function()
          require('ibl').setup_buffer(0, { enabled = false })
        end, {})
        
        vim.api.nvim_create_user_command('IBLEnable', function()
          require('ibl').setup_buffer(0, { enabled = true })
        end, {})
        
        -- Link scope highlighting to rainbow delimiters
        hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
      end,
    },
    
    -- Animation with mini.animate (replaces neoscroll)
    {'echasnovski/mini.nvim',
      version = false,
      config = function()
        require('mini.animate').setup({
          cursor = {
            enable = true,
            timing = function(_, n) return 150 / n end,
            path = require('mini.animate').gen_path.line(),
          },
          scroll = {
            enable = true,
            timing = function(_, n) return 200 / n end,
            subscroll = require('mini.animate').gen_subscroll.cubic({ easing = 'in-out' }),
          },
          resize = {
            enable = true,
            timing = function(_, n) return 100 / n end,
          },
          open = {
            enable = true,
            timing = function(_, n) return 250 / n end,
          },
          close = {
            enable = true,
            timing = function(_, n) return 250 / n end,
          },
          -- Set minimum window width to prevent layout shift on smaller windows
          win_config = {
            width = math.floor(0.8 * vim.o.columns),
            height = math.floor(0.8 * vim.o.lines),
          },
        })
      end,
    },
    
    -- Neoformat (alternative formatter)
    {'sbdchd/neoformat'},
    
}, {
  ui = {
    border = "rounded",
    icons = {
      cmd = "⌘",
      config = "🛠",
      event = "📅",
      ft = "📂",
      init = "⚙",
      keys = "🔑",
      plugin = "🔌",
      runtime = "💻",
      source = "📄",
      start = "🚀",
      task = "📌",
      lazy = "💤 ",
    },
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
  checker = { enabled = false },
  change_detection = { enabled = true, notify = false },
})

-- Load configuration modules
local config_modules = {
    'general', 'barline', 'startify', 'nvim-tree', 'codewindow', 'wilder', 'keystroke'
}

-- Use pcall for each module to avoid breaking if one fails
for _, module in ipairs(config_modules) do 
    local ok, err = pcall(require, 'config.' .. module)
    if not ok then
        print('Error loading module ' .. module .. ': ' .. err)
    end
end

-- LSP setup
local lspconfig = require('lspconfig')

-- Configure language servers
lspconfig.pyright.setup{}
lspconfig.rust_analyzer.setup{}
lspconfig.gopls.setup{}
lspconfig.terraformls.setup{}
lspconfig.bashls.setup{}
lspconfig.nixls.setup{}
lspconfig.dockerls.setup{}
lspconfig.yamlls.setup{}
lspconfig.kubernetes_ls.setup{}

-- Autocompletion setup
local cmp = require('cmp')
local luasnip = require('luasnip')
local lspkind = require('lspkind')

require('luasnip.loaders.from_vscode').lazy_load()

cmp.setup({
    snippet = {expand = function(args) luasnip.lsp_expand(args.body) end},
    mapping = cmp.mapping.preset.insert({
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<CR>'] = cmp.mapping.confirm({select = true}),
        ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            else
                fallback()
            end
        end, {'i', 's'}),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, {'i', 's'})
    }),
    sources = cmp.config.sources({
        {name = 'copilot'},
        {name = 'nvim_lsp'},
        {name = 'luasnip'},
        {name = 'buffer'},
        {name = 'path'}
    }),
    formatting = {
        format = lspkind.cmp_format({mode = 'symbol_text', maxwidth = 50})
    }
})

-- Set up other IDE features with safety checks
local function safe_setup(module_name)
    local ok, module = pcall(require, module_name)
    if ok then
        module.setup({})
        return true
    end
    return false
end

safe_setup('nvim-autopairs')
safe_setup('Comment')
safe_setup('symbols-outline')
safe_setup('trouble')

local ok_term, toggleterm = pcall(require, 'toggleterm')
if ok_term then
    toggleterm.setup({open_mapping = [[<c-\>]], direction = 'float'})
end

-- Aerial setup (Code outline for VSCode-like structure view)
local ok_aerial, aerial = pcall(require, 'aerial')
if ok_aerial then
    aerial.setup({
        layout = {
            default_direction = "right",
            placement = "edge",
            width = 30,
        },
        -- Show outline on right side by default
        open_automatic = true,
        -- Filter out certain symbols for cleaner view
        filter_kind = {
            "Class", "Constructor", "Enum", "Function", "Interface", "Method", 
            "Module", "Namespace", "Package", "Property", "Struct", "Unit"
        },
        -- Icons for different symbol kinds
        icons = {
            Class = "󰠱 ",
            Constructor = "󰆧 ",
            Function = "󰊕 ",
            Method = "ƒ ",
            Module = "󰏗 ",
        },
        keymaps = {
            ["<leader>to"] = "toggle",
            ["{<CR>"] = "actions.jump",
            ["["] = "actions.prev",
            ["]"] = "actions.next",
        },
    })
    
    -- Hotkey for toggle (F7 as additional shortcut)
    vim.keymap.set('n', '<F7>', '<cmd>AerialToggle!<CR>', { desc = "Toggle Code Outline" })
end

-- Formatting setup
require('formatter').setup({
        filetype = {
            javascript = {
                function()
                    return {
                        exe = "prettier",
                        args = {"--stdin-filepath", vim.fn.fnameescape(vim.api.nvim_buf_get_name(0))},
                        stdin = true
                    }
                end
            },
            typescript = {
                function()
                    return {
                        exe = "prettier",
                        args = {"--stdin-filepath", vim.fn.fnameescape(vim.api.nvim_buf_get_name(0))},
                        stdin = true
                    }
                end
            },
            python = {
                function()
                    return {
                        exe = "black",
                        args = {"-"},
                        stdin = true
                    }
                end
            },
            rust = {
                function()
                    return {
                        exe = "rustfmt",
                        args = {"--emit=stdout"},
                        stdin = true
                    }
                end
            },
            go = {
                function()
                    return {
                        exe = "gofmt",
                        stdin = true
                    }
                end
            },
        }
    })

-- Format on save
vim.cmd([[augroup FormatAutogroup
  autocmd!
  autocmd BufWritePost * FormatWrite
augroup END]])

-- Git blame setup (wrapped in pcall for safety)
local ok_gitblame, gitblame = pcall(require, 'git-blame')
if not ok_gitblame then
    -- Try alternative module name
    ok_gitblame, gitblame = pcall(require, 'gitblame')
end

if ok_gitblame then
    gitblame.setup({
        enabled = false,
    })
end

-- Todo comments
local ok_todo, todo_comments = pcall(require, 'todo-comments')
if ok_todo then
    todo_comments.setup()
end

-- Kubectl setup
local ok_kubectl, kubectl = pcall(require, 'kubectl')
if ok_kubectl then
    kubectl.setup({})
end

-- Define a custom command to open Startify
vim.cmd([[
  command! StartifyStart call StartifyStart()
  function StartifyStart()
    execute 'Startify'
  endfunction
]])

-- Helper to add a newline
vim.cmd([[
  function! AddNewLine()
    let save_cursor = getcurpos()
    call append(line('.'), '')
    call setpos('.', save_cursor)
  endfunction

  function! RemoveNewLine()
    let current_line = line('.')
    if current_line < line('$')
      execute 'normal! J'
    endif
  endfunction
]])

-- Neovim help command
vim.cmd([[
  command! NvimHelp !sh ~/.config/nvim/nvim-help.sh
  command! NvimHelpNav !sh ~/.config/nvim/nvim-help.sh nav
  command! NvimHelpCode !sh ~/.config/nvim/nvim-help.sh code
  command! NvimHelpEditor !sh ~/.config/nvim/nvim-help.sh editor
  command! NvimHelpGit !sh ~/.config/nvim/nvim-help.sh git
  command! NvimHelpCopilot !sh ~/.config/nvim/nvim-help.sh copilot
  command! NvimHelpK8s !sh ~/.config/nvim/nvim-help.sh k8s
]])

-- Define a command palette function
vim.cmd([[
  function! CommandPalette()
    call wilder#start_search()
  endfunction
  command! CommandPalette call CommandPalette()
]])

-- Keybindings
-- Map <F1> to open or close Startify
vim.api.nvim_set_keymap('n', '<F1>', ':Startify<CR>',
                        {noremap = true, silent = true})

-- Map <F2> to open or close nvim-tree
vim.api.nvim_set_keymap('n', '<F2>', ':NvimTreeToggle<CR>',
                        {noremap = true, silent = true})

-- Telescope keybindings
vim.api.nvim_set_keymap('n', '<leader>ff', ':Telescope find_files<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>fg', ':Telescope live_grep<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>fb', ':Telescope buffers<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>fh', ':Telescope help_tags<CR>',
                        {noremap = true, silent = true})

-- LSP keybindings
vim.api.nvim_set_keymap('n', 'gd', ':lua vim.lsp.buf.definition()<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', 'gr', ':lua vim.lsp.buf.references()<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', 'gi', ':lua vim.lsp.buf.implementation()<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', 'K', ':lua vim.lsp.buf.hover()<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>rn', ':lua vim.lsp.buf.rename()<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>ca', ':lua vim.lsp.buf.code_action()<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>e',
                        ':lua vim.diagnostic.open_float()<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>tt', ':TroubleToggle<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>so', ':SymbolsOutline<CR>',
                        {noremap = true, silent = true})

-- Format keybindings
vim.api.nvim_set_keymap('n', '<leader>fm', ':Format<CR>',
                        {noremap = true, silent = true})

-- Add/remove newline keybindings
vim.api.nvim_set_keymap('n', '<leader>nl', ':call AddNewLine()<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>nld', ':call RemoveNewLine()<CR>',
                        {noremap = true, silent = true})

-- Git blame keybindings
vim.api.nvim_set_keymap('n', '<leader>gb', ':GitBlameToggle<CR>',
                        {noremap = true, silent = true})

-- Command palette
vim.api.nvim_set_keymap('n', '<leader>p', ':CommandPalette<CR>',
                        {noremap = true, silent = true})

-- Copilot keybindings
vim.api.nvim_set_keymap('n', '<leader>cc', ':Copilot toggle<CR>',
                        {noremap = true, silent = true, desc = "Toggle Copilot"})
vim.api.nvim_set_keymap('n', '<leader>cs', ':Copilot suggestion<CR>',
                        {noremap = true, silent = true, desc = "Copilot suggestion"})
vim.api.nvim_set_keymap('n', '<leader>cd', ':Copilot panel<CR>',
                        {noremap = true, silent = true, desc = "Copilot panel"})
vim.api.nvim_set_keymap('n', '<leader>cr', ':Copilot chat<CR>',
                        {noremap = true, silent = true, desc = "Copilot chat"})

-- Enhanced Copilot setup
vim.g.copilot_no_tab_map = true
vim.api.nvim_set_keymap("i", "<C-j>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
vim.api.nvim_set_keymap("i", "<M-l>", '<Plug>(copilot-accept-line)', {})
vim.api.nvim_set_keymap("i", "<M-w>", '<Plug>(copilot-accept-word)', {})

-- Kubectl keybindings
vim.api.nvim_set_keymap('n', '<leader>kl',
                        ':lua require("kubectl").get_logs()<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>kp',
                        ':lua require("kubectl").get_pods()<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>kd',
                        ':lua require("kubectl").describe()<CR>',
                        {noremap = true, silent = true})

-- NvimHelp keybindings
vim.api.nvim_set_keymap('n', '<leader>h', ':NvimHelp<CR>',
                        {noremap = true, silent = false})

-- Startify will be auto-launched via init.lua