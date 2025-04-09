local M = {}
local panel = require("core.panel")
local test = require("core.test")

M.plugins = {
  {
    "willothy/wezterm.nvim",
    lazy = false,
    config = true,
  },
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    panel = panel.PANELS.LEFT,
    opts = {
      default_file_explorer = true,
      view_options = { show_hidden = true },
      float = {
        padding = 2,
        max_width = 0,
        max_height = 0,
        border = "rounded",
        win_options = { winblend = 0 },
      },
    },
  },
  {
    "Isrothy/neominimap.nvim",
    panel = panel.PANELS.RIGHT,
    opts = {
      auto_enable = true,
      layout = "split",
      split = {
        direction = "right",
        minimap_width = 20,
      },
    },
  },
}

function M.setup()
  local wezterm = require("wezterm")
  local legendary = require("legendary")

  -- Register panel plugins
  for _, plugin in ipairs(M.plugins) do
    if plugin.panel then
      panel.register_panel_plugin(plugin.panel, plugin)
    end
  end

  -- Register panel toggle commands
  legendary.keymaps({
    {
      "<leader>e",
      function()
        local current_win = vim.api.nvim_get_current_win()
        wezterm.split_pane.horizontal({
          left = true,
          percent = 20,
          program = { "nvim", "-c", "Oil" },
        })
      end,
      description = "Toggle left panel (File Explorer)",
    },
    {
      "<leader>r",
      function()
        local current_win = vim.api.nvim_get_current_win()
        -- Toggle all right panel plugins
        for _, plugin in ipairs(panel.get_panel_plugins(panel.PANELS.RIGHT)) do
          if plugin.toggle then
            plugin.toggle()
          end
        end
      end,
      description = "Toggle right panel",
    },
  })

  -- Register tests with health checks
  test.register_test("layout", {
    {
      desc = "Left Panel (Oil) Toggle",
      command = "<leader>e",
      expected = "Oil file explorer should open in left 20% of screen",
      verify = function()
        return vim.fn.exists(":Oil") == 2
      end
    },
    {
      desc = "Right Panel Toggle",
      command = "<leader>r",
      expected = "Minimap should open in right 20% of screen",
      verify = function()
        return vim.fn.exists(":Neominimap") == 2
      end
    },
    {
      desc = "Panel Integration",
      command = "<leader>e, then <leader>r",
      expected = "Both panels should be visible and properly sized",
    },
    {
      desc = "Error Handling",
      command = "Intentionally cause an error by closing a panel incorrectly",
      expected = "Should handle error gracefully and maintain panel state",
    }
  }, {
    -- Health checks
    function()
      -- Check WezTerm integration
      local has_wezterm = pcall(require, "wezterm")
      if not has_wezterm then
        return { status = "ERROR", msg = "WezTerm integration not available" }
      end
      return { status = "OK", msg = "WezTerm integration available" }
    end,
    function()
      -- Check Oil.nvim
      local has_oil = vim.fn.exists(":Oil") == 2
      if not has_oil then
        return { status = "ERROR", msg = "Oil.nvim not properly loaded" }
      end
      return { status = "OK", msg = "Oil.nvim loaded and ready" }
    end,
    function()
      -- Check panel state
      local panel = require("core.panel")
      if #panel.get_panel_plugins(panel.PANELS.LEFT) == 0 then
        return { status = "WARN", msg = "No plugins registered for left panel" }
      end
      return { status = "OK", msg = "Panel plugins properly registered" }
    end,
  })
end

return M
