#!/usr/bin/env nu

use std

def main [] {
    let loglib = ($env.HOME + "/.local/bin/loglib.nu")
    source $loglib

    # Check required commands
    let required_commands = ["fzf" "chafa" "git" "fd"]
    for cmd in $required_commands {
        if (which $cmd | is-empty) {
            log_error $"Required command not found: ($cmd)"
            log_info $"Install it with: nix shell nixpkgs#($cmd)"
            exit 1
        }
    }

    # Determine OS
    let os = if $nu.os.family == "macos" { "macos" } else if $nu.os.family == "linux" { "linux" } else {
        log_error $"Unsupported OS: ($nu.os.family)"
        exit 1
    }

    # Setup wallpapers directory
    let wallpapers_dir = ($env.HOME + "/.local/share/wallpapers")
    let wallpapers_repo = "https://github.com/roshbhatia/wallpapers.git"

    log_info "Checking wallpapers repository..."
    if not ($wallpapers_dir | path exists) {
        log_info $"Cloning wallpapers repository to ($wallpapers_dir)"
        mkdir -p ($wallpapers_dir | path dirname)
        if ($wallpapers_repo | git clone $wallpapers_dir 2> /dev/null | complete).exit_code != 0 {
            log_error "Failed to clone wallpapers repository"
            exit 1
        }
    } else {
        log_info "Updating wallpapers repository"
        let fetch = (cd $wallpapers_dir; git fetch --quiet 2> /dev/null | complete)
        let pull = (cd $wallpapers_dir; git pull --quiet 2> /dev/null | complete)
        
        if $fetch.exit_code != 0 {
            log_warn "Could not fetch updates - continuing with local version"
        } else if $pull.exit_code != 0 {
            log_warn "Could not pull updates - continuing with local version"
        }
    }

    # Find image files
    log_info "Scanning for wallpapers..."
    let images = (
        fd --type f --extension jpg --extension jpeg --extension png --extension webp . $wallpapers_dir | sort
    )

    let images = if ($images | is-empty) {
        log_info "No images in wallpapers repo, checking system locations..."
        let fallback_dirs = if $os == "macos" {
            [
                ($env.HOME + "/Pictures")
                ($env.HOME + "/Desktop")
                "/System/Library/Desktop Pictures"
                "/Library/Desktop Pictures"
            ]
        } else {
            [
                ($env.HOME + "/Pictures")
                ($env.HOME + "/Desktop")
            ]
        }

        let mut found_images = []
        for dir in $fallback_dirs {
            if ($dir | path exists) {
                let found = (fd --type f --extension jpg --extension jpeg --extension png --extension webp . $dir | sort)
                $found_images = ($found_images | append $found)
            }
        }

        if ($found_images | is-empty) {
            log_error "No images found in any location"
            log_info "Try adding some images to ~/Pictures or ensure the wallpapers repo is accessible"
            exit 1
        }

        $found_images | sort --unique
    } else {
        $images
    }

    log_success "Found wallpapers"

    # FZF preview with chafa
    let selected = (
        $images | fzf --preview "chafa --size 80x24 --colors 256 {}" --preview-window "right:50%" --height 50%
    )

    if ($selected | is-empty) {
        log_info "No wallpaper selected"
        exit 0
    }

    log_info $"Setting background to: (($selected | path basename))"

    if $os == "macos" {
        if (which osascript | is-empty) {
            log_error "osascript not available"
            exit 1
        }

        let result = (osascript -e $"tell application \"System Events\" to set picture of every desktop to \"($selected)\"" 2> /dev/null | complete)
        
        if $result.exit_code != 0 {
            log_warn "osascript failed - may need accessibility permissions"

            let db_path = ($env.HOME + "/Library/Application Support/Dock/desktoppicture.db")
            if ($db_path | path exists) {
                sqlite3 $db_path $"UPDATE pictures SET path = '($selected)';" 2> /dev/null | ignore
                killall Dock 2> /dev/null | ignore
                log_success "Background set via database update"
            } else {
                log_error "Could not set background - try System Preferences manually"
                exit 1
            }
        } else {
            log_success "Background set on macOS"
        }
    } else if $os == "linux" {
        mkdir -p ($env.HOME + "/.config/background")
        cp $selected ($env.HOME + "/.config/background/current")
        ln -sf ($env.HOME + "/.config/background/current") ($env.HOME + "/.background-image")

        log_success $"Background image set to: ($env.HOME)/.background-image"
        log_info "You may need to update your display manager or window manager configuration"
    }

    log_success "Done!"
}
