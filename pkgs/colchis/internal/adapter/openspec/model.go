package openspec

import (
	"encoding/json"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
)

const (
	FrameworkID       = "openspec"
	OperationDiscover = "planning.discover"
	OperationSnapshot = "planning.snapshot"
	OperationAction   = "planning.action"
)

type DiscoverRequest struct{}

type SnapshotRequest struct {
	Change string `json:"change"`
}

type ActionRequest struct {
	Change string `json:"change"`
	Action string `json:"action"`
}

type Schema struct {
	ID                string          `json:"id"`
	Description       string          `json:"description,omitempty"`
	Source            string          `json:"source,omitempty"`
	DeclaredArtifacts []string        `json:"declaredArtifacts"`
	TemplateArtifacts []string        `json:"templateArtifacts"`
	Location          string          `json:"location,omitempty"`
	SourceDigest      string          `json:"sourceDigest"`
	OpaqueSourceData  json.RawMessage `json:"opaqueSourceData"`
}

type DiscoverResult struct {
	Framework        string          `json:"framework"`
	Schemas          []Schema        `json:"schemas"`
	SourceDigest     string          `json:"sourceDigest"`
	OpaqueSourceData json.RawMessage `json:"opaqueSourceData"`
}

type Artifact struct {
	ID                  string   `json:"id"`
	Status              string   `json:"status"`
	OutputPath          string   `json:"outputPath,omitempty"`
	ResolvedOutputPath  string   `json:"resolvedOutputPath,omitempty"`
	ExistingOutputPaths []string `json:"existingOutputPaths"`
	Requires            []string `json:"requires"`
}

type Action struct {
	ID          string   `json:"id"`
	Kind        string   `json:"kind"`
	Available   bool     `json:"available"`
	Requires    []string `json:"requires"`
	Description string   `json:"description,omitempty"`
}

type ContextReference struct {
	ArtifactID string   `json:"artifactId"`
	Paths      []string `json:"paths"`
}

type WorkItem struct {
	ID          string          `json:"id"`
	Description string          `json:"description"`
	Done        bool            `json:"done"`
	OpaqueData  json.RawMessage `json:"opaqueData"`
}

type Gate struct {
	ID        string `json:"id"`
	Kind      string `json:"kind"`
	Satisfied bool   `json:"satisfied"`
	Detail    string `json:"detail,omitempty"`
}

type Snapshot struct {
	Framework        string             `json:"framework"`
	Change           string             `json:"change"`
	SchemaID         string             `json:"schemaId"`
	SourceDigest     string             `json:"sourceDigest"`
	Artifacts        []Artifact         `json:"artifacts"`
	Actions          []Action           `json:"actions"`
	Context          []ContextReference `json:"context"`
	WorkItems        []WorkItem         `json:"workItems"`
	Gates            []Gate             `json:"gates"`
	OpaqueSourceData json.RawMessage    `json:"opaqueSourceData"`
}

type ActionResult struct {
	Framework          string             `json:"framework"`
	Change             string             `json:"change"`
	SchemaID           string             `json:"schemaId"`
	Action             string             `json:"action"`
	Description        string             `json:"description,omitempty"`
	Instruction        string             `json:"instruction,omitempty"`
	OutputPath         string             `json:"outputPath,omitempty"`
	ResolvedOutputPath string             `json:"resolvedOutputPath,omitempty"`
	Dependencies       []string           `json:"dependencies"`
	Unlocks            []string           `json:"unlocks"`
	Context            []ContextReference `json:"context"`
	WorkItems          []WorkItem         `json:"workItems"`
	SourceDigest       string             `json:"sourceDigest"`
	OpaqueSourceData   json.RawMessage    `json:"opaqueSourceData"`
}

var discoverRequestSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object",
  "additionalProperties":false
}`)

var snapshotRequestSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object",
  "required":["change"],
  "properties":{"change":{"type":"string","minLength":1,"maxLength":128}},
  "additionalProperties":false
}`)

var actionRequestSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object",
  "required":["change","action"],
  "properties":{
    "change":{"type":"string","minLength":1,"maxLength":128},
    "action":{"type":"string","minLength":1,"maxLength":128}
  },
  "additionalProperties":false
}`)

var discoverResponseSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object",
  "required":["framework","schemas","sourceDigest","opaqueSourceData"],
  "properties":{
    "framework":{"const":"openspec"},
    "schemas":{"type":"array","items":{"$ref":"#/$defs/schema"}},
    "sourceDigest":{"$ref":"#/$defs/digest"},
    "opaqueSourceData":{"type":"object"}
  },
  "additionalProperties":false,
  "$defs":{
    "digest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"},
    "strings":{"type":"array","items":{"type":"string","minLength":1},"uniqueItems":true},
    "schema":{
      "type":"object",
      "required":["id","declaredArtifacts","templateArtifacts","sourceDigest","opaqueSourceData"],
      "properties":{
        "id":{"type":"string","minLength":1,"maxLength":128},
        "description":{"type":"string"},
        "source":{"type":"string"},
        "declaredArtifacts":{"$ref":"#/$defs/strings"},
        "templateArtifacts":{"$ref":"#/$defs/strings"},
        "location":{"type":"string"},
        "sourceDigest":{"$ref":"#/$defs/digest"},
        "opaqueSourceData":{"type":"object"}
      },
      "additionalProperties":false
    }
  }
}`)

var snapshotResponseSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object",
  "required":["framework","change","schemaId","sourceDigest","artifacts","actions","context","workItems","gates","opaqueSourceData"],
  "properties":{
    "framework":{"const":"openspec"},
    "change":{"$ref":"#/$defs/id"},
    "schemaId":{"$ref":"#/$defs/id"},
    "sourceDigest":{"$ref":"#/$defs/digest"},
    "artifacts":{"type":"array","items":{"$ref":"#/$defs/artifact"}},
    "actions":{"type":"array","items":{"$ref":"#/$defs/action"}},
    "context":{"type":"array","items":{"$ref":"#/$defs/context"}},
    "workItems":{"type":"array","items":{"$ref":"#/$defs/workItem"}},
    "gates":{"type":"array","items":{"$ref":"#/$defs/gate"}},
    "opaqueSourceData":{"type":"object"}
  },
  "additionalProperties":false,
  "$defs":{
    "id":{"type":"string","minLength":1,"maxLength":128},
    "digest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"},
    "strings":{"type":"array","items":{"type":"string"},"uniqueItems":true},
    "artifact":{
      "type":"object","required":["id","status","existingOutputPaths","requires"],
      "properties":{
        "id":{"$ref":"#/$defs/id"},"status":{"type":"string","minLength":1},
        "outputPath":{"type":"string"},"resolvedOutputPath":{"type":"string"},
        "existingOutputPaths":{"$ref":"#/$defs/strings"},"requires":{"$ref":"#/$defs/strings"}
      },"additionalProperties":false
    },
    "action":{
      "type":"object","required":["id","kind","available","requires"],
      "properties":{
        "id":{"$ref":"#/$defs/id"},"kind":{"type":"string","minLength":1},
        "available":{"type":"boolean"},"requires":{"$ref":"#/$defs/strings"},
        "description":{"type":"string"}
      },"additionalProperties":false
    },
    "context":{
      "type":"object","required":["artifactId","paths"],
      "properties":{"artifactId":{"$ref":"#/$defs/id"},"paths":{"$ref":"#/$defs/strings"}},
      "additionalProperties":false
    },
    "workItem":{
      "type":"object","required":["id","description","done","opaqueData"],
      "properties":{
        "id":{"$ref":"#/$defs/id"},"description":{"type":"string","minLength":1},
        "done":{"type":"boolean"},"opaqueData":{"type":"object"}
      },"additionalProperties":false
    },
    "gate":{
      "type":"object","required":["id","kind","satisfied"],
      "properties":{
        "id":{"$ref":"#/$defs/id"},"kind":{"type":"string","minLength":1},
        "satisfied":{"type":"boolean"},"detail":{"type":"string"}
      },"additionalProperties":false
    }
  }
}`)

var actionResponseSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object",
  "required":["framework","change","schemaId","action","dependencies","unlocks","context","workItems","sourceDigest","opaqueSourceData"],
  "properties":{
    "framework":{"const":"openspec"},
    "change":{"$ref":"#/$defs/id"},
    "schemaId":{"$ref":"#/$defs/id"},
    "action":{"$ref":"#/$defs/id"},
    "description":{"type":"string"},
    "instruction":{"type":"string"},
    "outputPath":{"type":"string"},
    "resolvedOutputPath":{"type":"string"},
    "dependencies":{"$ref":"#/$defs/strings"},
    "unlocks":{"$ref":"#/$defs/strings"},
    "context":{"type":"array","items":{"$ref":"#/$defs/context"}},
    "workItems":{"type":"array","items":{"$ref":"#/$defs/workItem"}},
    "sourceDigest":{"$ref":"#/$defs/digest"},
    "opaqueSourceData":{"type":"object"}
  },
  "additionalProperties":false,
  "$defs":{
    "id":{"type":"string","minLength":1,"maxLength":128},
    "digest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"},
    "strings":{"type":"array","items":{"type":"string"},"uniqueItems":true},
    "context":{
      "type":"object","required":["artifactId","paths"],
      "properties":{"artifactId":{"$ref":"#/$defs/id"},"paths":{"$ref":"#/$defs/strings"}},
      "additionalProperties":false
    },
    "workItem":{
      "type":"object","required":["id","description","done","opaqueData"],
      "properties":{
        "id":{"$ref":"#/$defs/id"},"description":{"type":"string","minLength":1},
        "done":{"type":"boolean"},"opaqueData":{"type":"object"}
      },"additionalProperties":false
    }
  }
}`)

func Manifest() (plugin.AdapterManifest, error) {
	discover, err := plugin.NewSchemaContract(discoverRequestSchema, discoverResponseSchema, true, true)
	if err != nil {
		return plugin.AdapterManifest{}, err
	}
	snapshot, err := plugin.NewSchemaContract(snapshotRequestSchema, snapshotResponseSchema, true, true)
	if err != nil {
		return plugin.AdapterManifest{}, err
	}
	action, err := plugin.NewSchemaContract(actionRequestSchema, actionResponseSchema, true, true)
	if err != nil {
		return plugin.AdapterManifest{}, err
	}
	return plugin.AdapterManifest{
		ID: FrameworkID, Port: domain.AdapterPortPlanning,
		Capabilities: []string{"planning.framework.openspec"}, HandleVersions: []uint32{1},
		Operations: map[string]plugin.SchemaContract{
			OperationDiscover: discover,
			OperationSnapshot: snapshot,
			OperationAction:   action,
		},
	}, nil
}
