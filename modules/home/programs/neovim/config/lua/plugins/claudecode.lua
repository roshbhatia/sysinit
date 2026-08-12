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
        -- `"unified"` selects `lua/claudecode/diff_inline.lua`, which upstream
        -- describes as a VS Code-style inline diff: one buffer with the deleted
        -- lines struck through and the added lines interleaved. The default is
        -- `"vertical"`, a split, and a split is the only reason a tab per edit was
        -- tolerable. Inline needs no room, so the tab goes too and reviewing several
        -- edits stops accumulating tabs.
        --
        -- The view is read-only either way: accept and reject stay on
        -- `ClaudeCodeDiffAccept` and `ClaudeCodeDiffDeny`. Editing the proposal
        -- before accepting it is what the working diff is for.
        diff_opts = {
          layout = "unified",
          open_in_new_tab = false,
        },
      }
    end,
  },
}
