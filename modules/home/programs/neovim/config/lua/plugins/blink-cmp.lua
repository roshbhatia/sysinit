return {
  {
    "saghen/blink.cmp",
    version = "1.*",
    event = { "BufReadPost", "InsertEnter" },
    dependencies = {
      "xzbdmw/colorful-menu.nvim",
      "fang2hou/blink-copilot",
      "copilotlsp-nvim/copilot-lsp",
    },
    opts = function()
      local function ai_doc_preview(item)
        local text = (item.textEdit and item.textEdit.newText) or item.insertText or item.label
        if type(text) ~= "string" or text == "" then
          return
        end
        if not item.detail or item.detail == "" then
          item.detail = text
        end
        item.documentation = nil
      end

      local providers = {
        buffer = {
          score_offset = 3,
          transform_items = function(_ctx, items)
            for _, item in ipairs(items) do
              item.kind_icon = " Buffer "
              item.kind_name = "Buffer"
            end
            return items
          end,
        },
        lazydev = {
          enabled = false,
          module = "lazydev.integrations.blink",
          name = "LazyDev",
          score_offset = 1,
        },
        lsp = {
          score_offset = 0,
          transform_items = function(_ctx, items)
            for _, item in ipairs(items) do
              item.kind_icon = "󰘧 LSP "
              item.kind_name = "LSP"
            end
            return items
          end,
        },
        path = {
          score_offset = 1,
          transform_items = function(_ctx, items)
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
        copilot = {
          name = "copilot",
          module = "blink-copilot",
          score_offset = 100,
          async = true,
          transform_items = function(_ctx, items)
            for _, item in ipairs(items) do
              item.kind_icon = " Copilot "
              item.kind_name = "Copilot"
              ai_doc_preview(item)
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
        "copilot",
      }

      return {
        completion = {
          keyword = {
            range = "prefix",
          },
          accept = {
            auto_brackets = {
              enabled = false,
            },
            create_undo_point = true,
          },
          documentation = {
            auto_show = true,
            auto_show_delay_ms = 0,
            draw = function(opts)
              local item = opts.item
              if item and item.documentation and type(item.documentation) == "table" and item.documentation.value then
                local ok, parser = pcall(require, "pretty_hover.parser")
                if ok then
                  local out = parser.parse(item.documentation.value)
                  item.documentation.value = out:string()
                end
              end
              opts.default_implementation()
            end,
          },
          ghost_text = {
            enabled = true,
          },
          list = {
            selection = {
              preselect = false,
              auto_insert = false,
            },
          },
          menu = {
            max_height = 15,
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
            function(cmp)
              local ok, copilot = pcall(require, "blink-copilot")
              if ok and copilot.is_visible and copilot.is_visible() then
                return cmp.select_and_accept()
              end
            end,
            "select_next",
            "fallback",
          },
          ["<S-Tab>"] = {
            "select_prev",
            "fallback",
          },
        },
        signature = {
          enabled = true,
        },
        sources = {
          default = sources,
          providers = providers,
        },
        snippets = {
          preset = "default",
        },
      }
    end,
    opts_extend = {
      "sources.default",
    },
  },
}
