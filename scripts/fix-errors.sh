#!/bin/bash
set -e

echo "🔧 Running error fix script..."

# Fix 1: Create proper directories
echo "Ensuring directories exist..."
mkdir -p ~/.npm
mkdir -p ~/.config/npm
mkdir -p ~/.local/bin
mkdir -p ~/.local/share/bash-completion/completions

# Fix 2: Fix permissions
echo "Fixing permissions..."
sudo chown -R $(whoami) ~/.npm
sudo chown -R $(whoami) ~/.config/npm
sudo chown -R $(whoami) ~/.local/bin
sudo chown -R $(whoami) ~/.local/share

# Fix 3: Ensure bash is set up correctly
echo "Creating minimal bash configuration..."
echo '#!/bin/bash
export TERM_PROGRAM=""
return 0' | sudo tee /etc/bashrc >/dev/null

# Fix 4: Set up gettext symlink
echo "Setting up gettext symlink..."
if [ -f "/opt/homebrew/opt/gettext/bin/gettext" ]; then
    sudo mkdir -p /usr/local/bin
    sudo ln -sf /opt/homebrew/opt/gettext/bin/gettext /usr/local/bin/gettext
fi

# Fix 5: Install common npm dependencies globally
echo "Installing necessary npm packages..."
npm install -g typescript typescript-language-server prettier

# Fix 6: Reset pipx if needed
echo "Resetting pipx if needed..."
if command -v pipx >/dev/null; then
    pipx reinstall-all || true
fi

echo "✅ Fixes completed."
echo "Now try running: make switch"