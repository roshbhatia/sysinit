package ty

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"
	"unicode"

	"github.com/roshbhatia/go-utils/cell"
	"github.com/roshbhatia/go-utils/paths"
	"golang.org/x/sys/unix"
)

type nativeItem struct {
	Text       string
	Foreground *struct{ Color string }
	Background *struct{ Color string }
	Attribute  *struct{ Intensity, Underline string }
}
type nativeItems []json.RawMessage

type presentationRow struct {
	ID    string      `json:"id"`
	Label nativeItems `json:"label"`
	Text  string      `json:"text"`
}
type presentationSession struct {
	Tail     nativeItems `json:"tail"`
	TailText string      `json:"tail_text"`
	ID       string      `json:"id"`
	Name     string      `json:"name"`
	Slot     int         `json:"slot"`
	Items    nativeItems `json:"items"`
	Inactive nativeItems `json:"inactive"`
	Text     string      `json:"text"`
}
type nativeStyle struct{ FG, BG string }

type presentationWindow struct {
	Tail     nativeItems `json:"tail"`
	TailText string      `json:"tail_text"`
	Host     nativeItems `json:"host"`
	HostText string      `json:"host_text"`
	ID       string      `json:"id"`
	Session  string      `json:"session"`
	Index    int         `json:"index"`
	Items    nativeItems `json:"items"`
	Text     string      `json:"text"`
	Active   bool        `json:"active"`
}
type presentation struct {
	Mode      nativeStyle                                        `json:"mode"`
	CopyMode  nativeStyle                                        `json:"copy_mode"`
	Host      nativeStyle                                        `json:"host"`
	Center    nativeStyle                                        `json:"center"`
	Rows      []presentationRow                                  `json:"rows"`
	Agents    []presentationRow                                  `json:"agents"`
	Attention []presentationRow                                  `json:"attention"`
	Sessions  []presentationSession                              `json:"sessions"`
	Windows   []presentationWindow                               `json:"windows"`
	Tabs      struct{ Active, Inactive struct{ FG, BG string } } `json:"tabs"`
	Icons     struct{ Locked, Unlocked string }                  `json:"icons"`
}
type presentationPane struct {
	ID           string `json:"id"`
	SessionID    string `json:"session_id"`
	Session      string `json:"session"`
	Window       string `json:"window"`
	Index        int    `json:"index"`
	WindowName   string `json:"window_name"`
	WindowActive bool   `json:"window_active"`
	PaneActive   bool   `json:"pane_active"`
	CWD          string `json:"cwd"`
	Title        string `json:"title"`
	ProcessName  string `json:"process_name"`
	Zoomed       bool   `json:"zoomed"`
	Floating     bool   `json:"floating"`
	Parent       string `json:"parent"`
	ParentName   string `json:"parent_name"`
	Activity     int64  `json:"activity"`
}

const presentationFormat = "#{pane_id}\x1f#{session_id}\x1f#{session_name}\x1f#{window_id}\x1f#{window_index}\x1f#{window_name}\x1f#{window_active}\x1f#{pane_active}\x1f#{pane_current_path}\x1f#{pane_title}\x1f#{pane_current_command}\x1f#{window_zoomed_flag}\x1f#{pane_floating_flag}\x1f#{@sysinit_float_parent}\x1f#{session_activity}\x1f#{pane_start_command}"

func pickerSettings() (pickerConfig, error) {
	root, err := paths.ConfigHomeE()
	if err != nil {
		return pickerConfig{}, err
	}
	name := os.Getenv("SYSINIT_TMUX_PROVIDERS")
	if name == "" {
		name = filepath.Join(root, "sysinit", "tmux-providers.json")
	}
	data, err := os.ReadFile(name)
	if err != nil {
		return pickerConfig{}, fmt.Errorf("read tmux provider config: %w", err)
	}
	var cfg pickerConfig
	if err = json.Unmarshal(data, &cfg); err != nil || cfg.Version != "sysinit.tmux-providers/v1" {
		return cfg, fmt.Errorf("invalid tmux provider config")
	}
	return cfg, nil
}

