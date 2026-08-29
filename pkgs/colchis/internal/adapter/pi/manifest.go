package pi

import (
	"encoding/json"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
)

var startRequestSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["sessionId"],"properties":{
    "sessionId":{"$ref":"#/$defs/id"},"provider":{"$ref":"#/$defs/id"},
    "model":{"type":"string","minLength":1},"name":{"type":"string","minLength":1},
    "approveProject":{"type":"boolean"}
  },"additionalProperties":false,"$defs":{"id":{"type":"string","minLength":1,"maxLength":128}}
}`)

var inputRequestSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["message","behavior"],"properties":{
    "message":{"type":"string","minLength":1},
    "behavior":{"enum":["prompt","steer","follow_up"]}
  },"additionalProperties":false
}`)

var emptyRequestSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","additionalProperties":false
}`)

var reconcileRequestSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","properties":{
    "cursor":{"type":"integer","minimum":0},
    "maxEvents":{"type":"integer","minimum":1,"maximum":500}
  },"additionalProperties":false
}`)

var attachmentOpenRequestSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["sessionId"],"properties":{
    "sessionId":{"type":"string","minLength":1,"maxLength":128},
    "cursor":{"type":"integer","minimum":0}
  },"additionalProperties":false
}`)

var attachmentCloseRequestSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["attachmentId","sessionId"],"properties":{
    "attachmentId":{"type":"string","minLength":1},
    "sessionId":{"type":"string","minLength":1,"maxLength":128}
  },"additionalProperties":false
}`)

var sessionResponseSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["state","capabilities"],"properties":{
    "state":{"enum":["idle","running","interrupting","cancelled","completed","failed"]},
    "capabilities":{"$ref":"#/$defs/capabilities"}
  },"additionalProperties":false,"$defs":{
    "capabilities":{"type":"object","required":["liveInput","queuedInput","interrupt","resume","nativeAttachment"],
      "properties":{"liveInput":{"const":true},"queuedInput":{"const":true},"interrupt":{"const":true},
        "resume":{"const":true},"nativeAttachment":{"const":true}},"additionalProperties":false}
  }
}`)

var inputResponseSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["accepted","queued","state"],"properties":{
    "accepted":{"type":"boolean"},"queued":{"type":"boolean"},
    "state":{"enum":["idle","running","interrupting","cancelled","completed","failed"]}
  },"additionalProperties":false
}`)

var interruptResponseSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["interrupted","state"],"properties":{
    "interrupted":{"type":"boolean"},
    "state":{"enum":["idle","running","interrupting","cancelled","completed","failed"]}
  },"additionalProperties":false
}`)

var reconcileResponseSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["state","cursor","firstAvailableCursor","events","more"],"properties":{
    "state":{"enum":["idle","running","interrupting","cancelled","completed","failed"]},
    "cursor":{"type":"integer","minimum":0},"firstAvailableCursor":{"type":"integer","minimum":0},
    "events":{"type":"array","items":{"$ref":"#/$defs/event"}},"more":{"type":"boolean"}
  },"additionalProperties":false,"$defs":{
    "event":{"type":"object","required":["sequence","kind","providerEventType","occurredAt","data"],
      "properties":{"sequence":{"type":"integer","minimum":1},
        "kind":{"enum":["session","turn","model_call","tool_call"]},
        "providerEventType":{"type":"string","minLength":1},"providerId":{"type":"string","minLength":1},
        "parentProviderId":{"type":"string","minLength":1},"occurredAt":{"type":"string","format":"date-time"},
        "data":{"type":"object"}},"additionalProperties":false}
  }
}`)

var attachmentResponseSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["attachmentId","transport","readOnly","cursor","capabilities"],"properties":{
    "attachmentId":{"type":"string","minLength":1},"transport":{"const":"native-event-stream"},
    "readOnly":{"const":false},"cursor":{"type":"integer","minimum":0},
    "capabilities":{"type":"array","items":{"enum":["live-input","queued-input","interrupt","resume"]},"uniqueItems":true}
  },"additionalProperties":false
}`)

var closeResponseSchema = json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["closed"],"properties":{"closed":{"type":"boolean"}},"additionalProperties":false
}`)

func Manifests() ([]plugin.AdapterManifest, error) {
	start, err := plugin.NewSchemaContract(startRequestSchema, sessionResponseSchema, false, false)
	if err != nil {
		return nil, err
	}
	input, err := plugin.NewSchemaContract(inputRequestSchema, inputResponseSchema, false, false)
	if err != nil {
		return nil, err
	}
	interrupt, err := plugin.NewSchemaContract(emptyRequestSchema, interruptResponseSchema, false, false)
	if err != nil {
		return nil, err
	}
	resume, err := plugin.NewSchemaContract(emptyRequestSchema, sessionResponseSchema, false, false)
	if err != nil {
		return nil, err
	}
	reconcile, err := plugin.NewSchemaContract(reconcileRequestSchema, reconcileResponseSchema, true, true)
	if err != nil {
		return nil, err
	}
	open, err := plugin.NewSchemaContract(attachmentOpenRequestSchema, attachmentResponseSchema, true, true)
	if err != nil {
		return nil, err
	}
	closeContract, err := plugin.NewSchemaContract(attachmentCloseRequestSchema, closeResponseSchema, true, true)
	if err != nil {
		return nil, err
	}
	return []plugin.AdapterManifest{
		{
			ID: RuntimeAdapterID, Port: domain.AdapterPortAgentRuntime,
			Capabilities: []string{
				"structured-result", "job-policy", "live-input", "queued-input", "interrupt", "resume", "rpc", "normalized-events",
				"native-attachment",
			},
			HandleVersions: []uint32{1, 2},
			Operations: map[string]plugin.SchemaContract{
				OperationStart: start, OperationInput: input, OperationInterrupt: interrupt,
				OperationResume: resume, OperationReconcile: reconcile,
			},
		},
		{
			ID: AttachmentAdapterID, Port: domain.AdapterPortAttachment,
			Capabilities:   []string{"attachment.native-event-stream", "attachment.live-input"},
			HandleVersions: []uint32{1},
			Operations: map[string]plugin.SchemaContract{
				OperationAttachmentOpen: open, OperationAttachmentClose: closeContract,
			},
		},
	}, nil
}
