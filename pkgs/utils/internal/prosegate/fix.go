package prosegate

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

// Vale carries an action through --output=JSON but never applies one, so this
// file is the applier. A rule with no action is reported and left alone.

type fileAlert struct {
	valeAlert
	// Span is a pair of 1-based, inclusive rune offsets into Line.
	Span   []int           `json:"Span"`
	Action valeAlertAction `json:"Action"`
}

type valeAlertAction struct {
	Name   string   `json:"Name"`
	Params []string `json:"Params"`
}

// apply turns one matched string into its replacement. It returns ok=false for
// an action this cannot carry out, which leaves the match untouched.
func apply(match string, action valeAlertAction) (string, bool) {
	switch action.Name {
	case "replace":
		if len(action.Params) == 0 {
			return "", false
		}
		return action.Params[0], true
	case "remove":
		return "", true
	case "edit":
		// params is [regex, pattern, replacement]; vale defines no other form.
		if len(action.Params) != 3 || action.Params[0] != "regex" {
			return "", false
		}
		re, err := regexp.Compile(action.Params[1])
		if err != nil {
			return "", false
		}
		return re.ReplaceAllString(match, action.Params[2]), true
	default:
		return "", false
	}
}

// locate returns the 1-based inclusive rune range on the line that holds the
// alert's matched text. Span is only a hint: a default-scope and a `scope: raw`
// alert measure the same line differently, and writing at the wrong offset
// silently destroys prose, so the match text has to be there.
func locate(runes []rune, a fileAlert) (int, int, bool) {
	match := []rune(a.Match)
	if len(match) == 0 {
		return 0, 0, false
	}

	start, end := a.Span[0], a.Span[1]
	if start >= 1 && end <= len(runes) && start <= end &&
		string(runes[start-1:end]) == a.Match {
		return start, end, true
	}

	// Fall back to the only unambiguous case: the match appears exactly once.
	line := string(runes)
	first := strings.Index(line, a.Match)
	if first < 0 || strings.Contains(line[first+len(a.Match):], a.Match) {
		return 0, 0, false
	}
	offset := len([]rune(line[:first])) + 1
	return offset, offset + len(match) - 1, true
}

// splice writes replacement over the 1-based inclusive range [start, end] and
// returns the new line with the new start offset. Vale's match does not always
// take the whole gap with it, so a replacement carrying its own spacing eats
// the space next to it on whichever side it supplies one.
func splice(runes []rune, start, end int, replacement string) ([]rune, int) {
	head, tail := runes[:start-1], runes[end:]
	if r := []rune(replacement); len(r) > 0 {
		for r[len(r)-1] == ' ' && len(tail) > 0 && tail[0] == ' ' {
			tail = tail[1:]
		}
		for (r[0] == ',' || r[0] == ':' || r[0] == '.') && len(head) > 0 && head[len(head)-1] == ' ' {
			head = head[:len(head)-1]
			start--
		}
		// A wrapped line can break on the em-dash, which leaves the
		// replacement's own space at the end of the line.
		if len(tail) == 0 {
			replacement = strings.TrimRight(replacement, " \t")
		}
	}
	out := make([]rune, 0, len(head)+len(replacement)+len(tail))
	out = append(out, head...)
	out = append(out, []rune(replacement)...)
	return append(out, tail...), start
}

// lintAlerts runs vale over one source and returns every alert with its span
// and action. A path lints that file; an empty path lints text on stdin, which
// is the only way to reach a chat reply that was never written to disk.
func lintAlerts(config, path, text string) ([]fileAlert, error) {
	binary, err := exec.LookPath("vale")
	if err != nil {
		return nil, err
	}
	// --no-global for the same reason as the check path: a user config at
	// ~/.vale.ini merges into every vale run and can replace the whole rule
	// set, and the fixer writes files.
	args := []string{"--config=" + config, "--no-global", "--output=JSON", "--no-exit"}
	if path == "" {
		args = append(args, "--ext=.md")
	} else {
		args = append(args, path)
	}
	cmd := exec.Command(binary, args...)
	if path == "" {
		cmd.Stdin = strings.NewReader(text)
	}
	out, err := cmd.Output()
	if err != nil {
		return nil, err
	}
	var byFile map[string][]fileAlert
	if err := json.Unmarshal(out, &byFile); err != nil {
		return nil, err
	}
	var all []fileAlert
	for _, list := range byFile {
		all = append(all, list...)
	}
	return all, nil
}

