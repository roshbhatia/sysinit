#!/usr/bin/env bash
# Script to check for updates to zsh plugins and calculate new hashes

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== ZSH Plugin Update Checker ===${NC}"
echo

# Current plugin versions from zsh.nix
declare -A current_plugins=(
    ["jeffreytse/zsh-vi-mode"]="v0.11.0"
    ["mroth/evalcache"]="3153dcd77a2c93aa8fdf5d17cece7edb1aa3e040"
    ["Aloxaf/fzf-tab"]="v1.2.0"
    ["zsh-users/zsh-autosuggestions"]="0e810e5afa27acbd074398eefbe28d13005dbc15"
    ["zdharma-continuum/fast-syntax-highlighting"]="cf318e06a9b7c9f2219d78f41b46fa6e06011fd9"
)

declare -A current_hashes=(
    ["jeffreytse/zsh-vi-mode"]="sha256-xbchXJTFWeABTwq6h4KWLh+EvydDrDzcY9AQVK65RS8="
    ["mroth/evalcache"]="GAjsTQJs9JdBEf9LGurme3zqXN//kVUM2YeBo0sCR2c="
    ["Aloxaf/fzf-tab"]="sha256-q26XVS/LcyZPRqDNwKKA9exgBByE0muyuNb0Bbar2lY="
    ["zsh-users/zsh-autosuggestions"]="sha256-85aw9OM2pQPsWklXjuNOzp9El1MsNb+cIiZQVHUzBnk="
    ["zdharma-continuum/fast-syntax-highlighting"]="sha256-RVX9ZSzjBW3LpFs2W86lKI6vtcvDWP6EPxzeTcRZua4="
)

# Function to get latest tag for a repository
get_latest_tag() {
    local repo="$1"
    echo -e "${YELLOW}Checking latest tag for $repo...${NC}"
    
    # Try to get latest tag, fallback to main branch if no tags
    if latest_tag=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | grep '"tag_name":' | cut -d'"' -f4 2>/dev/null); then
        if [[ -n "$latest_tag" && "$latest_tag" != "null" ]]; then
            echo "$latest_tag"
            return 0
        fi
    fi
    
    # Fallback: get latest commit from main/master branch
    for branch in main master; do
        if latest_commit=$(curl -s "https://api.github.com/repos/$repo/commits/$branch" | grep '"sha":' | head -1 | cut -d'"' -f4 2>/dev/null); then
            if [[ -n "$latest_commit" && "$latest_commit" != "null" ]]; then
                echo "${latest_commit:0:40}"  # Full 40-char hash
                return 0
            fi
        fi
    done
    
    echo "unknown"
    return 1
}

# Function to calculate nix hash for a GitHub repository
calculate_nix_hash() {
    local repo="$1"
    local rev="$2"
    echo -e "${YELLOW}Calculating hash for $repo @ $rev...${NC}"
    
    # Use nix-prefetch-github if available, otherwise use nix-prefetch-url
    if command -v nix-prefetch-github &> /dev/null; then
        owner=$(echo "$repo" | cut -d'/' -f1)
        repo_name=$(echo "$repo" | cut -d'/' -f2)
        nix-prefetch-github "$owner" "$repo_name" --rev "$rev" 2>/dev/null | grep '"sha256":' | cut -d'"' -f4 || echo "failed"
    else
        # Fallback method using nix-prefetch-url
        url="https://github.com/$repo/archive/$rev.tar.gz"
        nix-prefetch-url --unpack "$url" 2>/dev/null || echo "failed"
    fi
}

echo -e "${BLUE}Current plugin versions:${NC}"
for repo in "${!current_plugins[@]}"; do
    echo -e "  $repo: ${current_plugins[$repo]}"
done
echo

echo -e "${BLUE}Checking for updates...${NC}"
echo

updates_available=false

for repo in "${!current_plugins[@]}"; do
    echo -e "${BLUE}--- $repo ---${NC}"
    current_rev="${current_plugins[$repo]}"
    current_hash="${current_hashes[$repo]}"
    
    echo -e "Current: $current_rev"
    
    # Get latest version
    latest_rev=$(get_latest_tag "$repo")
    
    if [[ "$latest_rev" == "unknown" ]]; then
        echo -e "${RED}❌ Failed to get latest version${NC}"
        continue
    fi
    
    echo -e "Latest:  $latest_rev"
    
    if [[ "$current_rev" != "$latest_rev" ]]; then
        echo -e "${GREEN}✅ Update available!${NC}"
        updates_available=true
        
        # Calculate new hash
        new_hash=$(calculate_nix_hash "$repo" "$latest_rev")
        
        if [[ "$new_hash" != "failed" && -n "$new_hash" ]]; then
            echo -e "New hash: $new_hash"
            
            # Store update info for later use
            echo "$repo,$current_rev,$latest_rev,$current_hash,$new_hash" >> /tmp/zsh-plugin-updates.csv
        else
            echo -e "${RED}❌ Failed to calculate hash${NC}"
        fi
    else
        echo -e "${GREEN}✅ Up to date${NC}"
    fi
    echo
done

if [[ "$updates_available" == "true" ]]; then
    echo -e "${GREEN}=== Updates Available ===${NC}"
    echo -e "Update information saved to: ${YELLOW}/tmp/zsh-plugin-updates.csv${NC}"
    echo
    echo -e "${BLUE}To apply updates, the script will modify zsh.nix automatically.${NC}"
    echo -e "${YELLOW}Do you want to apply the updates? (y/N)${NC}"
else
    echo -e "${GREEN}=== All plugins are up to date! ===${NC}"
fi