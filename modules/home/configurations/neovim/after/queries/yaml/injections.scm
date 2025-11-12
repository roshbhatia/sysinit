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
