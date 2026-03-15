#!/usr/bin/env nu

def main [--update] {
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
    let os = $nu.os-info.name

    if $os not-in ["macos" "linux"] {
        print $"(ansi red_bold)[ERROR](ansi reset) Unsupported OS: ($os)"
        exit 1
    }

    # Setup wallpapers directory
    let wallpapers_dir = $env.HOME | path join ".local" "share" "wallpapers"
    let wallpapers_repo = "roshbhatia/wallpapers"

    print $"(ansi blue)[INFO](ansi reset) Checking wallpapers repository..."
    if not ($wallpapers_dir | path exists) {
        print $"(ansi blue)[INFO](ansi reset) Cloning wallpapers repository to ($wallpapers_dir)"
        mkdir ($wallpapers_dir | path dirname)
        let result = do { gh repo clone $wallpapers_repo $wallpapers_dir } | complete
        if $result.exit_code != 0 {
            print $"(ansi red_bold)[ERROR](ansi reset) Failed to clone wallpapers repository"
            exit 1
        }
    } else if $update {
        print $"(ansi blue)[INFO](ansi reset) Updating wallpapers repository"
        let fetch = do { cd $wallpapers_dir; git fetch --quiet } | complete
        let pull = do { cd $wallpapers_dir; git pull --quiet } | complete

        if $fetch.exit_code != 0 {
            print $"(ansi yellow_bold)[WARN](ansi reset) Could not fetch updates - continuing with local version"
        } else if $pull.exit_code != 0 {
            print $"(ansi yellow_bold)[WARN](ansi reset) Could not pull updates - continuing with local version"
        }
    }

    # Find image files
    print $"(ansi blue)[INFO](ansi reset) Scanning for wallpapers..."
    let images = do { fd --type f --extension jpg --extension jpeg --extension png --extension webp . $wallpapers_dir } | complete | get stdout | str trim | lines

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
            | each {|dir| do { fd --type f --extension jpg --extension jpeg --extension png --extension webp . $dir } | complete | get stdout | str trim | lines }
            | flatten
            | sort
            | uniq

        if ($found_images | is-empty) {
            print $"(ansi red_bold)[ERROR](ansi reset) No images found in any location"
            exit 1
        }

        $found_images
    } else {
        $images
    }

    print $"(ansi green)[OK](ansi reset) Found ($images | length) wallpapers"

    # FZF preview with chafa
    let selected = $images | str join "\n" | fzf --preview "chafa --size 80x24 --colors 256 {}" --preview-window "right:50%" --height 50% | str trim

    if ($selected | is-empty) {
        print $"(ansi blue)[INFO](ansi reset) No wallpaper selected"
        exit 0
    }

    print $"(ansi blue)[INFO](ansi reset) Setting background to: ($selected | path basename)"

    if $os == "macos" {
        let result = do { osascript -e $"tell application \"System Events\" to set picture of every desktop to \"($selected)\"" } | complete

        if $result.exit_code != 0 {
            print $"(ansi yellow_bold)[WARN](ansi reset) osascript failed - trying database update"

            let db_path = $env.HOME | path join "Library" "Application Support" "Dock" "desktoppicture.db"
            if ($db_path | path exists) {
                do { sqlite3 $db_path $"UPDATE pictures SET path = '($selected)';" } | complete | ignore
                do { killall Dock } | complete | ignore
                print $"(ansi green)[OK](ansi reset) Background set via database update"
            } else {
                print $"(ansi red_bold)[ERROR](ansi reset) Could not set background"
                exit 1
            }
        } else {
            print $"(ansi green)[OK](ansi reset) Background set on macOS"
        }
    } else if $os == "linux" {
        mkdir ($env.HOME | path join ".config" "background")
        cp $selected ($env.HOME | path join ".config" "background" "current")
        ln -sf ($env.HOME | path join ".config" "background" "current") ($env.HOME | path join ".background-image")

        print $"(ansi green)[OK](ansi reset) Background image linked to ~/.background-image"

        # Reload sway if running
        if "SWAYSOCK" in $env {
            try {
                swaymsg reload
                print $"(ansi blue)[INFO](ansi reset) Reloaded sway to apply background"
            } catch {
                print $"(ansi yellow_bold)[WARN](ansi reset) Could not reload sway"
            }
        } else {
            print $"(ansi blue)[INFO](ansi reset) Sway not detected - background will apply on next start"
        }
    }

    print $"(ansi green)[OK](ansi reset) Done!"
}
