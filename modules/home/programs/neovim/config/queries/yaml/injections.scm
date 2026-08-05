; Inject Go template for template: | blocks in Crossplane compositions
; This handles both direct template: blocks and nested inline.template: blocks
; Examples:
;   template: |
;     {{ $var := "value" }}
;     apiVersion: v1
;     kind: Object
;
;   inline:
;     template: |
;       {{ $var := "value" }}
(block_mapping_pair
  key: (flow_node) @_key
  (#eq? @_key "template")
  value: (block_node
    (block_scalar) @injection.content
    (#set! injection.language "gotmpl")
    (#set! injection.include-children)
  )
)

; Inject JSON or gotmpl for assumeRolePolicy: | blocks (AWS IAM policies)
; If Go template delimiters are present, use gotmpl to retain template highlighting.
; Otherwise default to json.
(block_mapping_pair
  key: (flow_node) @_assume_key
  (#eq? @_assume_key "assumeRolePolicy")
  value: (block_node
    (block_scalar) @injection.content
    (#match? @injection.content "{{")
    (#set! injection.language "gotmpl")
    (#set! injection.include-children)
  )
)
(block_mapping_pair
  key: (flow_node) @_assume_key
  (#eq? @_assume_key "assumeRolePolicy")
  value: (block_node
    (block_scalar) @injection.content
    (#not-match? @injection.content "{{")
    (#set! injection.language "json")
    (#set! injection.include-children)
  )
)

; Inject JSON or gotmpl for policy: | blocks (AWS IAM policies)
(block_mapping_pair
  key: (flow_node) @_policy_key
  (#eq? @_policy_key "policy")
  value: (block_node
    (block_scalar) @injection.content
    (#match? @injection.content "{{")
    (#set! injection.language "gotmpl")
    (#set! injection.include-children)
  )
)
(block_mapping_pair
  key: (flow_node) @_policy_key
  (#eq? @_policy_key "policy")
  value: (block_node
    (block_scalar) @injection.content
    (#not-match? @injection.content "{{")
    (#set! injection.language "json")
    (#set! injection.include-children)
  )
)

; Support language hints via comments (e.g., # language: gotmpl or # language: yaml)
(block_scalar
  (comment) @injection.language
  @injection.content
  (#offset! @injection.language 0 2 0 0)
  (#offset! @injection.content 1 0 0 0)
  (#set! injection.include-children)
)

; Default: treat block scalars as YAML
(block_scalar) @injection.content
  (#set! injection.language "yaml")
  (#set! injection.include-children)
