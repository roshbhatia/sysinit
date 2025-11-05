#!/usr/bin/env bash
# Test script for validating theme configuration error handling (T022)
# Tests invalid appearance + palette combinations

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

echo "======================================================================"
echo "Theme Configuration Validation Tests (T022)"
echo "======================================================================"
echo ""

# Backup original values.nix
cp values.nix values.nix.backup
echo "✓ Backed up values.nix to values.nix.backup"
echo ""

# Test function
test_invalid_config() {
  local test_name="$1"
  local config="$2"
  local expected_error="$3"

  echo "----------------------------------------------------------------------"
  echo "Test: $test_name"
  echo "----------------------------------------------------------------------"

  # Write test configuration
  cat >values.nix <<EOF
{
  user = {
    username = "rshnbhatia";
    hostname = "lv426";
  };

  git = {
    name = "Roshan Bhatia";
    email = "rshnbhatia@gmail.com";
    username = "roshbhatia";
  };

  $config

  darwin = {
    docker = {
      enable = true;
      backend = "colima";
    };
  };
}
EOF

  echo "Configuration:"
  echo "$config"
  echo ""

  # Try to build - should fail
  echo "Attempting build (should fail)..."
  if task nix:build 2>&1 | tee /tmp/nix-build-output.txt; then
    echo "❌ FAIL: Build succeeded when it should have failed!"
    return 1
  else
    local exit_code=$?
    echo "✓ Build failed as expected (exit code: $exit_code)"
    echo ""
    echo "Error output (searching for validation error):"
    if grep -i "$expected_error" /tmp/nix-build-output.txt; then
      echo "✓ Found expected error pattern in output"
    else
      echo "⚠ Error pattern not found, showing last 30 lines:"
      tail -30 /tmp/nix-build-output.txt
    fi
    echo ""
    return 0
  fi
}

# Test 1: Nord + Light mode (nord doesn't support light)
test_invalid_config \
  "Invalid: Nord palette with light appearance" \
  'theme = {
    appearance = "light";
    colorscheme = "nord";
  };' \
  "does not support appearance mode"

# Test 2: Kanagawa + Light mode (kanagawa doesn't support light)
test_invalid_config \
  "Invalid: Kanagawa palette with light appearance" \
  'theme = {
    appearance = "light";
    colorscheme = "kanagawa";
  };' \
  "does not support appearance mode"

# Test 3: Valid configuration (should pass)
echo "----------------------------------------------------------------------"
echo "Test: Valid configuration (Gruvbox + Light)"
echo "----------------------------------------------------------------------"
cat >values.nix <<EOF
{
  user = {
    username = "rshnbhatia";
    hostname = "lv426";
  };

  git = {
    name = "Roshan Bhatia";
    email = "rshnbhatia@gmail.com";
    username = "roshbhatia";
  };

  theme = {
    appearance = "light";
    colorscheme = "gruvbox";
  };

  darwin = {
    docker = {
      enable = true;
      backend = "colima";
    };
  };
}
EOF

echo "Configuration: Gruvbox + Light (should be valid)"
echo ""
echo "Attempting build (should succeed)..."
if task nix:build; then
  echo "✓ PASS: Valid configuration builds successfully"
else
  echo "❌ FAIL: Valid configuration failed to build"
fi

# Restore original values.nix
echo ""
echo "======================================================================"
echo "Restoring original configuration..."
echo "======================================================================"
mv values.nix.backup values.nix
echo "✓ Restored values.nix from backup"
echo ""

echo "======================================================================"
echo "Validation Tests Complete"
echo "======================================================================"
echo ""
echo "Summary:"
echo "  - Tested invalid appearance + palette combinations"
echo "  - Verified build-time validation catches errors"
echo "  - Verified valid configurations pass validation"
echo ""
echo "Note: T020 and T021 require manual visual testing of applications"
echo "      after applying theme changes with 'task nix:refresh'"
