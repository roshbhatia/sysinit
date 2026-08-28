package activity

import (
	"encoding/json"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
)

var importRequestSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["sources"],
  "properties":{
    "workspace":{"type":"string","minLength":1},"session":{"type":"string","minLength":1},
    "sources":{"type":"array","minItems":1,"items":{"enum":["traces","agent-edit-event"]},"uniqueItems":true},
    "afterUnixMillis":{"type":"integer","minimum":0},
    "maxRecords":{"type":"integer","minimum":1,"maximum":1000}
  },
  "additionalProperties":false
}`)

var observeRequestSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["sourceId","sources"],
  "properties":{
    "sourceId":{"type":"string","minLength":1},
    "workspace":{"type":"string","minLength":1},"session":{"type":"string","minLength":1},
    "sources":{"type":"array","minItems":1,"items":{"enum":["traces","agent-edit-event"]},"uniqueItems":true},
    "afterUnixMillis":{"type":"integer","minimum":0},
    "maxRecords":{"type":"integer","minimum":1,"maximum":1000}
  },
  "additionalProperties":false
}`)

var responseSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["records","sourceDigest","totalRecords","truncated"],
  "properties":{
    "records":{"type":"array","items":{"$ref":"#/$defs/record"}},
    "sourceDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"},
    "totalRecords":{"type":"integer","minimum":0},"truncated":{"type":"boolean"}
  },
  "additionalProperties":false,
  "$defs":{
    "record":{
      "type":"object",
      "required":["source","sourceId","kind","basis","authority","startedAt","opaqueData"],
      "properties":{
        "source":{"enum":["traces","agent-edit-event"]},"sourceId":{"type":"string","minLength":1},
        "parentSourceId":{"type":"string","minLength":1},
        "kind":{"enum":["session","turn","model_call","tool_call"]},
        "provider":{"type":"string"},"session":{"type":"string"},
        "basis":{"const":"adapter_reported"},"authority":{"const":"advisory"},
        "startedAt":{"type":"string","format":"date-time"},
        "endedAt":{"type":"string","format":"date-time"},"opaqueData":{"type":"object"}
      },
      "additionalProperties":false
    }
  }
}`)

func Manifest() (plugin.AdapterManifest, error) {
	importContract, err := plugin.NewSchemaContract(importRequestSchema, responseSchema, true, true)
	if err != nil {
		return plugin.AdapterManifest{}, err
	}
	observe, err := plugin.NewSchemaContract(observeRequestSchema, responseSchema, true, true)
	if err != nil {
		return plugin.AdapterManifest{}, err
	}
	return plugin.AdapterManifest{
		ID: AdapterID, Port: domain.AdapterPortActivity,
		Capabilities:   []string{"activity.traces", "activity.edit-events", "activity.advisory"},
		HandleVersions: []uint32{1},
		Operations: map[string]plugin.SchemaContract{
			OperationImport: importContract, OperationObserve: observe,
		},
	}, nil
}
