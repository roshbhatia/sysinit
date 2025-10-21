-- ast-grep Examples and Common Patterns
-- This file documents common ast-grep usage patterns for AI agents

local M = {}

M.examples = {
  typescript = {
    -- Find all async functions
    async_functions = "async function $NAME($$$ARGS) { $$$BODY }",
    
    -- Find React components with hooks
    react_hooks = "function $NAME() { $$$ useState($$$) $$$ }",
    
    -- Find all imports from a specific module
    imports = "import { $$$IMPORTS } from '$MODULE'",
    
    -- Find console.log statements
    console_log = "console.log($$$)",
    
    -- Find try-catch blocks
    try_catch = "try { $$$TRY } catch ($ERR) { $$$CATCH }",
  },
  
  python = {
    -- Find all class definitions
    classes = "class $NAME: $$$BODY",
    
    -- Find all function definitions with decorators
    decorated_functions = "@$DECORATOR\ndef $NAME($$$): $$$",
    
    -- Find all import statements
    imports = "from $MODULE import $$$",
    
    -- Find list comprehensions
    list_comp = "[$EXPR for $VAR in $ITER]",
  },
  
  go = {
    -- Find all error handling
    error_check = "if err != nil { $$$ }",
    
    -- Find struct definitions
    structs = "type $NAME struct { $$$ }",
    
    -- Find interface implementations
    interfaces = "type $NAME interface { $$$ }",
    
    -- Find goroutine launches
    goroutines = "go $FUNC($$$)",
  },
  
  lua = {
    -- Find all require statements
    requires = "require($MODULE)",
    
    -- Find all function definitions
    functions = "function $NAME($$$) $$$ end",
    
    -- Find local variable declarations
    locals = "local $VAR = $VALUE",
  },
  
  nix = {
    -- Find all mkIf conditions
    mkif = "lib.mkIf $CONDITION $BODY",
    
    -- Find all package definitions
    packages = "pkgs.$PACKAGE",
    
    -- Find all attribute sets
    attrsets = "{ $$$ATTRS }",
  },
}

-- Generate a prompt template for AI agents
function M.generate_prompt_template(lang, pattern_name)
  local pattern = M.examples[lang] and M.examples[lang][pattern_name]
  
  if not pattern then
    return string.format(
      "Language '%s' or pattern '%s' not found. Available: %s",
      lang,
      pattern_name,
      vim.inspect(M.examples)
    )
  end
  
  return string.format(
    "Use ast-grep to search for: %s\nCommand: ast-grep -l %s -p '%s'",
    pattern_name,
    lang,
    pattern
  )
end

return M
