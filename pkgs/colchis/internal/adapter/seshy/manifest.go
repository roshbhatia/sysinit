package seshy

import (
	"encoding/json"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
)

var createRequestSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["name","repositories"],
  "properties":{
    "name":{"$ref":"#/$defs/id"},
    "repositories":{"type":"array","items":{"type":"string","minLength":1},"uniqueItems":true},
    "branch":{"type":"string"}
  },
  "additionalProperties":false,
  "$defs":{"id":{"type":"string","minLength":1,"maxLength":128}}
}`)

var repositoryRequestSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["repository"],
  "properties":{
    "name":{"type":"string","minLength":1,"maxLength":128},
    "repository":{"type":"string","minLength":1},
    "branch":{"type":"string"}
  },
  "additionalProperties":false
}`)

var workspaceRequestSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object",
  "properties":{"name":{"type":"string","minLength":1,"maxLength":128}},
  "additionalProperties":false
}`)

var closeRequestSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","additionalProperties":false
}`)

var workspaceResponseSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["workspace","sourceDigest"],
  "properties":{
    "workspace":{"$ref":"#/$defs/workspace"},
    "sourceDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"}
  },
  "additionalProperties":false,
  "$defs":{
    "repository":{
      "type":"object","required":["name","path"],
      "properties":{"name":{"type":"string","minLength":1},"path":{"type":"string","minLength":1},"branch":{"type":"string"}},
      "additionalProperties":false
    },
    "workspace":{
      "type":"object","required":["name","path","repositories"],
      "properties":{
        "name":{"type":"string","minLength":1},"path":{"type":"string","minLength":1},
        "repositories":{"type":"array","items":{"$ref":"#/$defs/repository"}}
      },"additionalProperties":false
    }
  }
}`)

var attachmentResponseSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["kind","name","path","repositories"],
  "properties":{
    "kind":{"const":"terminal"},"name":{"type":"string","minLength":1},
    "path":{"type":"string","minLength":1},
    "repositories":{"type":"array","items":{"$ref":"#/$defs/repository"}}
  },
  "additionalProperties":false,
  "$defs":{"repository":{
    "type":"object","required":["name","path"],
    "properties":{"name":{"type":"string","minLength":1},"path":{"type":"string","minLength":1},"branch":{"type":"string"}},
    "additionalProperties":false
  }}
}`)

var closeResponseSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["closed"],
  "properties":{"closed":{"type":"boolean"}},"additionalProperties":false
}`)

func Manifests() ([]plugin.AdapterManifest, error) {
	create, err := plugin.NewSchemaContract(createRequestSchema, workspaceResponseSchema, false, false)
	if err != nil {
		return nil, err
	}
	add, err := plugin.NewSchemaContract(repositoryRequestSchema, workspaceResponseSchema, false, false)
	if err != nil {
		return nil, err
	}
	remove, err := plugin.NewSchemaContract(repositoryRequestSchema, workspaceResponseSchema, false, false)
	if err != nil {
		return nil, err
	}
	snapshot, err := plugin.NewSchemaContract(workspaceRequestSchema, workspaceResponseSchema, true, true)
	if err != nil {
		return nil, err
	}
	open, err := plugin.NewSchemaContract(workspaceRequestSchema, attachmentResponseSchema, true, true)
	if err != nil {
		return nil, err
	}
	closeContract, err := plugin.NewSchemaContract(closeRequestSchema, closeResponseSchema, true, true)
	if err != nil {
		return nil, err
	}
	return []plugin.AdapterManifest{
		{
			ID: WorkspaceAdapterID, Port: domain.AdapterPortWorkspace,
			Capabilities:   []string{"workspace.multi-repository", "workspace.worktree"},
			HandleVersions: []uint32{1},
			Operations: map[string]plugin.SchemaContract{
				OperationCreate: create, OperationAdd: add, OperationRemove: remove, OperationSnapshot: snapshot,
			},
		},
		{
			ID: AttachmentAdapterID, Port: domain.AdapterPortAttachment,
			Capabilities: []string{"attachment.terminal"}, HandleVersions: []uint32{1},
			Operations: map[string]plugin.SchemaContract{OperationOpen: open, OperationClose: closeContract},
		},
	}, nil
}
