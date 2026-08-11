package parse

import (
	"bytes"

	"github.com/yuin/goldmark"
	"github.com/yuin/goldmark/ast"
	"github.com/yuin/goldmark/extension"
	east "github.com/yuin/goldmark/extension/ast"
	"github.com/yuin/goldmark/text"
)

// md is the shared goldmark instance. The TaskList extension is enabled so that
// `- [ ]` / `- [x]` checkboxes parse into TaskCheckBox nodes, giving us the done
// state without hand-rolling checkbox scanning.
var md = goldmark.New(goldmark.WithExtensions(extension.TaskList))

// listItem is one top-level bullet extracted from a markdown fragment.
type listItem struct {
	text    string // item text with any leading checkbox stripped
	checked bool
	hasBox  bool // whether the item carried a [ ]/[x] checkbox
}

// extractListItems parses a markdown fragment and returns its top-level list
// items in document order, flattening across multiple sibling lists. It is used
// for both capability bullets and task checkboxes.
func extractListItems(src string) []listItem {
	source := []byte(src)
	doc := md.Parser().Parse(text.NewReader(source))
	var items []listItem

	for n := doc.FirstChild(); n != nil; n = n.NextSibling() {
		list, ok := n.(*ast.List)
		if !ok {
			continue
		}
		for li := list.FirstChild(); li != nil; li = li.NextSibling() {
			item, ok := li.(*ast.ListItem)
			if !ok {
				continue
			}
			it := listItem{}
			if box := firstTaskCheckBox(item); box != nil {
				it.hasBox = true
				it.checked = box.IsChecked
			}
			it.text = string(bytes.TrimSpace(itemText(item, source)))
			items = append(items, it)
		}
	}
	return items
}

// firstTaskCheckBox returns the TaskCheckBox at the start of a list item, or nil.
func firstTaskCheckBox(item *ast.ListItem) *east.TaskCheckBox {
	var found *east.TaskCheckBox
	_ = ast.Walk(item, func(n ast.Node, entering bool) (ast.WalkStatus, error) {
		if !entering {
			return ast.WalkContinue, nil
		}
		if box, ok := n.(*east.TaskCheckBox); ok {
			found = box
			return ast.WalkStop, nil
		}
		return ast.WalkContinue, nil
	})
	return found
}

// itemText reconstructs the visible text of a list item's first paragraph from
// the source, preserving inline emphasis markers and code spans verbatim so the
// downstream regex can recover `**name**` bold runs.
func itemText(item *ast.ListItem, source []byte) []byte {
	var buf bytes.Buffer
	// Only the first child block (the item's lead paragraph/text) is the item
	// label; nested lists are descended into separately by the caller's list walk.
	first := item.FirstChild()
	if first == nil {
		return nil
	}
	collectRaw(first, source, &buf)
	return buf.Bytes()
}

// collectRaw walks a node subtree and appends the raw source spans of its text,
// code, and emphasis markers in order.
func collectRaw(node ast.Node, source []byte, buf *bytes.Buffer) {
	switch n := node.(type) {
	case *east.TaskCheckBox:
		return // skip the checkbox glyph itself
	case *ast.Text:
		buf.Write(n.Segment.Value(source))
		if n.SoftLineBreak() || n.HardLineBreak() {
			buf.WriteByte(' ')
		}
		return
	case *ast.String:
		buf.Write(n.Value)
		return
	case *ast.CodeSpan:
		buf.WriteByte('`')
		for c := n.FirstChild(); c != nil; c = c.NextSibling() {
			collectRaw(c, source, buf)
		}
		buf.WriteByte('`')
		return
	case *ast.Emphasis:
		marker := bytes.Repeat([]byte{'*'}, n.Level)
		buf.Write(marker)
		for c := n.FirstChild(); c != nil; c = c.NextSibling() {
			collectRaw(c, source, buf)
		}
		buf.Write(marker)
		return
	}
	for c := node.FirstChild(); c != nil; c = c.NextSibling() {
		collectRaw(c, source, buf)
	}
}