func collectPresentation(cfg pickerConfig, runner commandRunner, history string) (presentation, error) {
	var result presentation
	if len(cfg.Presentation) == 0 {
		return result, fmt.Errorf("tmux native presentation command is not configured")
	}
	data, err := call(runner, "tmux", []string{"list-panes", "-a", "-F", presentationFormat}, nil)
	if err != nil {
		return result, err
	}
	panes := []presentationPane{}
	names := map[string]string{}
	for _, line := range strings.Split(strings.TrimSpace(string(data)), "\n") {
		if line == "" {
			continue
		}
		f := strings.Split(line, "\x1f")
		if len(f) != 16 {
			return result, fmt.Errorf("invalid tmux presentation row")
		}
		if _, err := parseTmuxPaneID(f[0]); err != nil {
			return result, err
		}
		if strings.Contains(f[15], "ty tmux picker") || (os.Getenv("SYSINIT_TMUX_UI") == "picker" && f[0] == os.Getenv("TMUX_PANE")) {
			continue
		}
		index, err := strconv.Atoi(f[4])
		if err != nil {
			return result, fmt.Errorf("invalid tmux window index: %w", err)
		}
		activity, _ := strconv.ParseInt(f[14], 10, 64)
		p := presentationPane{ID: f[0], SessionID: f[1], Session: f[2], Window: f[3], Index: index, WindowName: f[5], WindowActive: f[6] == "1", PaneActive: f[7] == "1", CWD: f[8], Title: f[9], ProcessName: f[10], Zoomed: f[11] == "1", Floating: f[12] == "1", Parent: f[13], Activity: activity}
		names[p.SessionID] = p.Session
		panes = append(panes, p)
	}
	sort.SliceStable(panes, func(i, j int) bool {
		if panes[i].SessionID != panes[j].SessionID {
			a, _ := strconv.Atoi(strings.TrimPrefix(panes[i].SessionID, "$"))
			b, _ := strconv.Atoi(strings.TrimPrefix(panes[j].SessionID, "$"))
			return a < b
		}
		if panes[i].Index != panes[j].Index {
			return panes[i].Index < panes[j].Index
		}
		return panes[i].ID < panes[j].ID
	})
	for i := range panes {
		panes[i].ParentName = names[panes[i].Parent]
	}
	var snapshot bytes.Buffer
	if err := tmuxSnapshot(&snapshot, runner); err != nil {
		return result, err
	}
	paneDir := paths.AgentPanes()
	payload, err := json.Marshal(map[string]any{"panes": panes, "snapshot": json.RawMessage(snapshot.Bytes()), "panes_dir": paneDir, "history_file": history})
	if err != nil {
		return result, err
	}
	output, err := call(runner, cfg.Presentation[0], cfg.Presentation[1:], bytes.NewReader(payload))
	if err != nil {
		return result, fmt.Errorf("render native terminal presentation: %w", err)
	}
	if err = json.Unmarshal(output, &result); err != nil {
		return result, fmt.Errorf("decode terminal presentation: %w", err)
	}
	return result, nil
}

func loadPresentation(cfg pickerConfig, runner commandRunner, fresh bool) (presentation, error) {
	root, ok, err := paths.GetE(paths.AgentsKey)
	if err != nil {
		return presentation{}, err
	}
	if !ok {
		home, e := paths.StateHomeE()
		if e != nil {
			return presentation{}, e
		}
		root = filepath.Join(home, "agents")
	}
	socket := os.Getenv("TMUX")
	if end := strings.LastIndex(socket, ","); end >= 0 {
		socket = socket[:end]
	}
	key := sha256.Sum256([]byte(socket))
	dir := filepath.Join(root, "tmux-ui", hex.EncodeToString(key[:8]))
	if err = os.MkdirAll(dir, 0700); err != nil {
		return presentation{}, err
	}
	lock, err := os.OpenFile(filepath.Join(dir, "lock"), os.O_CREATE|os.O_RDWR, 0600)
	if err != nil {
		return presentation{}, err
	}
	defer func() { _ = lock.Close() }()
	if err = unix.Flock(int(lock.Fd()), unix.LOCK_EX); err != nil {
		return presentation{}, err
	}
	defer func() { _ = unix.Flock(int(lock.Fd()), unix.LOCK_UN) }()
	file := filepath.Join(dir, "presentation.json")
	if !fresh {
		if st, err := os.Stat(file); err == nil && time.Since(st.ModTime()) < time.Second {
			if body, err := os.ReadFile(file); err == nil {
				var p presentation
				if json.Unmarshal(body, &p) == nil {
					return p, nil
				}
			}
		}
	}
	p, err := collectPresentation(cfg, runner, filepath.Join(dir, "history.json"))
	if err != nil {
		return p, err
	}
	body, err := json.Marshal(p)
	if err != nil {
		return p, err
	}
	tmp, err := os.CreateTemp(dir, "presentation-*.json")
	if err != nil {
		return p, err
	}
	name := tmp.Name()
	defer func() { _ = os.Remove(name) }()
	if _, err = tmp.Write(body); err != nil {
		_ = tmp.Close()
		return p, err
	}
	if err = tmp.Close(); err != nil {
		return p, err
	}
	if err = os.Rename(name, file); err != nil {
		return p, err
	}
	return p, nil
}

