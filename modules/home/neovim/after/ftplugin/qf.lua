-- after/ftplugin/qf.lua
-- Quickfix buffer-local configuration
-- This file runs AFTER all plugin ftplugin files (including bqf)

-- Set CodeDiff keymaps if the module is loaded
-- These override bqf's default <CR> behavior when in a CodeDiff quickfix list
if _G.CodeDiffExtensions and _G.CodeDiffExtensions.setup_qf_keymaps then
  _G.CodeDiffExtensions.setup_qf_keymaps()
end