// pass applies every placeable action once and returns the rewritten lines.
// Edits run last-first within each line so an earlier span keeps its offsets,
// and two overlapping alerts leave the second for the next pass. unplaced
// counts an action `locate` refused to place, which is a real edit left undone.
func pass(lines []string, found []fileAlert) (out []string, applied, unplaced int) {
	byLine := map[int][]fileAlert{}
	for _, a := range found {
		if a.Action.Name == "" || len(a.Span) != 2 {
			continue
		}
		byLine[a.Line] = append(byLine[a.Line], a)
	}
	if len(byLine) == 0 {
		return lines, 0, 0
	}

	for lineNo, list := range byLine {
		if lineNo < 1 || lineNo > len(lines) {
			unplaced += len(list)
			continue
		}
		// Descending by start offset, so each edit leaves earlier spans intact.
		//
		// Two rules can report the same span, because vale has no scope
		// negation: a heading is inside both `scope: heading` and the default
		// scope. Only the first of an overlapping pair is applied, so the tie
		// breaks on rule name ascending. That is a real contract, not an
		// accident: rules.cue names the more specific rule to sort first.
		sort.SliceStable(list, func(i, j int) bool {
			if list[i].Span[0] != list[j].Span[0] {
				return list[i].Span[0] > list[j].Span[0]
			}
			return list[i].Check < list[j].Check
		})

		runes := []rune(lines[lineNo-1])
		lastStart := len(runes) + 1
		for _, a := range list {
			start, end, ok := locate(runes, a)
			if !ok {
				unplaced++
				continue
			}
			if end >= lastStart {
				continue // overlaps an edit already made on this line
			}
			replacement, ok := apply(string(runes[start-1:end]), a.Action)
			if !ok {
				continue
			}
			runes, start = splice(runes, start, end, replacement)
			lastStart = start
			applied++
		}
		lines[lineNo-1] = string(runes)
	}
	return lines, applied, unplaced
}

// Two alerts on one line make the second one's offsets stale as soon as the
// first is applied, so a pass leaves work behind. Re-linting after each pass is
// what converges, and maxPasses stops a rule that fights itself.
const maxPasses = 10

// fixText applies every mechanical rule to text and returns the rewritten text.
// `fix` writes the result back to a file; `check` shows it to the model,
// because a Stop hook has no field that rewrites a reply.
func fixText(config, text string) (fixed string, applied, unplaced int) {
	lines := strings.Split(text, "\n")
	for range maxPasses {
		found, err := lintAlerts(config, "", strings.Join(lines, "\n"))
		if err != nil {
			break
		}
		var round int
		lines, round, unplaced = pass(lines, found)
		applied += round
		if round == 0 {
			break
		}
	}
	return strings.Join(lines, "\n"), applied, unplaced
}

// correction is one whole line, already rewritten, that the model can paste
// over the line it replaces.
type correction struct {
	Line int
	Text string
}

// A blocked reply is read once and acted on once, so the list has to fit on a
// screen. Past these bounds the gate reports the count instead, because a wall
// of corrections is not a fix list, it is the reply again.
const (
	maxCorrections = 12
	maxLineBytes   = 300
)

