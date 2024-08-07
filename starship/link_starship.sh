#!/bin/sh

# Get the full path of the starship.toml file in the current working directory
src="$(pwd)/starship.toml"

# Get the destination path in the home directory
dst="$HOME/.config/starship.toml"

# Check if the destination file already exists
if [ -e "$dst" ]; then
    echo "WARNING: $dst already exists. Do you want to overwrite it? (y/n)"
    read answer
    if [ "$answer" != "y" ]; then
        echo "Aborted."
        exit 1
    fi
    # Remove the existing file or link before creating a new one
    rm -f "$dst"
fi

# Create the symbolic link
ln -s "$src" "$dst"
echo "Linked $src to $dst."
