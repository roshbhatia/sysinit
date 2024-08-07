#!/bin/sh

# Set the source directory where your autuin configuration files are located
src="$(pwd)"

# Set the destination directory for autuin configuration files in your home directory
dst="$HOME/.config/atuin"

# Check if the destination directory already exists
if [ -e "$dst" ]; then
    echo "WARNING: $dst already exists. Do you want to overwrite it? (y/n)"
    read answer
    if [ "$answer" != "y" ]; then
        echo "Aborted."
        exit 1
    fi
    # Remove the existing directory before creating a new one
    rm -rf "$dst"
fi

# Create a symbolic link to the source directory
ln -s "$src" "$dst"
echo "Linked $src to $dst."
