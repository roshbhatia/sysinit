local M = {}
local config = require("sysinit.utils.config")

local deps = {
  "giuxtaposition/blink-cmp-copilot",
  "L3MON4D3/LuaSnip",
  "pta2002/intellitab.nvim",
  "rafamadriz/friendly-snippets",
  "xzbdmw/colorful-menu.nvim",
}

if config.is_copilot_enabled() then
  table.insert(deps, "giuxtaposition/blink-cmp-copilot")
end

M.plugins = {
  {
    "saghen/blink.cmp",
    version = "1.*",
    dependencies = deps,
    lazy = false,
    opts = function()
      local providers = {
        buffer = {
          score_offset = 3,
          transform_items = function(ctx, items)
            for _, item in ipairs(items) do
              item.kind_icon = " Buffer "
              item.kind_name = "Buffer"
            end
            return items
          end,
        },
        lazydev = {
          enabled = function()
            return vim.tbl_contains({ "lua" }, vim.bo.filetype)
          end,
          module = "lazydev.integrations.blink",
          name = "LazyDev",
          score_offset = 1,
        },
        lsp = {
          score_offset = 0,
          transform_items = function(ctx, items)
            for _, item in ipairs(items) do
              item.kind_icon = "󰘧 LSP "
              item.kind_name = "LSP"
            end
            return items
          end,
        },
        path = {
          score_offset = 1,
          transform_items = function(ctx, items)
            for _, item in ipairs(items) do
              item.kind_icon = " Path "
              item.kind_name = "Path"
            end
            return items
          end,
          opts = {
            show_hidden_files_by_default = true,
          },
        },
        snippets = {
          score_offset = 2,
          transform_items = function(ctx, items)
            for _, item in ipairs(items) do
              item.kind_icon = "󰩫 Snippets "
              item.kind_name = "Snippets"
            end
            return items
          end,
        },
      }

      local sources = {
        "buffer",
        "lazydev",
        "lsp",
        "path",
        "snippets",
      }

      if config.is_copilot_enabled() then
        providers.copilot = {
          name = "copilot",
          module = "blink-cmp-copilot",
          score_offset = 100,
          async = true,
          transform_items = function(ctx, items)
            for _, item in ipairs(items) do
              item.kind_icon = " Copilot "
              item.kind_name = "Copilot"
            end
            return items
          end,
        }
        table.insert(sources, "copilot")
      end

      return {
        completion = {
          accept = {
            auto_brackets = {
              enabled = false,
            },
            create_undo_point = true,
          },
          documentation = {
            auto_show = true,
            auto_show_delay_ms = 0,
            window = {
              border = "rounded",
            },
            draw = function(opts)
              if opts.item and opts.item.documentation then
                local out = require("pretty_hover.parser").parse(opts.item.documentation.value)
                opts.item.documentation.value = out:string()
              end

              opts.default_implementation(opts)
            end,
          },
          ghost_text = {
            enabled = true,
          },
          list = {
            selection = {
              preselect = false,
              auto_insert = true,
            },
          },
          menu = {
            max_height = 15,
            border = "rounded",
            draw = {
              columns = {
                {
                  "kind_icon",
                },
                {
                  "label",
                  gap = 1,
                },
              },
              components = {
                label = {
                  text = function(ctx)
                    return require("colorful-menu").blink_components_text(ctx)
                  end,
                  highlight = function(ctx)
                    return require("colorful-menu").blink_components_highlight(ctx)
                  end,
                },
              },
              treesitter = {
                "lsp",
                "copilot",
              },
            },
          },
        },
        cmdline = {
          enabled = false,
        },
        fuzzy = {
          implementation = "prefer_rust",
        },
        keymap = {
          preset = "super-tab",
          ["<C-Space>"] = {
            "show",
          },
          ["<CR>"] = {
            "accept",
            "fallback",
          },
          ["<Tab>"] = {
            "select_next",
            "snippet_forward",
            function()
              require("intellitab").indent()
            end,
          },
          ["<S-Tab>"] = {
            "select_prev",
            "snippet_backward",
            "fallback",
          },
        },
        signature = {
          enabled = true,
          window = {
            border = "rounded",
          },
        },
        sources = {
          default = sources,
          providers = providers,
        },
        snippets = {
          preset = "luasnip",
        },
      }
    end,
    opts_extend = {
      "sources.default",
    },
  },
}

return M
