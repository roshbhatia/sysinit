#!/bin/bash

# Colors
BLUE='\033[1;34m'
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get the absolute path to the repo root directory
REPO_ROOT=$(git rev-parse --show-toplevel)
if [ -z "$REPO_ROOT" ]; then
  echo -e "${RED}Error: Not in a git repository${NC}"
  exit 1
fi

NVIM_CONFIG_DIR="${REPO_ROOT}/modules/home/neovim"
TEMP_DATA_DIR="${REPO_ROOT}/.local/share/sysinit-nvim"
TEMP_CACHE_DIR="${REPO_ROOT}/.local/cache/sysinit-nvim" 
TEMP_STATE_DIR="${REPO_ROOT}/.local/state/sysinit-nvim"

# Create required directories
mkdir -p "$TEMP_DATA_DIR"
mkdir -p "$TEMP_CACHE_DIR"
mkdir -p "$TEMP_STATE_DIR"

echo -e "${BLUE}Testing Neovim configuration in isolation...${NC}"
echo -e "${YELLOW}Config directory: ${NVIM_CONFIG_DIR}${NC}"
echo -e "${YELLOW}Temporary data directory: ${TEMP_DATA_DIR}${NC}"

# Launch Neovim with the test environment
# Check if the standalone init file exists
if [ -f "${NVIM_CONFIG_DIR}/init_standalone.lua" ]; then
  echo -e "${YELLOW}Using standalone init file for testing${NC}"
  INIT_FILE="${NVIM_CONFIG_DIR}/init_standalone.lua"
else
  echo -e "${YELLOW}Using regular init file${NC}"
  INIT_FILE="${NVIM_CONFIG_DIR}/init.lua"
fi

NVIM_APPNAME="sysinit-nvim" \
XDG_CONFIG_HOME="${REPO_ROOT}" \
XDG_DATA_HOME="${REPO_ROOT}/.local/share" \
XDG_CACHE_HOME="${REPO_ROOT}/.local/cache" \
XDG_STATE_HOME="${REPO_ROOT}/.local/state" \
nvim -u "${INIT_FILE}" "$@"

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo -e "${GREEN}Neovim test completed successfully${NC}"
else
  echo -e "${RED}Neovim test exited with code: ${EXIT_CODE}${NC}"
fi

exit $EXIT_CODE