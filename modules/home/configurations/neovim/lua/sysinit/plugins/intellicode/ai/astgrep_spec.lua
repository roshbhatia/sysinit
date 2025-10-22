-- Tests for improved ast-grep integration
-- Run with: nvim --headless -c "PlenaryBustedDirectory lua/sysinit/plugins/intellicode/ai/ {minimal_init = 'init.lua'}"

local placeholders = require("sysinit.plugins.intellicode.ai.placeholders")
local examples = require("sysinit.plugins.intellicode.ai.astgrep-examples")

describe("ast-grep placeholder", function()
  it("should have single @astgrep placeholder", function()
    local found = false
    for _, ph in ipairs(placeholders.placeholder_descriptions) do
      if ph.token == "@astgrep" then
        found = true
        assert.equals("Interactive ast-grep search (opens picker)", ph.description)
        break
      end
    end
    assert.is_true(found, "@astgrep placeholder should be registered")
  end)

  it("should not have old placeholder variations", function()
    local old_placeholders = { "@astgrep-pattern", "@astgrep-lang", "@astgrep-preview" }
    for _, old_token in ipairs(old_placeholders) do
      local found = false
      for _, ph in ipairs(placeholders.placeholder_descriptions) do
        if ph.token == old_token then
          found = true
          break
        end
      end
      assert.is_false(found, string.format("%s should not exist", old_token))
    end
  end)

  it("should detect @astgrep placeholder", function()
    local input = "test @astgrep query"
    local contains_astgrep = input:find("@astgrep", 1, true) ~= nil
    assert.is_true(contains_astgrep)
  end)

  it("should not interfere with other placeholders", function()
    local input = "@buffer @cursor"
    local result = placeholders.apply_placeholders(input)
    assert.is_not_nil(result)
    -- Should have expanded other placeholders
    assert.is_not.equal(result, input)
  end)
end)

describe("ast-grep picker module", function()
  local picker = require("sysinit.plugins.editor.astgrep-picker")

  it("should expose start_picker function", function()
    assert.is_function(picker.start_picker)
  end)

  it("should expose repeat_last_search function", function()
    assert.is_function(picker.repeat_last_search)
  end)

  it("should expose search_with_pattern function", function()
    assert.is_function(picker.search_with_pattern)
  end)
end)

describe("ast-grep examples", function()
  it("should have examples for multiple languages", function()
    assert.is_table(examples.examples.typescript)
    assert.is_table(examples.examples.python)
    assert.is_table(examples.examples.go)
    assert.is_table(examples.examples.lua)
    assert.is_table(examples.examples.nix)
  end)

  it("should have helper functions", function()
    assert.is_function(examples.get_languages)
    assert.is_function(examples.get_patterns)
    assert.is_function(examples.generate_placeholder)
  end)

  it("should return list of languages", function()
    local languages = examples.get_languages()
    assert.is_table(languages)
    assert.is_true(#languages > 0)
    assert.is_true(vim.tbl_contains(languages, "typescript"))
    assert.is_true(vim.tbl_contains(languages, "python"))
  end)

  it("should return patterns for a language", function()
    local patterns = examples.get_patterns("typescript")
    assert.is_table(patterns)
    assert.is_true(#patterns > 0)
  end)

  it("should return empty table for unknown language", function()
    local patterns = examples.get_patterns("nonexistent")
    assert.is_table(patterns)
    assert.equals(0, #patterns)
  end)

  it("should generate placeholders", function()
    local placeholder = examples.generate_placeholder("typescript", "async_functions", false)
    assert.is_string(placeholder)
    assert.is_true(placeholder:match("@astgrep") ~= nil)
  end)

  it("should generate preview placeholders", function()
    local placeholder = examples.generate_placeholder("typescript", "async_functions", true)
    assert.is_string(placeholder)
    assert.is_true(placeholder:match("@astgrep") ~= nil)
  end)
end)

describe("interactive placeholder handler", function()
  it("should export handle_interactive_astgrep", function()
    assert.is_function(placeholders.handle_interactive_astgrep)
  end)

  it("should detect @astgrep in input", function()
    local input = "test @astgrep query"
    local has_astgrep = input:find("@astgrep", 1, true) ~= nil
    assert.is_true(has_astgrep)
  end)

  it("should not detect @astgrep when not present", function()
    local input = "test @buffer @cursor"
    local has_astgrep = input:find("@astgrep", 1, true) ~= nil
    assert.is_false(has_astgrep)
  end)
end)

-- Integration test for the improved workflow
describe("improved ast-grep workflow", function()
  it("should support simplified pattern access", function()
    -- 1. Examples are organized by language
    local languages = examples.get_languages()
    assert.is_true(#languages > 0)

    -- 2. Patterns are accessible per language
    local patterns = examples.get_patterns("typescript")
    assert.is_true(#patterns > 0)

    -- 3. Pattern content is accessible
    local pattern_name = patterns[1]
    local pattern = examples.examples.typescript[pattern_name]
    assert.is_string(pattern)
    assert.is_true(#pattern > 0)
  end)

  it("should provide cleaner API surface", function()
    -- Single placeholder token
    assert.is_not_nil(placeholders.handle_interactive_astgrep)

    -- Picker module with clear functions
    local picker = require("sysinit.plugins.editor.astgrep-picker")
    assert.is_function(picker.start_picker)
    assert.is_function(picker.repeat_last_search)

    -- Examples module with query functions
    assert.is_function(examples.get_languages)
    assert.is_function(examples.get_patterns)
  end)

  it("should have no syntax to memorize", function()
    -- User only needs to know: @astgrep
    -- Everything else is interactive via picker

    local description = nil
    for _, ph in ipairs(placeholders.placeholder_descriptions) do
      if ph.token == "@astgrep" then
        description = ph.description
        break
      end
    end

    assert.is_string(description)
    assert.is_true(description:match("[Ii]nteractive") ~= nil)
  end)
end)

describe("backward compatibility", function()
  it("should still support non-ast-grep placeholders", function()
    local input = "@buffer @cursor @diagnostic"
    local result = placeholders.apply_placeholders(input)
    assert.is_string(result)
    -- At minimum should not crash
  end)

  it("should handle empty input", function()
    local result = placeholders.apply_placeholders("")
    assert.equals("", result)
  end)

  it("should handle nil input", function()
    local result = placeholders.apply_placeholders(nil)
    assert.is_nil(result)
  end)
end)
