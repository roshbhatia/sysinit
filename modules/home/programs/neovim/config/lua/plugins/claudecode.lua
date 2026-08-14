return {
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    cmd = {
      "ClaudeCode",
      "ClaudeCodeFocus",
      "ClaudeCodeSelectModel",
      "ClaudeCodeAdd",
      "ClaudeCodeSend",
      "ClaudeCodeTreeAdd",
      "ClaudeCodeDiffAccept",
      "ClaudeCodeDiffDeny",
    },
    opts = function()
      local choice = vim.g.claudecode_provider or "auto"
      if choice == "auto" then
        local in_wezterm = vim.env.WEZTERM_PANE ~= nil and vim.fn.executable("wezterm") == 1
        choice = in_wezterm and "wezterm" or "snacks"
      end

      local provider = "auto"
      if choice == "wezterm" then
        local ok, wezterm = pcall(require, "utils.wezterm_terminal")
        if ok then
          local p = wezterm.build_provider({ name = "claudecode" })
          if p.is_available() then
            provider = p
          else
            vim.notify("claudecode: wezterm provider unavailable, falling back to snacks", vim.log.levels.WARN)
          end
        end
      end

      return {
        terminal = {
          provider = provider,
          split_side = "right",
          split_width_percentage = 0.4,
        },
        diff_opts = {
          layout = "unified",
          open_in_new_tab = false,
        },
      }
    end,
  },
}
