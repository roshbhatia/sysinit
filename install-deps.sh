#!/usr/bin/env bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

function handle_error {
    echo -e "${RED}Error: $1${NC}"
    echo "Installation failed. Please check the error message above."
    exit 1
}

if [ "$EUID" -eq 0 ]; then
    handle_error "Please do not run this script as root or with sudo."
fi

# Print banner
echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}              Sysinit Deps Installer                        ${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""
echo "This script will install the prerequisites needed for sysinit:"
echo "- Xcode Command Line Tools"
echo "- Nix package manager"
echo "- Nix Flakes (configuration)"
echo ""

echo -e "${BLUE}Step 1: Installing Xcode Command Line Tools${NC}"
if ! xcode-select -p &>/dev/null; then
    echo -e "${YELLOW}Installing Xcode Command Line Tools...${NC}"
    xcode-select --install || handle_error "Failed to install Xcode Command Line Tools"
    echo -e "${YELLOW}Please wait for Xcode Command Line Tools to finish installing, then press any key to continue...${NC}"
    read -n 1
else
    echo -e "${GREEN}✓ Xcode Command Line Tools already installed${NC}"
fi

echo -e "${BLUE}Step 2: Installing Nix Package Manager${NC}"
if ! command -v nix &>/dev/null; then
    echo -e "${YELLOW}Installing Nix using Determinate Systems installer...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm || handle_error "Failed to install Nix"
    
    # Source nix
    echo -e "${YELLOW}Setting up Nix environment...${NC}"
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    else
        handle_error "Failed to source Nix environment. Please restart your terminal and run this script again."
    fi
else
    echo -e "${GREEN}✓ Nix already installed${NC}"
fi

echo -e "${BLUE}Step 3: Enabling Nix Flakes${NC}"
mkdir -p ~/.config/nix
FLAKES_CONFIG="experimental-features = nix-command flakes"
if ! grep -q "$FLAKES_CONFIG" ~/.config/nix/nix.conf 2>/dev/null; then
    echo "$FLAKES_CONFIG" >> ~/.config/nix/nix.conf
    echo -e "${GREEN}✓ Nix Flakes enabled${NC}"
else
    echo -e "${GREEN}✓ Nix Flakes already enabled${NC}"
fi

echo -e "${BLUE}Step 4: Preparing System Files${NC}"
for file in "/etc/bashrc" "/etc/zshrc"; do
    if [[ -f "$file" && ! -f "${file}.before-nix-darwin" ]]; then
        echo -e "${YELLOW}Moving $file to ${file}.before-nix-darwin${NC}"
        sudo mv "$file" "${file}.before-nix-darwin" || echo -e "${YELLOW}Warning: Could not move $file${NC}"
    else
        echo -e "${GREEN}✓ $file already prepared${NC}"
    fi
done

echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}                Install Complete                            ${NC}"
echo -e "${GREEN}============================================================${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "   Build and switch to the configuration:"
echo "   # For personal machines:"
echo "   darwin-rebuild switch --flake .#default"
echo ""
echo "   # For work machines:"
echo "   darwin-rebuild switch --flake .#work"
echo ""
