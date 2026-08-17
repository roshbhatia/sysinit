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

// Vale carries an action through --output=JSON but never applies one: the CLI
// has no fix flag, and only editor integrations consume them. This is the
// applier. A rule without an action is reported and left alone, which is why
// only the mechanical rewrites carry one in pkgs/prose-style/rules.cue.
//
// A chat reply cannot be fixed this way. A Stop hook fires after the text is
// already on screen and has no field to rewrite it, so `check` still sends a
// reply back rather than repairing it.

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
// alert's matched text.
//
// Span alone is not trustworthy. Vale reports it against the text the rule saw,
// and a default-scope rule sees markdown-stripped text while a `scope: raw`
// rule sees the line as written. On a line carrying both kinds of alert the two
// coordinate systems disagree, and writing at the wrong offset silently
// destroys prose. So Span is only a hint: the match text has to be there, or
// the alert is skipped and reported by lint instead.
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
// returns the new line with the new start offset.
//
// Vale's match does not always take the whole gap with it. `[ \t]*—[ \t]*`
// against `foo — bar` in a heading can report ` —` and leave the trailing space
// on the line, so a bare ": " replacement writes `foo:  bar`. So a replacement
// that carries its own spacing eats the space next to it, on whichever side it
// supplies one.
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

func lintFile(config, path string) ([]fileAlert, error) {
	binary, err := exec.LookPath("vale")
	if err != nil {
		return nil, err
	}
	cmd := exec.Command(binary, "--config="+config, "--output=JSON", "--no-exit", path)
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

// fixFile rewrites path in place and reports how many alerts it applied.
//
// Edits run last-first within each line so an earlier span keeps its offsets.
// Two alerts that overlap would corrupt each other, so the second one is left
// for the next pass rather than applied on top of a shifted line.
//
// It also reports how many alerts carried an action it could not place. Vale's
// Line is approximate for a default-scope alert inside a list, and `locate`
// refuses to write when the reported line does not hold the match. Those are
// real edits left undone, so they are counted rather than swallowed.
func fixFile(config, path string, dry bool) (int, int, error) {
	found, err := lintFile(config, path)
	if err != nil {
		return 0, 0, err
	}

	byLine := map[int][]fileAlert{}
	for _, a := range found {
		if a.Action.Name == "" || len(a.Span) != 2 {
			continue
		}
		byLine[a.Line] = append(byLine[a.Line], a)
	}
	if len(byLine) == 0 {
		return 0, 0, nil
	}

	raw, err := os.ReadFile(path)
	if err != nil {
		return 0, 0, err
	}
	lines := strings.Split(string(raw), "\n")

	applied, unplaced := 0, 0
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
			if err != nil {
				return err
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

	// Two alerts on one line make the second one's offsets stale as soon as the
	// first is applied, so a pass leaves work behind. Re-linting after each
	// pass is what converges, and maxPasses stops a rule that fights itself.
	const maxPasses = 10

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
