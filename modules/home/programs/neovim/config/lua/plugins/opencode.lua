return {
  {
    "nickjvandyke/opencode.nvim",
    version = "*",
    dependencies = { "folke/snacks.nvim" },
    config = function()
      local choice = vim.g.opencode_provider or "auto"
      if choice == "auto" then
        local in_wezterm = vim.env.WEZTERM_PANE ~= nil and vim.fn.executable("wezterm") == 1
        choice = in_wezterm and "wezterm" or "snacks"
      end

      local server_opts = nil
      if choice == "wezterm" then
        local ok, wezterm = pcall(require, "utils.wezterm_terminal")
        if ok then
          server_opts = wezterm.build_server_callbacks("opencode --port", {
            name = "opencode",
            percent = 0.35,
          })
        else
          vim.notify("opencode: wezterm util missing, falling back to snacks", vim.log.levels.WARN)
        end
      end

      vim.g.opencode_opts = {
        server = server_opts,
        events = { reload = true },
      }
    end,
  },
}
