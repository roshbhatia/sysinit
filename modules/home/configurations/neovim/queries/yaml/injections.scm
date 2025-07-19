; Language injections for Go template syntax in YAML strings
; Supports Crossplane, Kustomize, and Helm files with Go templating

; Inject Go template syntax into string values containing template expressions
((plain_scalar) @injection.content
 (#match? @injection.content "{{.*}}")
 (#set! injection.language "gotmpl")
 (#set! injection.include-children))

((double_quote_scalar) @injection.content  
 (#match? @injection.content ".*{{.*}}.*")
 (#set! injection.language "gotmpl")
 (#set! injection.include-children))

((single_quote_scalar) @injection.content
 (#match? @injection.content ".*{{.*}}.*") 
 (#set! injection.language "gotmpl")
 (#set! injection.include-children))

; Inject Go template syntax into block scalars (multi-line strings)
((block_scalar) @injection.content
 (#match? @injection.content ".*{{.*}}.*")
 (#set! injection.language "gotmpl")
 (#set! injection.include-children))

; Special injection for inline templates in Crossplane compositions
((block_mapping_pair
  key: (flow_node (plain_scalar) @_key)
  value: (block_node 
    (block_mapping
      (block_mapping_pair
        key: (flow_node (plain_scalar) @_template_key)
        value: (flow_node 
          (block_scalar) @injection.content))))
 (#eq? @_key "inline")
 (#eq? @_template_key "template")
 (#set! injection.language "gotmpl")
 (#set! injection.include-children))

; Injection for template field values in functionRef configurations
((block_mapping_pair
  key: (flow_node (plain_scalar) @_key)
  value: (flow_node 
    (block_scalar) @injection.content))
 (#eq? @_key "template")
 (#set! injection.language "gotmpl") 
 (#set! injection.include-children))

; Kustomize patches with Go templates
((block_mapping_pair
  key: (flow_node (plain_scalar) @_key)
  value: (flow_node 
    (block_scalar) @injection.content))
 (#any-of? @_key "patch" "target")
 (#match? @injection.content ".*{{.*}}.*")
 (#set! injection.language "gotmpl")
 (#set! injection.include-children))

; Helm values.yaml files - inject into any string containing templates
((block_mapping_pair
  value: (flow_node 
    (plain_scalar) @injection.content))
 (#match? @injection.content ".*{{.*}}.*")
 (#set! injection.language "gotmpl")
 (#set! injection.include-children))

; Helm template files ending in .yaml or .yml in templates directory
((document
  (block_node
    (block_mapping) @injection.content))
 (#match? @injection.content ".*{{.*}}.*")
 (#set! injection.language "gotmpl")
 (#set! injection.include-children))