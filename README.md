```                                                                                                                                       
                                                                 ___     
                                   ,--,                 ,--,   ,--.'|_   
                                 ,--.'|         ,---, ,--.'|   |  | :,'  
  .--.--.              .--.--.   |  |,      ,-+-. /  ||  |,    :  : ' :  
 /  /    '       .--, /  /    '  `--'_     ,--.'|'   |`--'_  .;__,'  /   
|  :  /`./     /_ ./||  :  /`./  ,' ,'|   |   |  ,"' |,' ,'| |  |   |    
|  :  ;_    , ' , ' :|  :  ;_    '  | |   |   | /  | |'  | | :__,'| :    
 \  \    `./___/ \: | \  \    `. |  | :   |   | |  | ||  | :   '  : |__  
  `----.   \.  \  ' |  `----.   \'  : |__ |   | |  |/ '  : |__ |  | '.'| 
 /  /`--'  / \  ;   : /  /`--'  /|  | '.'||   | |--'  |  | '.'|;  :    ; 
'--'.     /   \  \  ;'--'.     / ;  :    ;|   |/      ;  :    ;|  ,   /  
  `--'---'     :  \  \ `--'---'  |  ,   / '---'       |  ,   /  ---`-'   
                \  ' ;            ---`-'               ---`-'            
                 `--`                                                    
```

# sysinit

My dotfiles and configs.

## Installation

```bash
./install.sh
```

This script will:
1. Install required dependencies via Homebrew
2. Create symlinks for all configuration files
3. Start necessary services

## Included Configurations

- Starship - Cross-shell prompt
- K9s - Kubernetes CLI
- Atuin - Shell history
- Macchina - System information fetcher
- Rio - GPU-accelerated terminal emulator
- Git - Version control
- ZSH - Shell configuration
- SketchyBar - macOS status bar customization

### SketchyBar

A customizable status bar for macOS that can display system information, active applications, and more.

Prerequisites:
- Enable "Displays have separate Spaces" in System Settings -> Desktop & Dock

The configuration includes:
- Mission control space indicators
- Active application display
- Clock
- Volume indicator
- Battery status

For more advanced configurations, see the [SketchyBar GitHub repository](https://github.com/FelixKratz/SketchyBar).