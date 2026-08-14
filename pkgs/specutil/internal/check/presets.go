package check

var presets = map[string][]RuleConfig{
	"spec-driven": {
		{
			ID:   "required-sections",
			Name: "proposal-sections",
			Params: map[string]any{
				"artifact": "proposal",
				"sections": []string{"### Non-goals", "## Behavior"},
			},
		},
		{
			ID:   "section-min-bullets",
			Name: "behavior-has-criteria",
			Params: map[string]any{
				"artifact": "proposal",
				"section":  "## Behavior",
				"min":      1,
			},
		},
		{
			ID:   "required-sections",
			Name: "design-sections",
			Params: map[string]any{
				"artifact": "design",
				"sections": []string{"## Decisions", "## Rollout & Gating", "## Adversarial Review"},
			},
		},
		{
			ID: "paired-bullet",
			Params: map[string]any{
				"artifact": "design",
				"lead":     "- Decision:",
				"follower": "- Alternative rejected:",
			},
		},
		{
			ID: "phase-marker-required",
			Params: map[string]any{
				"marker":        "shape",
				"allowedValues": []string{"loop", "graph"},

				"skipPhasePattern": "(?i)rollout",
			},
		},
		{
			ID: "phase-marker-conditional",
			Params: map[string]any{
				"when":             map[string]any{"marker": "shape", "value": "loop"},
				"require":          []string{"stop", "maxIters"},
				"skipPhasePattern": "(?i)rollout",
			},
		},
		{
			ID: "phase-task-pattern",
			Params: map[string]any{
				"pattern":          `(?i)adversarial\s+review`,
				"describe":         "adversarial-review task",
				"skipPhasePattern": "(?i)rollout",
			},
		},
		{
			ID:   "phase-marker-pattern",
			Name: "stop-is-a-command",
			Params: map[string]any{
				"marker": "stop",
				"when":   map[string]any{"marker": "shape", "value": "loop"},

				"pattern":  "`(nix|nh|task|specutil|openspec|citelock|loop-gate|git|jq|go|python3?|bash|sh|shellcheck|shfmt|pytest|npm|bun|cargo|make)\\b[^`]*`",
				"describe": "open a backtick span with a command",
			},
		},
		{ID: "task-deps-resolve"},
		{
			ID:       "phase-edges-declared",
			Severity: SeverityWarn,
			Params: map[string]any{
				"when":             map[string]any{"marker": "shape", "value": "graph"},
				"skipPhasePattern": "(?i)rollout",
			},
		},
		{ID: "task-id-required"},
		{ID: "task-id-matches-phase"},
		{ID: "task-deps-acyclic"},
		{
			ID:       "task-text-max-words",
			Severity: SeverityWarn,
			Params:   map[string]any{"max": 60},
		},
		{ID: "no-em-dash"},
		{
			ID: "bolded-bullet-lead",
			Params: map[string]any{
				"allow": []string{
					"WHEN", "THEN", "AND", "POLARITY", "SHAPE", "STOP", "MAX-ITERS", "BREAKING",
				},
			},
		},
		{
			ID: "review-decision-current",
			Params: map[string]any{
				"accept": []string{"approved"},
			},
		},
	},
}

var aliases = map[string]string{
	"rosh-spec-driven": "spec-driven",
}

func resolvePresetName(name string) string {
	if _, ok := presets[name]; ok {
		return name
	}
	if target, ok := aliases[name]; ok {
		return target
	}
	return name
}
