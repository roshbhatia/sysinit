-- Custom TreeSitter query registration
--
-- This file is loaded AFTER TreeSitter is initialized, making it ideal for:
-- - Custom query registration via Lua API
-- - Query modifications that can't be done via .scm files
-- - Dynamic query setup based on runtime conditions
--
-- Note: Static TreeSitter queries (.scm files) should be placed in:
-- queries/<language>/<query-type>.scm (e.g., queries/yaml/injections.scm)
--
-- These are automatically loaded by TreeSitter and don't need Lua registration.

-- Example: Register a custom query for a language
-- local ts = require("nvim-treesitter.query")
-- ts.set_query("mylang", "highlights", [[
--   (identifier) @variable
--   (function_name) @function
-- ]])

-- Example: Add to existing queries
-- local query = ts.get_query("lua", "highlights")
-- ts.set_query("lua", "highlights", query .. [[
--   (custom_node) @custom.highlight
-- ]])

-- The yaml injections in queries/yaml/injections.scm already handle:
-- - Go template injection for Crossplane compositions
-- - JSON/gotmpl injection for AWS IAM policies
-- - Language hints via comments

-- Add any custom query registrations below:
