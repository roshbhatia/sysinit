#!/bin/bash

# Colors
BLUE='\033[1;34m'
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get Neovim config directory path
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
NVIM_CONFIG_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

# Simple test runner for Neovim config
echo -e "${BLUE}Testing Neovim configuration...${NC}"

# Go to the Neovim config directory
cd "$NVIM_CONFIG_DIR"

# Run Neovim with the config directly
NVIM_APPNAME="sysinit-nvim" nvim -u init.lua "$@"

# Check exit code
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Neovim test completed successfully${NC}"
  exit 0
else
  echo -e "${RED}Neovim test failed${NC}"
  exit 1
fi