func renderNative(items nativeItems, width int, tmux bool) string {
	var out strings.Builder
	remaining := width
	color := func(value string, background bool) {
		if tmux {
			key := "fg"
			if background {
				key = "bg"
			}
			fmt.Fprintf(&out, "#[%s=%s]", key, value)
			return
		}
		value = strings.TrimPrefix(value, "#")
		rgb, err := strconv.ParseUint(value, 16, 32)
		if err != nil {
			return
		}
		kind := 38
		if background {
			kind = 48
		}
		fmt.Fprintf(&out, "\x1b[%d;2;%d;%d;%dm", kind, (rgb>>16)&255, (rgb>>8)&255, rgb&255)
	}
	for _, raw := range items {
		if len(raw) > 0 && raw[0] == '"' {
			if tmux {
				out.WriteString("#[default]")
			} else {
				out.WriteString("\x1b[0m")
			}
			continue
		}
		var item nativeItem
		if json.Unmarshal(raw, &item) != nil {
			continue
		}
		if item.Foreground != nil {
			color(item.Foreground.Color, false)
		}
		if item.Background != nil {
			color(item.Background.Color, true)
		}
		if item.Attribute != nil {
			if item.Attribute.Intensity == "Normal" {
				if tmux {
					out.WriteString("#[nobold,nodim]")
				} else {
					out.WriteString("\x1b[22m")
				}
			}
			if item.Attribute.Intensity == "Half" {
				if tmux {
					out.WriteString("#[dim]")
				} else {
					out.WriteString("\x1b[2m")
				}
			}
			if item.Attribute.Intensity == "Bold" {
				if tmux {
					out.WriteString("#[bold]")
				} else {
					out.WriteString("\x1b[1m")
				}
			}
			if item.Attribute.Underline == "Single" {
				if tmux {
					out.WriteString("#[underscore]")
				} else {
					out.WriteString("\x1b[4m")
				}
			}
		}
		text := strings.Map(func(r rune) rune {
			if unicode.IsControl(r) {
				return ' '
			}
			return r
		}, item.Text)
		if remaining <= 0 {
			continue
		}
		text = cell.Truncate(text, remaining)
		remaining -= cell.Width(text)
		if tmux {
			text = strings.ReplaceAll(text, "#", "##")
		}
		out.WriteString(text)
	}
	if tmux {
		out.WriteString("#[default]")
	} else {
		out.WriteString("\x1b[0m")
	}
	return out.String()
}

