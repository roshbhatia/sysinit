package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	// Configuration: embed module lists directly
	modules := map[string][]string{
		"editor": {"oil"},
		"ui":     {},
		"tools":  {"alpha", "lazygit", "hop"},
	}

	// Read template file
	tplData, err := ioutil.ReadFile("init.tpl.lua")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error reading template: %v\n", err)
		os.Exit(1)
	}
	tpl := string(tplData)

	// Build module_system block
	var sb []string
	sb = append(sb, "-- determine module loading system")
	sb = append(sb, "local module_system = {")
	for _, kind := range []string{"editor", "ui", "tools"} {
		mods := modules[kind]
		sb = append(sb, fmt.Sprintf("  %s = {", kind))
		for _, m := range mods {
			sb = append(sb, fmt.Sprintf("    %q,", m))
		}
		sb = append(sb, "  },")
	}
	sb = append(sb, "}")
	sb = append(sb, "")
	sb = append(sb, "local function collect_plugin_specs()")
	sb = append(sb, "  return module_loader.get_plugin_specs(module_system)")
	sb = append(sb, "end")
	block := strings.Join(sb, "\n")

	// Replace placeholder in template
	output := strings.Replace(tpl, "-- MODULE_SYSTEM_BLOCK", block, 1)

	// Write generated init-vscode.lua
	if err := ioutil.WriteFile("init-vscode.lua", []byte(output), 0644); err != nil {
		fmt.Fprintf(os.Stderr, "Error writing init-vscode.lua: %v\n", err)
		os.Exit(1)
	}
	fmt.Println("Generated init-vscode.lua")
	// Annotate which-key mappings in Lua files
	prefixActions := map[string]string{
		"f": "search-preview.quickOpenWithPreview, workbench.action.findInFiles, workbench.action.showAllEditors, workbench.action.showAllSymbols, workbench.action.openRecent",
		"b": "workbench.action.nextEditor, workbench.action.previousEditor, workbench.action.closeActiveEditor, workbench.action.closeOtherEditors",
		"w": "workbench.action.focusLeftGroup, workbench.action.focusBelowGroup, workbench.action.focusAboveGroup, workbench.action.focusRightGroup, workbench.action.evenEditorWidths, workbench.action.toggleEditorWidths, workbench.action.closeActiveEditor, workbench.action.closeOtherEditors, workbench.action.moveEditorToLeftGroup, workbench.action.moveEditorToBelowGroup, workbench.action.moveEditorToAboveGroup, workbench.action.moveEditorToRightGroup",
		"g": "git.stage, git.stageAll, git.unstage, git.unstageAll, git.commit, git.commitAll, git.push, git.pull, git.openChange, git.openAllChanges, git.checkout, git.fetch, git.revertChange, workbench.view.scm, workbench.action.chat.open",
	}
	// Walk through Lua files and annotate wk.add entries
	err = filepath.Walk("lua", func(path string, info os.FileInfo, err error) error {
		if err != nil || info.IsDir() || !strings.HasSuffix(path, ".lua") {
			return err
		}
		data, err := ioutil.ReadFile(path)
		if err != nil {
			return err
		}
		content := string(data)
		// Only annotate files that use which-key (wk.add)
		if !strings.Contains(content, "wk.add") {
			return nil
		}
		lines := strings.Split(content, "\n")
		changed := false
		for i, line := range lines {
			for prefix, actions := range prefixActions {
				key := fmt.Sprintf("\"<leader>%s\"", prefix)
				if strings.Contains(line, key) && !strings.Contains(line, "-- vscode actions") {
					lines[i] = line + " -- vscode actions: " + actions
					changed = true
				}
			}
		}
		if changed {
			err := ioutil.WriteFile(path, []byte(strings.Join(lines, "\n")), 0644)
			if err != nil {
				return err
			}
			fmt.Println("Annotated", path)
		}
		return nil
	})
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error annotating Lua files: %v\n", err)
		os.Exit(1)
	}
}
