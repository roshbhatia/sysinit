package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"
)

var (
	components []string
	allFlag    bool
	rootCmd    = &cobra.Command{
		Use:   "sysinit",
		Short: "SysInit - dotfiles and environment setup tool",
		Long:  "SysInit helps you deploy dotfiles and configure your development environment.",
	}

	installCmd = &cobra.Command{
		Use:   "install",
		Short: "Install selected components",
		Run:   runInstall,
	}

	listCmd = &cobra.Command{
		Use:   "list",
		Short: "List available components",
		Run:   runList,
	}
)

// Mapping from component names to their source and destination paths
var componentPaths = map[string]struct {
	src  string
	dest string
}{
	"starship": {src: "starship", dest: "~/.config/starship"},
	"k9s":      {src: "k9s", dest: "~/.config/k9s"},
	"atuin":    {src: "atuin", dest: "~/.config/atuin"},
	"macchina": {src: "macchina", dest: "~/.config/macchina"},
	"wezterm":  {src: "wezterm", dest: "~/.config/wezterm"},
}

// Special components with multiple paths
var specialComponents = map[string][]struct {
	src  string
	dest string
}{
	"wezterm": {
		{src: "wezterm", dest: "~/.config/wezterm"},
		{src: "wezterm/plugins", dest: "~/.config/wezterm/plugins"},
	},
	"zsh": {
		{src: "zsh/.zshrc", dest: "~/.zshrc"},
		{src: "zsh/.zshutils", dest: "~/.zshutils"},
		{src: "zsh/conf.d", dest: "~/.config/zsh/conf.d"},
	},
	"git": {
		{src: "git/.gitconfig", dest: "~/.gitconfig"},
		{src: "git/.gitconfig.personal", dest: "~/.gitconfig.personal"},
	},
}

var (
	completionCmd = &cobra.Command{
		Use:   "completion [bash|zsh|fish|powershell]",
		Short: "Generate completion script",
		Long: `To load completions:

Bash:
  $ source <(sysinit completion bash)

Zsh:
  $ source <(sysinit completion zsh)

fish:
  $ sysinit completion fish | source

PowerShell:
  PS> sysinit completion powershell | Out-String | Invoke-Expression
`,
		Args:      cobra.ExactValidArgs(1),
		ValidArgs: []string{"bash", "zsh", "fish", "powershell"},
		Run: func(cmd *cobra.Command, args []string) {
			switch args[0] {
			case "bash":
				cmd.Root().GenBashCompletion(os.Stdout)
			case "zsh":
				cmd.Root().GenZshCompletion(os.Stdout)
			case "fish":
				cmd.Root().GenFishCompletion(os.Stdout, true)
			case "powershell":
				cmd.Root().GenPowerShellCompletionWithDesc(os.Stdout)
			}
		},
	}
)

