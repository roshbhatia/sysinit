package schema

import "maps"

// Field is the one key an agent uses to ask a question instead of answering.
const Field = "clarify"

// Rule tells the agent that the question is available.
const Rule = "If this request is ambiguous and a wrong guess costs more than a question does, " +
	"answer with {\"" + Field + "\": \"<one short question>\"} and nothing else. " +
	"Ask at most one question at a time. Otherwise answer in the shape asked for."

// Relaxed answers the shape to send, and whether a question may be answered with.
//
// "An answer or a question" is a union, and the Anthropic API rejects anyOf at
// the top level of a tool schema, so the wire carries a shape loose enough to
// hold either and Check enforces the strict one.
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

// Question reads back the question an agent asked, or "" when it answered. A
// lone field is required, so a clarify note beside real fields is still an answer.
func Question(reply map[string]any) string {
	if len(reply) != 1 {
		return ""
	}
	asked, _ := reply[Field].(string)
	return asked
}
