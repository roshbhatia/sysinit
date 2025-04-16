#!/usr/bin/env bash

# Script to fetch READMEs for all Neovim dependencies
# It looks for the following pattern in Lua files:
# # sysinit.nvim.readme-url="https://githubusercontentraw.com/wahtever"

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
NEOVIM_DIR="${PROJECT_ROOT}/modules/home/neovim"
README_DIR="${PROJECT_ROOT}/neovim-readmes"

# Create README directory if it doesn't exist
mkdir -p "${README_DIR}"

# Function to extract README URLs from Lua files
function extract_readmes() {
  local files=$(find "${NEOVIM_DIR}" -type f -name "*.lua")
  local count=0
  local found=0
  
  echo -e "${YELLOW}Scanning Lua files for README URLs...${NC}"
  
  for file in ${files}; do
    count=$((count + 1))
    
    # Extract README URL from file
    local readmes=$(grep -o "# sysinit.nvim.readme-url=\"[^\"]*\"" "${file}" || true)
    
    if [[ -n "${readmes}" ]]; then
      found=$((found + 1))
      local filename=$(basename "${file}" .lua)
      
      echo -e "${GREEN}Found README URL in ${filename}${NC}"
      
      # Extract the URL
      local url=$(echo "${readmes}" | sed 's/# sysinit.nvim.readme-url=\"//g' | sed 's/\"//g')
      
      # Download the README
      echo -e "Downloading README from ${url}"
      curl -s "${url}" -o "${README_DIR}/${filename}.md"
      
      if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}Successfully downloaded README for ${filename}${NC}"
      else
        echo -e "${RED}Failed to download README for ${filename}${NC}"
      fi
    fi
  done
  
  echo -e "${YELLOW}Scanned ${count} files, found ${found} README URLs${NC}"
}

# Main function
function main() {
  echo -e "${YELLOW}Fetching READMEs for Neovim dependencies...${NC}"
  extract_readmes
  echo -e "${GREEN}READMEs saved to ${README_DIR}${NC}"
}

main