func init() {
	// Install command setup
	installCmd.Flags().StringSliceVarP(&components, "components", "c", []string{}, "Comma-separated list of components to install (starship,k9s,atuin,macchina,zsh,git,wezterm,grugnvim)")
	installCmd.Flags().BoolVarP(&allFlag, "all", "a", false, "Install all components")

	// Add commands to root
	rootCmd.AddCommand(installCmd)
	rootCmd.AddCommand(listCmd)
	rootCmd.AddCommand(completionCmd)

	// Set version
	rootCmd.Version = "0.1.0"
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func runInstall(cmd *cobra.Command, args []string) {
	if !allFlag && len(components) == 0 {
		// Default to all components if none specified
		allFlag = true
	}

	if allFlag {
		components = []string{"starship", "k9s", "atuin", "macchina", "zsh", "git", "wezterm", "grugnvim"}
	}

	// Get working directory
	pwd, err := os.Getwd()
	if err != nil {
		fmt.Printf("Error getting current directory: %v\n", err)
		os.Exit(1)
	}

	// Get home directory
	home, err := os.UserHomeDir()
	if err != nil {
		fmt.Printf("Error getting home directory: %v\n", err)
		os.Exit(1)
	}

	successCount := 0

	// Process each component
	for _, component := range components {
		fmt.Printf("Installing %s...\n", component)

		switch component {
		case "wezterm":
			// Ensure plugin directory exists
			pluginDir := filepath.Join(home, ".config", "wezterm", "plugins")
			if err := os.MkdirAll(pluginDir, 0755); err != nil && !os.IsExist(err) {
				fmt.Printf("❌ Failed to create plugin directory: %v\n", err)
				continue
			}

			// Continue with normal wezterm installation
			if specialPaths, ok := specialComponents[component]; ok {
				componentSuccess := true
				for _, path := range specialPaths {
					src := filepath.Join(pwd, path.src)
					dest := strings.Replace(path.dest, "~", home, 1)
					if err := createSymlink(src, dest); err != nil {
						fmt.Printf("❌ Failed to install %s part (%s): %v\n", component, path.src, err)
						componentSuccess = false
					}
				}
				if componentSuccess {
					fmt.Printf("✅ Successfully installed %s\n", component)
					successCount++
				}
			}

		case "grugnvim":
			if err := installGrugnvim(pwd, home); err != nil {
				fmt.Printf("❌ Failed to install grugnvim: %v\n", err)
			} else {
				fmt.Println("✅ Successfully installed grugnvim")
				successCount++
			}

		default:
			// Handle normal components
			if paths, ok := componentPaths[component]; ok {
				src := filepath.Join(pwd, paths.src)
				dest := strings.Replace(paths.dest, "~", home, 1)
				if err := createSymlink(src, dest); err != nil {
					fmt.Printf("❌ Failed to install %s: %v\n", component, err)
				} else {
					fmt.Printf("✅ Successfully installed %s\n", component)
					successCount++
				}
			} else if specialPaths, ok := specialComponents[component]; ok {
				// Handle special components with multiple paths
				componentSuccess := true
				for _, path := range specialPaths {
					src := filepath.Join(pwd, path.src)
					dest := strings.Replace(path.dest, "~", home, 1)
					if err := createSymlink(src, dest); err != nil {
						fmt.Printf("❌ Failed to install %s part (%s): %v\n", component, path.src, err)
						componentSuccess = false
					}
				}
				if componentSuccess {
					fmt.Printf("✅ Successfully installed %s\n", component)
					successCount++
				}
			} else {
				fmt.Printf("⚠️ Unknown component: %s\n", component)
			}
		}
	}

	fmt.Printf("\nInstallation complete: %d/%d components installed successfully\n", successCount, len(components))
}

func createSymlink(src, dest string) error {
	// Ensure parent directory exists
	err := os.MkdirAll(filepath.Dir(dest), 0755)
	if err != nil {
		return fmt.Errorf("failed to create parent directory: %w", err)
	}

	// Check if destination exists and is a symlink
	if info, err := os.Lstat(dest); err == nil {
		if info.Mode()&os.ModeSymlink != 0 {
			// It's a symlink, remove it
			if err := os.Remove(dest); err != nil {
				return fmt.Errorf("failed to remove existing symlink: %w", err)
			}
		} else {
			// It's a file or directory, create backup
			backupPath := dest + ".backup." + fmt.Sprintf("%d", os.Getpid())
			if err := os.Rename(dest, backupPath); err != nil {
				return fmt.Errorf("failed to backup existing file: %w", err)
			}
			fmt.Printf("  Created backup at %s\n", backupPath)
		}
	}

	// Create the symlink
	return os.Symlink(src, dest)
}

func installGrugnvim(pwd, home string) error {
	grugnvimDir := filepath.Join(pwd, "grugnvim")
	if _, err := os.Stat(grugnvimDir); os.IsNotExist(err) {
		return fmt.Errorf("grugnvim directory not found at %s", grugnvimDir)
	}

	// Change to grugnvim directory
	currentDir, err := os.Getwd()
	if err != nil {
		return fmt.Errorf("failed to get current directory: %w", err)
	}

	// Run the link script
	if err := os.Chdir(grugnvimDir); err != nil {
		return fmt.Errorf("failed to change to grugnvim directory: %w", err)
	}
	defer os.Chdir(currentDir) // Ensure we change back when done

	nvimConfig := filepath.Join(home, ".config", "nvim")
	cmd := exec.Command("rm", "-rf", nvimConfig)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("deleting nvim config failed %w - %s", err, string(output))
	}
	fmt.Printf("  %s\n", string(output))

	cmd = exec.Command("bash", "./link-nvimconfig.sh")
	output, err = cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("linking script failed: %w - %s", err, string(output))
	}

	fmt.Printf("  %s\n", string(output))
	return nil
}

func runList(cmd *cobra.Command, args []string) {
	// Get descriptions for regular components
	componentDescriptions := map[string]string{
		"starship": "Cross-shell prompt",
		"k9s":      "Kubernetes CLI",
		"atuin":    "Shell history",
		"macchina": "System info",
		"zsh":      "ZSH configs",
		"git":      "Git configs",
		"wezterm":  "Terminal emulator",
		"grugnvim": "Neovim setup",
	}

	fmt.Println("Available components:")
	fmt.Println("=====================")

	// List all components
	availableComponents := []string{
		"starship", "k9s", "atuin", "macchina",
		"zsh", "git", "wezterm", "grugnvim",
	}

	for _, component := range availableComponents {
		description := componentDescriptions[component]
		fmt.Printf("- %-10s %s\n", component, description)
	}

	fmt.Println()
	fmt.Println("Usage: sysinit install --components component1,component2")
	fmt.Println("   or: sysinit install --all")
}
