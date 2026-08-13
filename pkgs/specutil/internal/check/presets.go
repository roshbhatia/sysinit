package check

// presets are built-in rubrics, keyed by the spec-framework schema name they describe.
var presets = map[string][]RuleConfig{
	// spec-driven mirrors the rubric the specreview shell lint enforced, rule for rule, so
	// a repository can drop that script and get the same verdicts from specutil.
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
			// `openspec validate` cannot check this.
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
				// A rollout slice sequences the impactful actions; it is exempt
				// from declaring a work shape.
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
			// The schema's own words: "STOP is a command, not a wish." A prose STOP
			// cannot be evaluated, so the loop ends when the model decides it is
			// done, and `loop-gate arm --until` has nothing to run.
			ID:   "phase-marker-pattern",
			Name: "stop-is-a-command",
			Params: map[string]any{
				"marker": "stop",
				"when":   map[string]any{"marker": "shape", "value": "loop"},
				// Any backtick span is too weak: a stop that says "`lib/x.nix` passes fixtures"
				// names a file, not something to run, and passed.
				"pattern":  "`(nix|nh|task|specutil|openspec|citelock|loop-gate|git|jq|go|python3?|bash|sh|shellcheck|shfmt|pytest|npm|bun|cargo|make)\\b[^`]*`",
				"describe": "open a backtick span with a command",
			},
		},
		{ID: "task-deps-resolve"},
		{
			// A graph models fan-out, and its subtasks MAY carry a `deps:`, so a zero-edge graph
			// is legal.
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
			// 60 words is roughly four sentences: enough to state an outcome and its gate, not
			// enough to hold a history.
			ID:       "task-text-max-words",
			Severity: SeverityWarn,
			Params:   map[string]any{"max": 60},
		},
		{ID: "no-em-dash"},
		{
			ID: "bolded-bullet-lead",
			Params: map[string]any{
				"allow": []string{
					// POLARITY stays allowed: no preset requires a polarity marker
					// any more, but archived and other-repo spec files still carry
					// one, and rewriting them would be churn for no signal.
					"WHEN", "THEN", "AND", "POLARITY", "SHAPE", "STOP", "MAX-ITERS", "BREAKING",
				},
			},
		},
		{
			// A change nobody approved is not ready, and an approval given before the artifacts
			// moved is not an approval of what is there now.
			ID: "review-decision-current",
			Params: map[string]any{
				"accept": []string{"approved"},
			},
		},
	},
}

// aliases map retired schema names onto a live preset key.
var aliases = map[string]string{
	"rosh-spec-driven": "spec-driven",
}

// resolvePresetName returns the live preset key for name.
func resolvePresetName(name string) string {
	if _, ok := presets[name]; ok {
		return name
	}
	if target, ok := aliases[name]; ok {
		return target
	}
	return name
}
