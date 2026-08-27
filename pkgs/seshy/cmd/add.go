package cmd

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"path/filepath"

	"github.com/roshbhatia/sysinit/pkgs/internal/ui"
	"github.com/roshbhatia/sysinit/pkgs/seshy/internal/config"
	"github.com/roshbhatia/sysinit/pkgs/seshy/internal/hook"
	"github.com/roshbhatia/sysinit/pkgs/seshy/internal/session"
	"github.com/roshbhatia/sysinit/pkgs/seshy/internal/tmpl"
	"github.com/spf13/cobra"
)

var (
	addBranch string
	addStdin  bool
)

var addCmd = &cobra.Command{
	Use:               "add <name> [repos...]",
	Short:             "Add repositories to a session",
	Args:              cobra.MinimumNArgs(1),
	ValidArgsFunction: completeSessionNames,
	RunE: func(cmd *cobra.Command, args []string) error {
		name := args[0]
		if !session.Exists(name) {
			return fmt.Errorf("session %s not found", ui.AccentBold(name))
		}

		sessionPath, err := session.GetPath(name)
		if err != nil {
			return err
		}

		cfg, err := config.Load()
		if err != nil {
			return fmt.Errorf("loading config: %w", err)
		}

		repos := args[1:]

		if addStdin {
			scanner := bufio.NewScanner(os.Stdin)
			for scanner.Scan() {
				line := scanner.Text()
				if line != "" {
					repos = append(repos, line)
				}
			}
		}

		if len(repos) == 0 {
			candidates, err := runSource(cfg.RepoSource)
			if err != nil {
				return fmt.Errorf("repo source: %w", err)
			}

			// Filter out repos already in session
			existingSources, _ := session.ListRepoSources(sessionPath)
			existingSet := make(map[string]bool, len(existingSources))
			for _, s := range existingSources {
				resolved, err := filepath.EvalSymlinks(s)
				if err != nil {
					resolved = s
				}
				existingSet[resolved] = true
			}
			var available []string
			for _, d := range candidates {
				resolved, err := filepath.EvalSymlinks(d)
				if err != nil {
					resolved = d
				}
				if !existingSet[resolved] {
					available = append(available, d)
				}
			}

			if len(available) == 0 {
				fmt.Fprintln(os.Stderr, ui.Info("All available repositories are already in the session."))
				return nil
			}

			selected, err := runPicker(cfg.Picker, available)
			if err != nil {
				if errors.Is(err, errCancelled) {
					return nil
				}
				return err
			}
			repos = selected
		}

		if len(repos) == 0 {
			return fmt.Errorf("no repositories selected")
		}

		opts := session.CreateOpts{
			BranchFormat:   cfg.BranchFormat,
			BranchOverride: addBranch,
		}

		result, newRepos, err := session.AddRepos(name, repos, opts)
		if err != nil {
			return fmt.Errorf("failed to add repositories: %w", err)
		}

		// Build template data with ALL repos (existing + new)
		allRepos := session.GetSessionRepoInfos(sessionPath)
		data := session.BuildTemplateData(name, sessionPath, allRepos)

		// Render per-repo templates for NEW repos only
		repoTmplDir := filepath.Join(config.ConfigDir(), "templates", "repo")
		for _, ri := range newRepos {
			rd := data.ForRepo(tmpl.RepoData{Name: ri.Name, Path: ri.Path, Source: ri.SourcePath, Branch: ri.Branch})
			if err := tmpl.RenderDir(repoTmplDir, ri.Path, rd); err != nil {
				fmt.Fprintln(os.Stderr, ui.Warningf("template error for %s: %v", ri.Name, err))
			}
		}

		// Re-render session templates (Repos list changed)
		sessionTmplDir := filepath.Join(config.ConfigDir(), "templates", "session")
		if err := tmpl.RenderSessionDir(sessionTmplDir, sessionPath, data); err != nil {
			fmt.Fprintln(os.Stderr, ui.Warningf("session template error: %v", err))
		}

		// Run post-add hooks
		hook.Run("post-add", cfg.Hooks.PostAdd, data, sessionPath)

		for _, s := range result.Skipped {
			fmt.Fprintln(os.Stderr, ui.Warningf("Skipped %s (already in session)", s))
		}
		for repo, e := range result.Errors {
			fmt.Fprintln(os.Stderr, ui.Errorf("Failed %s: %v", repo, e))
		}

		fmt.Fprintln(os.Stderr, ui.Successf("Added %d/%d repo(s) to %s", len(result.Added), len(repos), ui.AccentBold(name)))
		fmt.Fprintf(os.Stderr, "  %s %s\n", ui.Faint("path:"), sessionPath)

		if result.Err() != nil {
			return fmt.Errorf("some repositories failed to add")
		}
		return nil
	},
}

func init() {
	addCmd.Flags().StringVarP(&addBranch, "branch", "b", "", "Override branch name for all worktrees")
	addCmd.Flags().BoolVar(&addStdin, "stdin", false, "Read repo paths from stdin")
	rootCmd.AddCommand(addCmd)
}
