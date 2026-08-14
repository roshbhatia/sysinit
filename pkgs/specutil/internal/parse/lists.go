package parse

import (
	"bytes"

	"github.com/yuin/goldmark"
	"github.com/yuin/goldmark/ast"
	"github.com/yuin/goldmark/extension"
	east "github.com/yuin/goldmark/extension/ast"
	"github.com/yuin/goldmark/text"
)

var md = goldmark.New(goldmark.WithExtensions(extension.TaskList))

type listItem struct {
	text    string
	checked bool
	hasBox  bool
}

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

func itemText(item *ast.ListItem, source []byte) []byte {
	var buf bytes.Buffer

	first := item.FirstChild()
	if first == nil {
		return nil
	}
	collectRaw(first, source, &buf)
	return buf.Bytes()
}

func collectRaw(node ast.Node, source []byte, buf *bytes.Buffer) {
	switch n := node.(type) {
	case *east.TaskCheckBox:
		return
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
