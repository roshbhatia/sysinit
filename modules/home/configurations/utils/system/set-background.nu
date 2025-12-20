#!/usr/bin/env nu

use std

def main [] {
    # Check required commands
    let required_commands = ["fzf" "chafa" "gh" "fd"]
    for cmd in $required_commands {
        if (which $cmd | is-empty) {
            print $"(ansi red_bold)[ERROR](ansi reset) Required command not found: ($cmd)"
            print $"(ansi blue)[INFO](ansi reset) Install it with: nix shell nixpkgs#($cmd)"
            exit 1
        }
    }

    # Determine OS
    let os = if $nu.os-info.name == "macos" { "macos" } else if $nu.os-info.name == "linux" { "linux" } else {
        print $"(ansi red_bold)[ERROR](ansi reset) Unsupported OS: ($nu.os-info.name)"
        exit 1
    }

    # Setup wallpapers directory
    let wallpapers_dir = $env.HOME | path join ".local" "share" "wallpapers"
    let wallpapers_repo = "roshbhatia/wallpapers"

    print $"(ansi blue)[INFO](ansi reset) Checking wallpapers repository..."
    if not ($wallpapers_dir | path exists) {
        print $"(ansi blue)[INFO](ansi reset) Cloning wallpapers repository to ($wallpapers_dir)"
        mkdir ($wallpapers_dir | path dirname)
        if (gh repo clone $wallpapers_repo $wallpapers_dir err> /dev/null | complete).exit_code != 0 {
            print $"(ansi red_bold)[ERROR](ansi reset) Failed to clone wallpapers repository"
            exit 1
        }
    } else {
        print $"(ansi blue)[INFO](ansi reset) Updating wallpapers repository"
        let fetch = (cd $wallpapers_dir; git fetch --quiet err> /dev/null | complete)
        let pull = (cd $wallpapers_dir; git pull --quiet err> /dev/null | complete)

        if $fetch.exit_code != 0 {
            print $"(ansi yellow_bold)[WARN](ansi reset) Could not fetch updates - continuing with local version"
        } else if $pull.exit_code != 0 {
            print $"(ansi yellow_bold)[WARN](ansi reset) Could not pull updates - continuing with local version"
        }
    }

    # Find image files
    print $"(ansi blue)[INFO](ansi reset) Scanning for wallpapers..."
    let images = (
        fd --type f --extension jpg --extension jpeg --extension png --extension webp . $wallpapers_dir | sort
    )

    let images = if ($images | is-empty) {
        print $"(ansi blue)[INFO](ansi reset) No images in wallpapers repo, checking system locations..."
        let fallback_dirs = if $os == "macos" {
            [
                ($env.HOME | path join "Pictures")
                ($env.HOME | path join "Desktop")
                "/System/Library/Desktop Pictures"
                "/Library/Desktop Pictures"
            ]
        } else {
            [
                ($env.HOME | path join "Pictures")
                ($env.HOME | path join "Desktop")
            ]
        }

        let found_images = $fallback_dirs
            | where {|dir| $dir | path exists}
            | each {|dir| fd --type f --extension jpg --extension jpeg --extension png --extension webp . $dir}
            | flatten
            | sort
            | uniq

        if ($found_images | is-empty) {
            print $"(ansi red_bold)[ERROR](ansi reset) No images found in any location"
            print $"(ansi blue)[INFO](ansi reset) Try adding some images to ~/Pictures or ensure the wallpapers repo is accessible"
            exit 1
        }

        $found_images
    } else {
        $images
    }

    print $"(ansi green)[SUCCESS](ansi reset) Found wallpapers"

    # FZF preview with chafa
    let selected = (
        $images | fzf --preview "chafa --size 80x24 --colors 256 {}" --preview-window "right:50%" --height 50%
    )

    if ($selected | is-empty) {
        print $"(ansi blue)[INFO](ansi reset) No wallpaper selected"
        exit 0
    }

    print $"(ansi blue)[INFO](ansi reset) Setting background to: (($selected | path basename))"

    if $os == "macos" {
        if (which osascript | is-empty) {
            print $"(ansi red_bold)[ERROR](ansi reset) osascript not available"
            exit 1
        }

        let result = (osascript -e $"tell application \"System Events\" to set picture of every desktop to \"($selected)\"" err> /dev/null | complete)

        if $result.exit_code != 0 {
            print $"(ansi yellow_bold)[WARN](ansi reset) osascript failed - may need accessibility permissions"

            let db_path = $env.HOME | path join "Library" "Application Support" "Dock" "desktoppicture.db"
            if ($db_path | path exists) {
                sqlite3 $db_path $"UPDATE pictures SET path = '($selected)';" err> /dev/null | ignore
                killall Dock err> /dev/null | ignore
                print $"(ansi green)[SUCCESS](ansi reset) Background set via database update"
            } else {
                print $"(ansi red_bold)[ERROR](ansi reset) Could not set background - try System Preferences manually"
                exit 1
            }
        } else {
            print $"(ansi green)[SUCCESS](ansi reset) Background set on macOS"
        }
    } else if $os == "linux" {
        mkdir ($env.HOME | path join ".config" "background")
        cp $selected ($env.HOME | path join ".config" "background" "current")
        ln -sf ($env.HOME | path join ".config" "background" "current") ($env.HOME | path join ".background-image")

        print $"(ansi green)[SUCCESS](ansi reset) Background image set to: ($env.HOME)/.background-image"
        print $"(ansi blue)[INFO](ansi reset) You may need to update your display manager or window manager configuration"
    }

    print $"(ansi green)[SUCCESS](ansi reset) Done!"
}
