#!/usr/bin/env bash
# Test script to validate fzf-preview functionality

set -e

echo "Testing fzf-preview script..."
echo "=============================="

# Test 1: Preview a file
echo "Test 1: Previewing this script file"
echo "-----------------------------------"
./modules/home/configurations/utils/fzf-preview ./test-fzf-preview.sh
echo

# Test 2: Preview a directory
echo "Test 2: Previewing modules directory"
echo "------------------------------------"
./modules/home/configurations/utils/fzf-preview ./modules
echo

# Test 3: Preview non-existent file
echo "Test 3: Previewing non-existent file"
echo "------------------------------------"
./modules/home/configurations/utils/fzf-preview ./non-existent-file
echo

# Test 4: Test with grep-style line numbers
echo "Test 4: Testing grep-style format (file:line)"
echo "----------------------------------------------"
./modules/home/configurations/utils/fzf-preview "./test-fzf-preview.sh:10"
echo

echo "Test completed!"
echo "==============="
echo
echo "Now you can:"
echo "1. Run 'darwin-rebuild switch --flake .' to apply the debug configuration"
echo "2. Test fzf-tab completion (e.g., 'ls <TAB>')"
echo "3. Check /tmp/fzf-tab-debug.log to see what variables are available"
echo "4. Once you understand the variables, we can fix the fzf-tab preview"