-- Additional theme overrides that apply after all plugins load
--
-- This file is loaded AFTER all regular plugins, making it ideal for:
-- - Static highlight overrides that should apply to all themes
-- - Corrections to plugin-provided highlights
-- - Global visual customizations
--
-- Note: Theme-specific dynamic overrides are handled in:
-- lua/sysinit/plugins/ui/themes/overrides.lua
--
-- The theme system already applies semantic color-based overrides via
-- an autocommand on ColorScheme events. This file is for additional
-- user-defined static overrides.

-- Example: Override visual selection for all themes
-- vim.api.nvim_set_hl(0, "Visual", { bg = "#3a3a3a", fg = "NONE" })

-- Example: Make floating windows always transparent
-- vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })

-- Example: Customize search highlighting
-- vim.api.nvim_set_hl(0, "Search", { bg = "#ffff00", fg = "#000000", bold = true })

-- Add your custom highlight overrides below:
