package schema

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"
)

func Any() map[string]any {
	return map[string]any{"type": "object", "additionalProperties": true}
}

var kinds = map[string]string{
	"string":  "string",
	"str":     "string",
	"text":    "string",
	"int":     "integer",
	"integer": "integer",
	"number":  "number",
	"float":   "number",
	"bool":    "boolean",
	"boolean": "boolean",
	"object":  "object",
	"any":     "",
}

func typeOf(text string) (map[string]any, error) {
	if strings.HasPrefix(text, "[]") {
		inner, err := typeOf(strings.TrimPrefix(text, "[]"))
		if err != nil {
			return nil, err
		}
		return map[string]any{"type": "array", "items": inner}, nil
	}

	if strings.Contains(text, "|") {
		var values []string
		for _, value := range strings.Split(text, "|") {
			value = strings.TrimSpace(value)
			if value != "" {
				values = append(values, value)
			}
		}
		if len(values) < 2 {
			return nil, fmt.Errorf("an enum needs at least two values, got %q", text)
		}
		return map[string]any{"type": "string", "enum": values}, nil
	}
	kind, ok := kinds[text]
	if !ok {
		return nil, fmt.Errorf("unknown type %q", text)
	}
	if kind == "" {
		return map[string]any{}, nil
	}
	return map[string]any{"type": kind}, nil
}

func Build(spec string) (map[string]any, error) {
	properties := map[string]any{}
	required := []string{}

	for _, field := range split(spec) {
		field = strings.TrimSpace(field)
		if field == "" {
			continue
		}
		name, rest, found := strings.Cut(field, ":")
		if !found {
			return nil, fmt.Errorf("field %q has no type, write it as name:type", field)
		}
		name = strings.TrimSpace(name)
		rest = strings.TrimSpace(rest)
		optional := strings.HasSuffix(rest, "?")
		rest = strings.TrimSuffix(rest, "?")

		kind, err := typeOf(rest)
		if err != nil {
			return nil, fmt.Errorf("field %q: %w", name, err)
		}
		properties[name] = kind
		if !optional {
			required = append(required, name)
		}
	}

	if len(properties) == 0 {
		return nil, fmt.Errorf("the spec named no fields")
	}
	built := map[string]any{
		"type":                 "object",
		"properties":           properties,
		"additionalProperties": false,
	}
	if len(required) > 0 {
		built["required"] = required
	}
	return built, nil
}

func split(spec string) []string {
	var fields []string
	depth := 0
	start := 0
	for at, letter := range spec {
		switch letter {
		case '[', '{':
			depth++
		case ']', '}':
			depth--
		case ',':
			if depth == 0 {
				fields = append(fields, spec[start:at])
				start = at + 1
			}
		}
	}
	return append(fields, spec[start:])
}

func Load(path string) (map[string]any, error) {
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var built map[string]any
	if err := json.Unmarshal(raw, &built); err != nil {
		return nil, fmt.Errorf("%s is not JSON: %w", path, err)
	}
	return built, nil
}

func Resolve(argument string) (map[string]any, error) {
	if strings.HasPrefix(argument, "@") {
		return Load(strings.TrimPrefix(argument, "@"))
	}
	return Build(argument)
}
