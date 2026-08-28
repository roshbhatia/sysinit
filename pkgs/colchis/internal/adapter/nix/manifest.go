package nix

import (
	"encoding/json"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
)

var resolveRequestSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["workspace","shell","snapshotDigest"],
  "properties":{
    "workspace":{"type":"string","minLength":1},
    "flakeReference":{"type":"string","minLength":1},
    "shell":{"$ref":"#/$defs/id"},
    "snapshotDigest":{"$ref":"#/$defs/digest"}
  },
  "additionalProperties":false,
  "$defs":{
    "id":{"type":"string","minLength":1,"maxLength":128},
    "digest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"}
  }
}`)

var executeRequestSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["command","secretNames","expectedSnapshotDigest"],
  "properties":{
    "command":{"type":"array","minItems":1,"items":{"type":"string"}},
    "stdin":{"type":"string"},
    "secretNames":{"type":"array","items":{"type":"string","minLength":1},"uniqueItems":true},
    "expectedSnapshotDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"}
  },
  "additionalProperties":false
}`)

var checkRequestSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["checks","expectedSnapshotDigest"],
  "properties":{
    "checks":{"type":"array","minItems":1,"items":{"type":"string","minLength":1,"maxLength":128},"uniqueItems":true},
    "expectedSnapshotDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"}
  },
  "additionalProperties":false
}`)

var resolveResponseSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["environment"],
  "properties":{"environment":{"$ref":"#/$defs/environment"}},
  "additionalProperties":false,
  "$defs":{
    "digest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"},
    "environment":{
      "type":"object",
      "required":["id","system","flakeReference","shell","derivation","lockDigest","snapshotDigest","sandbox","opaqueMetadata"],
      "properties":{
        "id":{"$ref":"#/$defs/digest"},"system":{"type":"string","minLength":1},
        "flakeReference":{"type":"string","minLength":1},"shell":{"type":"string","minLength":1},
        "derivation":{"type":"string","pattern":"^/nix/store/"},
        "lockDigest":{"$ref":"#/$defs/digest"},"snapshotDigest":{"$ref":"#/$defs/digest"},
        "sandbox":{"const":"nix-develop"},"opaqueMetadata":{"type":"object"}
      },"additionalProperties":false
    }
  }
}`)

var executeResponseSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object",
  "required":["environmentId","snapshotDigest","exitCode","stdout","stderr"],
  "properties":{
    "environmentId":{"$ref":"#/$defs/digest"},"snapshotDigest":{"$ref":"#/$defs/digest"},
    "exitCode":{"type":"integer"},"stdout":{"type":"string"},"stderr":{"type":"string"}
  },
  "additionalProperties":false,
  "$defs":{"digest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"}}
}`)

var checkResponseSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["environmentId","snapshotDigest","checks"],
  "properties":{
    "environmentId":{"$ref":"#/$defs/digest"},"snapshotDigest":{"$ref":"#/$defs/digest"},
    "checks":{"type":"array","items":{"$ref":"#/$defs/check"}}
  },
  "additionalProperties":false,
  "$defs":{
    "digest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"},
    "check":{
      "type":"object","required":["name","exitCode","build","stderr"],
      "properties":{
        "name":{"type":"string","minLength":1},"exitCode":{"type":"integer"},
        "build":{"type":"array"},"stderr":{"type":"string"}
      },"additionalProperties":false
    }
  }
}`)

func Manifest() (plugin.AdapterManifest, error) {
	resolve, err := plugin.NewSchemaContract(resolveRequestSchema, resolveResponseSchema, true, true)
	if err != nil {
		return plugin.AdapterManifest{}, err
	}
	execute, err := plugin.NewSchemaContract(executeRequestSchema, executeResponseSchema, false, false)
	if err != nil {
		return plugin.AdapterManifest{}, err
	}
	check, err := plugin.NewSchemaContract(checkRequestSchema, checkResponseSchema, true, true)
	if err != nil {
		return plugin.AdapterManifest{}, err
	}
	return plugin.AdapterManifest{
		ID: AdapterID, Port: domain.AdapterPortEnvironment,
		Capabilities: []string{
			"environment.nix", "environment.snapshot-bound", "environment.named-secrets",
		},
		HandleVersions: []uint32{2},
		Operations: map[string]plugin.SchemaContract{
			OperationResolve: resolve, OperationExecute: execute, OperationCheck: check,
		},
	}, nil
}
