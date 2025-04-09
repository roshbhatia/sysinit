local M = {}
local panel = require("core.panel")
local test = require("core.test")
local verify = require("core.verify")

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

-- Register verification steps
verify.register_verification("layout", {
  {
    desc = "Check Oil.nvim Integration",
    command = "<leader>e",
    expected = "Should open Oil file explorer in the left panel (20% width)",
  },
  {
    desc = "Check Panel Toggling",
    command = "<leader>e (press again)",
    expected = "Should close the left panel",
  },
  {
    desc = "Verify Right Panel",
    command = "<leader>r",
    expected = "Should open minimap in the right panel (20% width)",
  },
  {
    desc = "Check Panel Persistence",
    command = ":e somefile.txt",
    expected = "Panels should maintain their state when switching buffers",
  },
  {
    desc = "Test WezTerm Integration",
    command = ":WeztermSpawn htop",
    expected = "Should open htop in a new WezTerm pane",
  },
})

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

  -- Register tests with health checks and verifications
  test.register_test("layout", {
    -- Basic functionality tests
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
    -- WezTerm integration tests
    {
      desc = "WezTerm Multiplexing",
      command = ":WeztermSpawn htop",
      expected = "Should open htop in a new WezTerm pane",
      verify = function()
        return pcall(require, "wezterm") and true
      end
    },
    -- Panel state tests
    {
      desc = "Panel State Persistence",
      command = "<leader>e, switch buffers, <leader>e",
      expected = "Panel should maintain state across buffer switches",
    },
    {
      desc = "Multiple Panel Interaction",
      command = "<leader>e, then <leader>r",
      expected = "Both panels should coexist without conflicts",
    }
  }, {
    -- Health checks
    function()
      -- Verify WezTerm
      if not pcall(require, "wezterm") then
        return { status = "ERROR", msg = "WezTerm integration not available" }
      end
      return { status = "OK", msg = "WezTerm integration ready" }
    end,
    function()
      -- Verify Oil
      if vim.fn.exists(":Oil") ~= 2 then
        return { status = "ERROR", msg = "Oil.nvim not properly loaded" }
      end
      return { status = "OK", msg = "Oil.nvim ready" }
    end,
    function()
      -- Verify Neominimap
      if vim.fn.exists(":Neominimap") ~= 2 then
        return { status = "ERROR", msg = "Neominimap not properly loaded" }
      end
      return { status = "OK", msg = "Neominimap ready" }
    end,
    function()
      -- Verify panel registration
      local left_plugins = panel.get_panel_plugins(panel.PANELS.LEFT)
      local right_plugins = panel.get_panel_plugins(panel.PANELS.RIGHT)
      if #left_plugins == 0 or #right_plugins == 0 then
        return { status = "WARN", msg = "Some panels have no registered plugins" }
      end
      return { status = "OK", msg = "All panels have registered plugins" }
    end
  })
end

return M
