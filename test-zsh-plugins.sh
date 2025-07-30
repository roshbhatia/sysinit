#!/usr/bin/env bash
# Test script for zsh plugins functionality

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== ZSH Plugin Tests ===${NC}"
echo

# Test 1: Check if plugins are loaded in zsh
echo -e "${YELLOW}Test 1: Plugin Loading Test${NC}"
echo "This test requires you to run in a zsh session after rebuilding."
echo

cat << 'EOF' > /tmp/test-zsh-plugins-load.zsh
#!/usr/bin/env zsh
# Plugin loading test script

echo "=== ZSH Plugin Loading Test ==="
echo

# Test zsh-vi-mode
echo "Testing zsh-vi-mode..."
if [[ -n "$ZVM_VERSION" ]] || typeset -f zvm_define_widget >/dev/null; then
    echo "✅ zsh-vi-mode: LOADED"
else
    echo "❌ zsh-vi-mode: NOT LOADED"
fi

# Test evalcache
echo "Testing evalcache..."
if typeset -f _evalcache >/dev/null; then
    echo "✅ evalcache: LOADED"
else
    echo "❌ evalcache: NOT LOADED"
fi

# Test fzf-tab
echo "Testing fzf-tab..."
if [[ -n "$_FZF_TAB_LOADED" ]] || typeset -f fzf-tab-complete >/dev/null; then
    echo "✅ fzf-tab: LOADED"
else
    echo "❌ fzf-tab: NOT LOADED"
fi

# Test zsh-autosuggestions
echo "Testing zsh-autosuggestions..."
if [[ -n "$ZSH_AUTOSUGGEST_LOADED" ]] || typeset -f _zsh_autosuggest_bind_widgets >/dev/null; then
    echo "✅ zsh-autosuggestions: LOADED"
else
    echo "❌ zsh-autosuggestions: NOT LOADED"
fi

# Test fast-syntax-highlighting
echo "Testing fast-syntax-highlighting..."
if [[ -n "$FAST_HIGHLIGHT_VERSION" ]] || typeset -f fast-theme >/dev/null; then
    echo "✅ fast-syntax-highlighting: LOADED"
else
    echo "❌ fast-syntax-highlighting: NOT LOADED"
fi

echo
echo "=== Plugin Loading Test Complete ==="
EOF

chmod +x /tmp/test-zsh-plugins-load.zsh

echo -e "${GREEN}Created plugin loading test: /tmp/test-zsh-plugins-load.zsh${NC}"
echo -e "${YELLOW}Run this in zsh after rebuilding: zsh /tmp/test-zsh-plugins-load.zsh${NC}"
echo

# Test 2: Check fzf-tab preview functionality
echo -e "${YELLOW}Test 2: FZF-Tab Preview Test${NC}"
echo "This test verifies the fzf-tab preview functionality."
echo

cat << 'EOF' > /tmp/test-fzf-tab-preview.zsh
#!/usr/bin/env zsh
# FZF-Tab preview test script

echo "=== FZF-Tab Preview Test ==="
echo

# Check if fzf-preview command exists
if command -v fzf-preview &>/dev/null; then
    echo "✅ fzf-preview command: AVAILABLE"
    
    # Test preview with a sample file
    echo "Testing preview with README.md..."
    if [[ -f "README.md" ]]; then
        echo "Preview output:"
        fzf-preview README.md | head -5
        echo "..."
        echo "✅ Preview test: PASSED"
    else
        echo "❌ README.md not found for testing"
    fi
else
    echo "❌ fzf-preview command: NOT AVAILABLE"
fi

# Check zstyle configuration
echo
echo "Checking fzf-tab zstyle configuration..."
zstyle -L ':fzf-tab:*' | grep -E "(fzf-preview|use-fzf-default-opts)" || echo "❌ fzf-tab zstyle not configured"

echo
echo "=== FZF-Tab Preview Test Complete ==="
echo
echo "To test interactively:"
echo "1. Type 'ls ' and press TAB"
echo "2. Navigate through completions - you should see previews"
echo "3. Try 'cd ' and press TAB to see directory previews"
EOF

chmod +x /tmp/test-fzf-tab-preview.zsh

echo -e "${GREEN}Created fzf-tab preview test: /tmp/test-fzf-tab-preview.zsh${NC}"
echo -e "${YELLOW}Run this in zsh after rebuilding: zsh /tmp/test-fzf-tab-preview.zsh${NC}"
echo

# Test 3: Performance test
echo -e "${YELLOW}Test 3: Shell Startup Performance Test${NC}"
echo "This test measures zsh startup time with all plugins."
echo

cat << 'EOF' > /tmp/test-zsh-performance.zsh
#!/usr/bin/env zsh
# ZSH performance test script

echo "=== ZSH Performance Test ==="
echo

# Test startup time
echo "Measuring zsh startup time (5 runs)..."
total_time=0
runs=5

for i in {1..$runs}; do
    start_time=$(date +%s.%N)
    zsh -i -c exit 2>/dev/null
    end_time=$(date +%s.%N)
    
    duration=$(echo "$end_time - $start_time" | bc -l)
    total_time=$(echo "$total_time + $duration" | bc -l)
    
    printf "Run %d: %.3f seconds\n" $i $duration
done

average_time=$(echo "scale=3; $total_time / $runs" | bc -l)
echo
printf "Average startup time: %.3f seconds\n" $average_time

# Performance thresholds
if (( $(echo "$average_time < 0.5" | bc -l) )); then
    echo "✅ Performance: EXCELLENT (< 0.5s)"
elif (( $(echo "$average_time < 1.0" | bc -l) )); then
    echo "✅ Performance: GOOD (< 1.0s)"
elif (( $(echo "$average_time < 2.0" | bc -l) )); then
    echo "⚠️  Performance: ACCEPTABLE (< 2.0s)"
else
    echo "❌ Performance: SLOW (>= 2.0s)"
fi

echo
echo "=== Performance Test Complete ==="
EOF

# Check if bc is available for the performance test
if ! command -v bc &>/dev/null; then
    echo -e "${YELLOW}Warning: 'bc' command not found. Performance test may not work.${NC}"
fi

chmod +x /tmp/test-zsh-performance.zsh

echo -e "${GREEN}Created performance test: /tmp/test-zsh-performance.zsh${NC}"
echo -e "${YELLOW}Run this in zsh after rebuilding: zsh /tmp/test-zsh-performance.zsh${NC}"
echo

echo -e "${BLUE}=== Test Summary ===${NC}"
echo -e "${GREEN}✅ Created 3 test scripts for zsh plugins${NC}"
echo -e "${GREEN}✅ Updated zsh-autosuggestions to latest commit${NC}"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Run 'darwin-rebuild switch --flake .' to apply changes"
echo "2. Open a new zsh shell"
echo "3. Run the test scripts to verify everything works"
echo
echo -e "${BLUE}Test script locations:${NC}"
echo "- Plugin loading: /tmp/test-zsh-plugins-load.zsh"
echo "- FZF-Tab preview: /tmp/test-fzf-tab-preview.zsh"  
echo "- Performance: /tmp/test-zsh-performance.zsh"