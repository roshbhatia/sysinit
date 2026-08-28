package note

import (
	"encoding/json"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
)

var syncRequestSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","properties":{
    "file":{"type":"string","minLength":1},"openOnly":{"type":"boolean"}
  },"additionalProperties":false
}`)

var answerRequestSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["id","summary"],"properties":{
    "id":{"type":"string","minLength":1},"summary":{"type":"string","minLength":1},
    "rationale":{"type":"string"},"author":{"type":"string","minLength":1}
  },"additionalProperties":false
}`)

var responseSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["records","sourceDigest"],"properties":{
    "records":{"type":"array","items":{"$ref":"#/$defs/record"}},
    "sourceDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"}
  },"additionalProperties":false,"$defs":{
    "record":{"type":"object","required":[
      "source","sourceId","kind","summary","author","origin","state","authority","anchor"
    ],"properties":{
      "source":{"const":"utils-note"},"sourceId":{"type":"string","minLength":1},
      "replyTo":{"type":"string","minLength":1},"kind":{"enum":["annotation","reply"]},
      "summary":{"type":"string","minLength":1},"rationale":{"type":"string"},
      "author":{"type":"string","minLength":1},"origin":{"enum":["agent","user"]},
      "state":{"enum":["open","answered"]},"authority":{"enum":["owner","advisory"]},
      "anchor":{"type":"object","required":["file","line","text"],"properties":{
        "file":{"type":"string","minLength":1},"line":{"type":"integer","minimum":1},"text":{"type":"string"}
      },"additionalProperties":false}
    },"additionalProperties":false}
  }
}`)

func Manifest() (plugin.AdapterManifest, error) {
	syncContract, err := plugin.NewSchemaContract(syncRequestSchema, responseSchema, true, true)
	if err != nil {
		return plugin.AdapterManifest{}, err
	}
	answerContract, err := plugin.NewSchemaContract(answerRequestSchema, responseSchema, false, false)
	if err != nil {
		return plugin.AdapterManifest{}, err
	}
	return plugin.AdapterManifest{
		ID: AdapterID, Port: domain.AdapterPortAnnotation,
		Capabilities:   []string{"annotation.utils-note", "annotation.owner-authority", "annotation.replies"},
		HandleVersions: []uint32{1},
		Operations: map[string]plugin.SchemaContract{
			OperationSync: syncContract, OperationAnswer: answerContract,
		},
	}, nil
}
