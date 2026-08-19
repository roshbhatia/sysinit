package cmd

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"path/filepath"

	"github.com/roshbhatia/seshy/internal/config"
	"github.com/roshbhatia/seshy/internal/hook"
	"github.com/roshbhatia/seshy/internal/session"
	"github.com/roshbhatia/seshy/internal/tmpl"
	"github.com/roshbhatia/seshy/internal/ui"
	"github.com/spf13/cobra"
)

var (
	newBranch string
	newStdin  bool
	newEmpty  bool
)

var newCmd = &cobra.Command{
	Use:   "new <name> [repos...]",
	Short: "Create a new session",
	Args:  cobra.MinimumNArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		name := args[0]

		if err := session.ValidateSessionName(name); err != nil {
			return err
		}
		if session.Exists(name) {
			return fmt.Errorf("session %s already exists", ui.AccentBold(name))
		}

		cfg, err := config.Load()
		if err != nil {
			return fmt.Errorf("loading config: %w", err)
		}

		repos := args[1:]

		if newEmpty && len(repos) > 0 {
			return fmt.Errorf("--empty takes no repositories")
		}

		if newStdin {
			scanner := bufio.NewScanner(os.Stdin)
			for scanner.Scan() {
				line := scanner.Text()
				if line != "" {
					repos = append(repos, line)
				}
			}
		}

		// The picker is the only interactive path here. --empty and --stdin both
		// say the caller already supplied the repo list, so an empty list means an
		// empty session instead of a prompt no one is there to answer.
		if len(repos) == 0 && !newEmpty && !newStdin {
			candidates, err := runSource(cfg.RepoSource)
			if err != nil {
				return fmt.Errorf("repo source: %w", err)
			}
			candidates = prependDefaults(cfg.DefaultRepos, candidates)
			if len(candidates) > 0 {
				selected, err := runPicker(cfg.Picker, candidates)
				if err != nil {
					if errors.Is(err, errCancelled) {
						return nil
					}
					return err
				}
				repos = selected
			}
		}

		opts := session.CreateOpts{
			BranchFormat:   cfg.BranchFormat,
			BranchOverride: newBranch,
		}

		repoInfos, err := session.Create(name, repos, opts)
		if err != nil {
			return fmt.Errorf("failed to create session: %w", err)
		}

		sessionPath, _ := session.GetPath(name)
		data := session.BuildTemplateData(name, sessionPath, repoInfos)

		// Render per-repo templates
		repoTmplDir := filepath.Join(config.ConfigDir(), "templates", "repo")
		for _, ri := range repoInfos {
			rd := data.ForRepo(tmpl.RepoData{Name: ri.Name, Path: ri.Path, Source: ri.SourcePath, Branch: ri.Branch})
			if err := tmpl.RenderDir(repoTmplDir, ri.Path, rd); err != nil {
				fmt.Fprintln(os.Stderr, ui.Warningf("template error for %s: %v", ri.Name, err))
			}
		}

		// Render session-level templates
		sessionTmplDir := filepath.Join(config.ConfigDir(), "templates", "session")
		if err := tmpl.RenderDir(sessionTmplDir, sessionPath, data); err != nil {
			fmt.Fprintln(os.Stderr, ui.Warningf("session template error: %v", err))
		}

		// Run post-create hooks
		hook.Run("post-create", cfg.Hooks.PostCreate, data, sessionPath)

		fmt.Fprintln(os.Stderr, ui.Successf("Created session %s", ui.AccentBold(name)))
		fmt.Fprintf(os.Stderr, "  %s %s\n", ui.Faint("path:"), sessionPath)
		fmt.Fprintf(os.Stderr, "  %s %d\n", ui.Faint("repos:"), len(repoInfos))
		if len(repoInfos) == 0 {
			fmt.Fprintln(os.Stderr, ui.Info("Empty session. Add repos with "+ui.AccentBold("sy add "+name)))
		}
		return nil
	},
}

func init() {
	newCmd.Flags().StringVarP(&newBranch, "branch", "b", "", "Override branch name for all worktrees")
	newCmd.Flags().BoolVar(&newStdin, "stdin", false, "Read repo paths from stdin")
	newCmd.Flags().BoolVar(&newEmpty, "empty", false, "Create the session with no repositories")
	rootCmd.AddCommand(newCmd)
}
