#!/bin/zsh
# Zsh config test script

# Test: vi mode
if [[ $KEYMAP != vicmd && $KEYMAP != viins ]]; then
  echo "FAIL: vi mode not enabled"
  exit 1
else
  echo "PASS: vi mode enabled"
fi

# Test: Atuin
if ! command -v atuin >/dev/null; then
  echo "FAIL: atuin not found"
  exit 1
else
  echo "PASS: atuin found"
fi

# Test: OMP
if ! command -v oh-my-posh >/dev/null; then
  echo "FAIL: oh-my-posh not found"
  exit 1
else
  echo "PASS: oh-my-posh found"
fi

# Test: Direnv
if ! command -v direnv >/dev/null; then
  echo "FAIL: direnv not found"
  exit 1
else
  echo "PASS: direnv found"
fi

# Test: uv
if ! command -v uv >/dev/null; then
  echo "FAIL: uv not found"
  exit 1
else
  echo "PASS: uv found"
fi

# Test: virtualenv
if ! command -v virtualenv >/dev/null; then
  echo "FAIL: virtualenv not found"
  exit 1
else
  echo "PASS: virtualenv found"
fi

# Test: zoxide
if ! command -v zoxide >/dev/null; then
  echo "FAIL: zoxide not found"
  exit 1
else
  echo "PASS: zoxide found"
fi
