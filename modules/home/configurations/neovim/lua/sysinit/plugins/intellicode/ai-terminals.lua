-- Legacy ai-terminals.lua - now delegates to unified AI system
local M = {}

-- Forward everything to the new unified AI system
local ai = require("sysinit.ai")

-- Export the terminals module for compatibility
return ai.terminals_module()
