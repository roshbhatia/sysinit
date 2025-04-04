#!/bin/bash
#
# Test script for the smart-resize.sh functionality
#

# Create test directory structure
TEST_DIR="$HOME/.config/sysinit/tests"
mkdir -p "$TEST_DIR"
echo "Using test directory: $TEST_DIR"

# Create mock aerospace command
cat > "$TEST_DIR/aerospace" << 'EOF'
#!/bin/bash
# Mock aerospace command - logs calls to file
echo "[MOCK] aerospace $@" >> "$TEST_DIR/aerospace-calls.log"
EOF
chmod +x "$TEST_DIR/aerospace"

# Fix path to log file in mock command
sed -i '' "s|\$TEST_DIR/aerospace-calls.log|$TEST_DIR/aerospace-calls.log|g" "$TEST_DIR/aerospace"

# Clear previous log if it exists
rm -f "$TEST_DIR/aerospace-calls.log"
touch "$TEST_DIR/aerospace-calls.log"
chmod 644 "$TEST_DIR/aerospace-calls.log"

# Copy the actual script we're testing
TEST_SCRIPT="$TEST_DIR/smart-resize.sh"
cp "$(dirname "$0")/../modules/home/aerospace/smart-resize.sh" "$TEST_SCRIPT"

# Modify the script to use our mock
sed -i '' "s|aerospace resize|$TEST_DIR/aerospace resize|g" "$TEST_SCRIPT"

# Set up environment for test
export XDG_DATA_HOME="$TEST_DIR/local/share"
mkdir -p "$XDG_DATA_HOME/aerospace"
export PATH="$TEST_DIR:$PATH"

echo "=== STARTING SMART-RESIZE TESTS ==="

# Just verify the basic cycling behavior
echo "Testing the 5-size cycle:"
rm -f "$XDG_DATA_HOME/aerospace/last_resize"

# Execute the script 7 times and capture outputs
for i in {1..7}; do
  echo "Run $i:"
  bash "$TEST_SCRIPT" "right"
  if [ -f "$XDG_DATA_HOME/aerospace/last_resize" ]; then
    SIZE=$(cat "$XDG_DATA_HOME/aerospace/last_resize")
    echo "Current size: $SIZE%"
  else
    echo "No size file found!"
  fi
  echo ""
done

# Test vertical direction
echo "Testing with 'down' direction:"
bash "$TEST_SCRIPT" "down"
if [ -f "$XDG_DATA_HOME/aerospace/last_resize" ]; then
  SIZE=$(cat "$XDG_DATA_HOME/aerospace/last_resize")
  echo "Size after 'down': $SIZE%"
else
  echo "No size file found!"
fi

# Check if aerospace was called
echo "Checking aerospace calls:"
if [ -f "$TEST_DIR/aerospace-calls.log" ]; then
  CALLS=$(cat "$TEST_DIR/aerospace-calls.log")
  echo "Total number of calls: $(grep -c "aerospace" "$TEST_DIR/aerospace-calls.log")"
  echo "Sample of calls:"
  head -n 3 "$TEST_DIR/aerospace-calls.log"
else
  echo "No calls logged (missing log file)."
fi

echo "=== TESTS COMPLETE ==="