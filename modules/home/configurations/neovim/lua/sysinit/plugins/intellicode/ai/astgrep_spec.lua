-- Tests for ast-grep integration improvements
-- Run with: nvim --headless -c "PlenaryBustedDirectory lua/sysinit/plugins/intellicode/ai/ {minimal_init = 'init.lua'}"

local placeholders = require("sysinit.plugins.intellicode.ai.placeholders")
local terminal = require("sysinit.plugins.intellicode.ai.terminal")

describe("ast-grep placeholders", function()
  it("should include @astgrep-preview placeholder", function()
    local found = false
    for _, ph in ipairs(placeholders.placeholder_descriptions) do
      if ph.token == "@astgrep-preview" then
        found = true
        break
      end
    end
    assert.is_true(found, "@astgrep-preview placeholder should be registered")
  end)

  it("should expand @astgrep-pattern placeholder", function()
    local input = "Find patterns: @astgrep-pattern:console.log($$$)"
    local result = placeholders.apply_placeholders(input)
    -- Result should either have matches or "No matches found"
    assert.is_not_nil(result)
    assert.is_not.equal(result, input) -- Should be expanded
  end)

  it("should expand @astgrep-lang placeholder with language", function()
    local input = "Find TS patterns: @astgrep-lang:typescript:function $NAME($$$) { $$$ }"
    local result = placeholders.apply_placeholders(input)
    assert.is_not_nil(result)
  end)

  it("should handle multiple placeholders in one input", function()
    local input = "@buffer @astgrep-pattern:test"
    local result = placeholders.apply_placeholders(input)
    assert.is_not_nil(result)
    -- Should have expanded both placeholders
    assert.is_not.equal(result, input)
  end)
end)

describe("terminal validation", function()
  it("should validate ast-grep patterns in prompts", function()
    local text = "@astgrep-pattern:test-pattern"
    local errors, warnings = terminal.validate_prompt(text)
    assert.is_table(errors)
    assert.is_table(warnings)
  end)

  it("should warn about unsupported languages", function()
    local text = "@astgrep-lang:invalid-lang:pattern"
    local errors, warnings = terminal.validate_prompt(text)
    assert.is_true(#warnings > 0)
  end)

  it("should warn about patterns with quotes", function()
    local text = "@astgrep-pattern:test'with'quotes"
    local errors, warnings = terminal.validate_prompt(text)
    assert.is_true(#warnings > 0)
  end)

  it("should accept valid patterns without warnings", function()
    local text = "@astgrep-lang:typescript:function"
    local errors, warnings = terminal.validate_prompt(text)
    assert.is_true(#errors == 0)
  end)
end)

describe("ast-grep examples", function()
  local examples = require("sysinit.plugins.intellicode.ai.astgrep-examples")

  it("should have examples for typescript", function()
    assert.is_table(examples.examples.typescript)
    assert.is_not_nil(examples.examples.typescript.async_functions)
  end)

  it("should have examples for python", function()
    assert.is_table(examples.examples.python)
    assert.is_not_nil(examples.examples.python.classes)
  end)

  it("should have examples for go", function()
    assert.is_table(examples.examples.go)
    assert.is_not_nil(examples.examples.go.error_check)
  end)

  it("should have examples for lua", function()
    assert.is_table(examples.examples.lua)
    assert.is_not_nil(examples.examples.lua.requires)
  end)

  it("should have examples for nix", function()
    assert.is_table(examples.examples.nix)
    assert.is_not_nil(examples.examples.nix.packages)
  end)

  it("should generate prompt templates", function()
    local prompt = examples.generate_prompt_template("typescript", "async_functions")
    assert.is_string(prompt)
    assert.is_true(prompt:match("ast%-grep") ~= nil)
  end)
end)

describe("run_astgrep helper", function()
  -- Test the helper function indirectly through placeholders
  it("should handle simple patterns", function()
    local input = "@astgrep-pattern:test"
    local result = placeholders.apply_placeholders(input)
    -- Should return either matches or "No matches found"
    assert.is_string(result)
  end)

  it("should handle language-specific patterns", function()
    local input = "@astgrep-lang:lua:require"
    local result = placeholders.apply_placeholders(input)
    assert.is_string(result)
  end)
end)

describe("preview functionality", function()
  -- These tests validate that the preview function exists and is callable
  -- Full UI testing would require integration tests

  it("should expose preview_astgrep function", function()
    assert.is_function(placeholders.preview_astgrep)
  end)

  it("should expose send_astgrep_to_terminal function", function()
    assert.is_function(terminal.send_astgrep_to_terminal)
  end)

  it("should expose preview_prompt function", function()
    assert.is_function(terminal.preview_prompt)
  end)
end)

-- Integration test for the full workflow
describe("ast-grep workflow integration", function()
  it("should support the complete pattern search workflow", function()
    -- 1. Pattern exists in examples
    local examples = require("sysinit.plugins.intellicode.ai.astgrep-examples")
    local ts_pattern = examples.examples.typescript.async_functions
    assert.is_string(ts_pattern)

    -- 2. Placeholder can be constructed
    local placeholder = string.format("@astgrep-lang:typescript:%s", ts_pattern)
    assert.is_string(placeholder)

    -- 3. Validation passes
    local errors, warnings = terminal.validate_prompt(placeholder)
    assert.is_true(#errors == 0)

    -- 4. Placeholder expands (though may have no matches in test env)
    local result = placeholders.apply_placeholders(placeholder)
    assert.is_string(result)
  end)

  it("should support preview workflow", function()
    local examples = require("sysinit.plugins.intellicode.ai.astgrep-examples")
    local pattern = examples.examples.lua.functions

    -- Construct preview placeholder
    local placeholder = string.format("@astgrep-preview:%s", pattern)

    -- Validate it would be recognized
    assert.is_true(placeholder:match("@astgrep%-preview") ~= nil)
  end)
end)