func statusStyle(style nativeStyle) string {
	fg, bg := style.FG, style.BG
	if fg == "" {
		fg = "default"
	}
	if bg == "" {
		bg = "default"
	}
	return "#[fg=" + fg + ",bg=" + bg + "]"
}
func renderTmuxStatus(p presentation, session string, width int, window string, locked bool, modes ...string) string {
	var current *presentationSession
	for i := range p.Sessions {
		if p.Sessions[i].ID == session {
			current = &p.Sessions[i]
			break
		}
	}
	if current == nil || width < 1 {
		return ""
	}
	mode := "NORMAL"
	palette := p.Mode
	if len(modes) > 0 && modes[0] == "COPY" {
		mode = "COPY"
		palette = p.CopyMode
	}
	icon := strings.TrimSpace(p.Icons.Unlocked)
	if locked {
		mode = "LOCKED"
		icon = strings.TrimSpace(p.Icons.Locked)
	}
	modeText := mode + " " + icon + " "
	if width < 50 {
		modeText = icon + " "
	}
	left := statusStyle(palette) + "#[bold]" + strings.ReplaceAll(modeText, "#", "##") + "#[default]"
	used := cell.Width(modeText)
	windows := []presentationWindow{}
	hostItems := nativeItems{}
	hostText := ""
	for _, w := range p.Windows {
		if w.Session == current.Name {
			windows = append(windows, w)
			if w.ID == window {
				hostItems, hostText = w.Host, w.HostText
			}
		}
	}
	hostWidth := min(cell.Width(hostText), max(7, width/4))
	reserve := min(cell.Width(current.Text), max(8, width/2))
	tabBudget := max(0, width-used-hostWidth-reserve-1)
	total := 0
	for _, w := range windows {
		total += cell.Width(w.Text) + 1
	}
	if total > tabBudget {
		sort.SliceStable(windows, func(i, j int) bool { return windows[i].ID == window && windows[j].ID != window })
	}
	for _, w := range windows {
		if tabBudget < 3 {
			break
		}
		budget := min(tabBudget-1, cell.Width(w.Text))
		if w.ID != window {
			budget = min(budget, 24)
		}
		if budget < 1 {
			break
		}
		label := renderNativePriority(w.Items, w.Tail, w.TailText, budget)
		base := p.Tabs.Inactive
		if w.ID == window {
			base = p.Tabs.Active
		}
		style := statusStyle(nativeStyle{FG: base.FG, BG: base.BG})
		left += "#[range=window|" + strconv.Itoa(w.Index) + "]" + style + strings.ReplaceAll(label, "#[default]", style) + "#[default,norange] "
		visible := min(cell.Width(w.Text), budget) + 1
		used += visible
		tabBudget -= visible
	}
	rightBudget := max(0, width-used-hostWidth)
	sessions := append([]presentationSession(nil), p.Sessions...)
	sort.SliceStable(sessions, func(i, j int) bool { return sessions[i].ID == session && sessions[j].ID != session })
	var right strings.Builder
	rightWidth := 0
	for _, s := range sessions {
		budget := rightBudget - rightWidth
		if budget < 1 {
			break
		}
		if s.ID != session && cell.Width(s.Text) > budget {
			continue
		}
		items := s.Inactive
		if s.ID == session {
			items = s.Items
		}
		style := p.Tabs.Inactive
		if s.ID == session {
			style = p.Tabs.Active
		}
		base := statusStyle(nativeStyle{FG: style.FG, BG: style.BG})
		label := renderNativePriority(items, s.Tail, s.TailText, budget)
		right.WriteString(strings.ReplaceAll(label, "#[default]", base) + "#[default]")
		rightWidth += min(cell.Width(s.Text), budget)
	}
	hostStyle := statusStyle(p.Host)
	host := hostStyle + "#[bold]" + strings.ReplaceAll(renderNative(hostItems, hostWidth, true), "#[default]", hostStyle) + "#[default]"
	return left + statusStyle(p.Center) + strings.Repeat(" ", max(0, width-used-rightWidth-hostWidth)) + "#[default]" + right.String() + host
}
func renderNativePriority(items, tail nativeItems, tailText string, width int) string {
	tailWidth := min(cell.Width(tailText), width)
	return renderNative(items, max(0, width-tailWidth), true) + renderNative(tail, tailWidth, true)
}

func runTmuxUI(args []string, stdout io.Writer, runner commandRunner) error {
	if len(args) == 2 && args[0] == "session-slot" {
		slot, err := strconv.Atoi(args[1])
		if err != nil || slot < 1 || slot > 9 {
			return invalidUsage("session slot must be 1-9")
		}
		cfg, err := pickerSettings()
		if err != nil {
			return err
		}
		p, err := loadPresentation(cfg, runner, true)
		if err != nil {
			return err
		}
		for _, session := range p.Sessions {
			if session.Slot == slot {
				return switchSession(runner, session.Name)
			}
		}
		return fmt.Errorf("session slot %d is empty", slot)
	}
	if len(args) != 6 || args[0] != "status" {
		return invalidUsage("usage: ty tmux ui status <session-id> <width> <window-id> <locked> <mode>")
	}
	width, err := strconv.Atoi(args[2])
	if err != nil || width < 1 {
		return fmt.Errorf("invalid status width")
	}
	cfg, err := pickerSettings()
	if err != nil {
		return err
	}
	p, err := loadPresentation(cfg, runner, false)
	if err != nil {
		return err
	}
	_, err = io.WriteString(stdout, renderTmuxStatus(p, args[1], width, args[3], args[4] == "1", args[5]))
	return err
}
