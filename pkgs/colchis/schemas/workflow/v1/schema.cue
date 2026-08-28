package workflow

import "list"

#Identifier: string & =~"^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$"
#Digest:     string & =~"^sha256:[a-f0-9]{64}$"

#Budgets: close({
	maxConcurrentNodes:       uint & >0 & <=4096
	maxConcurrentProcesses:   uint & >0 & <=4096
	maxMaterializedSnapshots: uint & >0 & <=4096
	maxSnapshotBytes:         uint & >0
	maxVerificationSeconds:   uint & >0
})

#JSONSchema: {
	"$schema": "https://json-schema.org/draft/2020-12/schema"
	...
}

#Capabilities: close({
	required: *([]) | [...#Identifier]
	optional: *([]) | [...#Identifier]
	_uniqueRequired: list.UniqueItems(required)
	_uniqueOptional: list.UniqueItems(optional)
	_uniqueCapabilities: list.UniqueItems(list.Concat([required, optional]))
})

#Verification: close({
	key:         #Identifier
	required:    bool
	environment: #Identifier
	command: [#Identifier, ...string]
	timeoutSeconds: uint & >0
})

#EffectOperation: close({
	kind:               #Identifier
	targetSchemaDigest: #Digest
	reconciliation:     "observe" | "owner"
	idempotent:         bool
})

#EffectPolicy: *close({
	mode: "deny"
}) | close({
	mode:                   "allow"
	requiresOwnerAuthority: true
	operations: [#EffectOperation, ...#EffectOperation]
})

#JobPolicy: close({
	approvals:  "always" | "on-request" | "never"
	filesystem: "read-only" | "workspace-write" | "danger-full-access"
	network:    "deny" | "allow"
})

#StageTemplate: close({
	kind:               "task" | "judge" | "verification" | "effect"
	inputSchema:        #JSONSchema
	inputSchemaDigest:  #Digest
	outputSchema:       #JSONSchema
	outputSchemaDigest: #Digest
	capabilities:       #Capabilities
	writeScopes:       *(["."]) | [string & !="", ...(string & !="")]
	verification: *([]) | [...#Verification]
	effects:           #EffectPolicy
	maxAttempts:       *(1) | uint & >0 & <=100
	maxRepairAttempts: *(2) | uint & <=10
	_uniqueVerifications: list.UniqueItems([for check in verification {check.key}])
})

#Node: close({
	template: #Identifier
	adapter:  #Identifier
	policy:   #JobPolicy
	budget: *({maxAttempts: 1}) | close({
		maxAttempts: *(1) | uint & >0 & <=100
	})
})

#Edge: close({
	id:                #Identifier
	from:              #Identifier
	fromPort:          #Identifier
	to:                #Identifier
	toPort:            #Identifier
	valueSchemaDigest: #Digest
	required:          *(true) | bool
})

#StopCondition: close({
	kind:       "validation"
	validation: #Identifier
}) | close({
	kind: "result_match"
	node: #Identifier
	path: [#Identifier, ...#Identifier]
	equals: bool | number | string | null
})

#Loop: close({
	id:             #Identifier
	backEdge:       #Identifier
	stop:           #StopCondition
	iterationLimit: uint & >0 & <=1000
	stallLimit:     uint & >0 & <=1000
})

#Workflow: close({
	schemaVersion:    "colchis.workflow/v2"
	evaluatorVersion: "cue-0.17.1+colchis-policy-v2"
	name:             #Identifier
	budgets:          #Budgets
	effects:          #EffectPolicy
	jobDefaults: *(#JobPolicy & {
		approvals:  "on-request"
		filesystem: "workspace-write"
		network:    "deny"
	}) | #JobPolicy
	templates: [#Identifier]: #StageTemplate
	nodes: [#Identifier]: #Node & {
		policy: *(jobDefaults) | #JobPolicy
	}
	edges: [...#Edge]
	loops: *([]) | [...#Loop]
	_hasNodes: len(nodes) > 0
	_uniqueEdges: list.UniqueItems([for edge in edges {edge.id}])
	_uniqueLoops: list.UniqueItems([for loop in loops {loop.id}])
	_nodeTemplates: {
		for key, node in nodes {
			"\(key)": {
				template:    templates[node.template]
				maxAttempts: templates[node.template].maxAttempts & >=node.budget.maxAttempts
			}
		}
	}
	_edgeChecks: {
		for edge in edges {
			"\(edge.id)": {
				from:         nodes[edge.from]
				to:           nodes[edge.to]
				outputDigest: templates[nodes[edge.from].template].outputSchemaDigest & edge.valueSchemaDigest
				inputDigest:  templates[nodes[edge.to].template].inputSchemaDigest & edge.valueSchemaDigest
			}
		}
	}
	_edgeIndex: {
		for edge in edges {
			"\(edge.id)": edge
		}
	}
	_loopChecks: {
		for loop in loops {
			"\(loop.id)": {
				backEdge: _edgeIndex[loop.backEdge]
			}
		}
	}
})
