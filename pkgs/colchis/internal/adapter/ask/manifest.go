package ask

import (
	"encoding/json"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
)

var startRequestSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object",
  "required":["prompt","provider","responseSchema","responseSchemaDigest"],
  "properties":{
    "prompt":{"type":"string","minLength":1},"input":{"type":"string"},
    "provider":{"type":"string","minLength":1,"maxLength":128},
    "model":{"type":"string","minLength":1,"maxLength":128},
    "responseSchema":{"type":"object"},
    "responseSchemaDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"}
  },
  "additionalProperties":false
}`)

var startResponseSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["status","provider"],
  "properties":{
    "status":{"enum":["completed","needs-input"]},
    "provider":{"type":"string","minLength":1},"model":{"type":"string"},
    "value":{},"question":{"type":"string","minLength":1},"stderr":{"type":"string"}
  },
  "oneOf":[
    {"properties":{"status":{"const":"completed"}},"required":["value"]},
    {"properties":{"status":{"const":"needs-input"}},"required":["question"]}
  ],
  "additionalProperties":false
}`)

func Manifest() (plugin.AdapterManifest, error) {
	start, err := plugin.NewSchemaContract(startRequestSchema, startResponseSchema, false, false)
	if err != nil {
		return plugin.AdapterManifest{}, err
	}
	return plugin.AdapterManifest{
		ID: AdapterID, Port: domain.AdapterPortAgentRuntime,
		Capabilities:   []string{"job-policy", "one-shot", "structured-result", "queued-input"},
		HandleVersions: []uint32{1},
		Operations:     map[string]plugin.SchemaContract{OperationStart: start},
	}, nil
}
