return function(theme_config)
  local background = theme_config.variant or "medium"
  if background ~= "hard" and background ~= "medium" and background ~= "soft" then
    background = "medium"
  end

  vim.g.gruvbox_material_background = background
  vim.g.gruvbox_material_better_performance = 1
  vim.g.gruvbox_material_enable_italic = 1
  vim.g.gruvbox_material_disable_italic_comment = 0
  vim.g.gruvbox_material_cursor = "auto"
  vim.g.gruvbox_material_transparent_background = 2
  vim.g.gruvbox_material_dim_inactive_windows = 0
  vim.g.gruvbox_material_sign_column_background = "none"
  vim.g.gruvbox_material_spell_foreground = "none"
  vim.g.gruvbox_material_ui_contrast = "low"
  vim.g.gruvbox_material_show_eob = 0
  vim.g.gruvbox_material_float_style = "bright"
  vim.g.gruvbox_material_diagnostic_text_highlight = 0
  vim.g.gruvbox_material_diagnostic_line_highlight = 0
  vim.g.gruvbox_material_diagnostic_virtual_text = "grey"
  vim.g.gruvbox_material_current_word = "bold"
  vim.g.gruvbox_material_inlay_hints_background = "dimmed"
  vim.g.gruvbox_material_disable_terminal_colors = 0

  return {}
end