// corrections rewrites the mechanical faults in text and returns the lines that
// changed, plus the alerts that survive and need a person. A whole line is
// returned rather than a "replace X with Y" pair, because the same token can
// appear twice on one line and a pair would not say which one moved.
func corrections(config, text string) ([]correction, []valeAlert) {
	fixed, applied, _ := fixText(config, text)

	var changed []correction
	if applied > 0 {
		before, after := strings.Split(text, "\n"), strings.Split(fixed, "\n")
		for i := range after {
			if i >= len(before) || before[i] == after[i] {
				continue
			}
			line := after[i]
			if len(line) > maxLineBytes {
				continue // too long to hand back; the alert still names it
			}
			changed = append(changed, correction{Line: i + 1, Text: line})
		}
	}

	// The manual list is read off the FIXED text, so a fault the rewrite
	// already removed is never reported back as still outstanding.
	var manual []valeAlert
	if found, err := lintAlerts(config, "", fixed); err == nil {
		for _, a := range found {
			if a.Action.Name == "" {
				manual = append(manual, a.valeAlert)
			}
		}
	}
	sort.SliceStable(manual, func(i, j int) bool { return manual[i].Line < manual[j].Line })
	return changed, manual
}

// fixFile rewrites path in place and reports how many alerts it applied.
func fixFile(config, path string, dry bool) (int, int, error) {
	found, err := lintAlerts(config, path, "")
	if err != nil {
		return 0, 0, err
	}
	raw, err := os.ReadFile(path)
	if err != nil {
		return 0, 0, err
	}

	lines, applied, unplaced := pass(strings.Split(string(raw), "\n"), found)
	if applied == 0 || dry {
		return applied, unplaced, nil
	}
	info, err := os.Stat(path)
	if err != nil {
		return 0, unplaced, err
	}
	return applied, unplaced, os.WriteFile(path, []byte(strings.Join(lines, "\n")), info.Mode().Perm())
}

// markdown walks the given paths and returns every .md file under them.
func markdown(paths []string) ([]string, error) {
	var found []string
	for _, root := range paths {
		err := filepath.Walk(root, func(p string, info os.FileInfo, err error) error {
			// A repository root holds directories this cannot read, and one of
			// them must not stop the walk before it reaches the docs.
			if err != nil {
				if info != nil && info.IsDir() {
					return filepath.SkipDir
				}
				return nil
			}
			if info.IsDir() && strings.HasPrefix(filepath.Base(p), ".") && p != root {
				return filepath.SkipDir
			}
			if !info.IsDir() && strings.EqualFold(filepath.Ext(p), ".md") {
				found = append(found, p)
			}
			return nil
		})
		if err != nil {
			return nil, err
		}
	}
	return found, nil
}

func fix(args []string) int {
	dry := false
	var paths []string
	for _, a := range args {
		if a == "--dry-run" {
			dry = true
			continue
		}
		paths = append(paths, a)
	}
	if len(paths) == 0 {
		fmt.Fprintln(os.Stderr, "prose-gate fix: give at least one file or directory")
		return 2
	}

	config := stylePath()
	if config == "" {
		fmt.Fprintln(os.Stderr, "prose-gate fix: SYSINIT_PROSE_STYLE is unset")
		return 2
	}

	files, err := markdown(paths)
	if err != nil {
		fmt.Fprintf(os.Stderr, "prose-gate fix: %v\n", err)
		return 2
	}

	total, stuck := 0, 0
	perFile := map[string]int{}
	for range maxPasses {
		round := 0
		stuck = 0
		for _, f := range files {
			n, skipped, err := fixFile(config, f, dry)
			if err != nil {
				fmt.Fprintf(os.Stderr, "prose-gate fix: %s: %v\n", f, err)
				continue
			}
			perFile[f] += n
			round += n
			stuck += skipped
		}
		total += round
		// A dry run never writes, so a second pass would report the same work.
		if round == 0 || dry {
			break
		}
	}
	for _, f := range files {
		if perFile[f] > 0 {
			fmt.Printf("%3d  %s\n", perFile[f], f)
		}
	}
	verb := "applied"
	if dry {
		verb = "would apply"
	}
	fmt.Printf("%s %d fixes across %d files\n", verb, total, len(files))
	// Never let a skip read as coverage. These are edits the rule set asked for
	// and this could not place, and only `lint` will show them.
	if stuck > 0 {
		fmt.Printf("%d could not be placed and were left alone; run lint to see them\n", stuck)
	}
	return 0
}
