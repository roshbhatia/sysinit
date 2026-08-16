package schema

import "maps"

// Field is the one key an agent uses to ask a question instead of answering.
const Field = "clarify"

// Rule tells the agent that the question is available. Without it the agent
// meets an ambiguous request by guessing, and the guess comes back in the right
// shape, which reads as a good answer.
const Rule = "If this request is ambiguous and a wrong guess costs more than a question does, " +
	"answer with {\"" + Field + "\": \"<one short question>\"} and nothing else. " +
	"Ask at most one question at a time. Otherwise answer in the shape asked for."

// Relaxed answers with the shape to hand the agent, and with whether a question
// is one of the answers it may give.
//
// "An answer or a question" is a union, and the Anthropic API rejects anyOf,
// oneOf and allOf at the top level of a tool schema: `input_schema does not
// support oneOf, allOf, or anyOf at the top level`. So the wire carries a shape
// loose enough to hold either, and Check enforces the strict one here. A partial
// answer is caught by that check rather than by the agent.
func Relaxed(shape map[string]any) (map[string]any, bool) {
	if shape == nil {
		return nil, false
	}
	if Free(shape) {
		return shape, true
	}

	properties, named := shape["properties"].(map[string]any)
	if !named {
		return shape, false
	}

	loose := maps.Clone(shape)
	widened := maps.Clone(properties)
	widened[Field] = map[string]any{"type": "string"}
	loose["properties"] = widened
	delete(loose, "required")
	return loose, true
}

// Question reads back the question an agent asked, or "" when it answered. It
// insists on a lone field, so an answer that happens to hold a clarify note
// beside its real fields is still an answer.
func Question(reply map[string]any) string {
	if len(reply) != 1 {
		return ""
	}
	asked, _ := reply[Field].(string)
	return asked
}
