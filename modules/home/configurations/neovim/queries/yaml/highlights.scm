; Custom highlights for Go templating in YAML files
; Supports Crossplane compositions, Kustomize files, and Helm values with Go templates

; Go template expressions in plain scalars
((plain_scalar) @go_template.expression
 (#match? @go_template.expression "{{.*}}"))

; Template expressions in quoted scalars  
((double_quote_scalar) @go_template.expression
 (#match? @go_template.expression ".*{{.*}}.*"))

((single_quote_scalar) @go_template.expression
 (#match? @go_template.expression ".*{{.*}}.*"))

; Block scalar with go templates
((block_scalar) @go_template.block
 (#match? @go_template.block ".*{{.*}}.*"))

; Crossplane function annotations
((block_mapping_pair
  key: (flow_node (plain_scalar) @annotation.key)
  value: (flow_node (plain_scalar) @annotation.value))
 (#match? @annotation.key "crossplane\\.io/.*"))

; Crossplane composition metadata
((block_mapping_pair
  key: (flow_node (plain_scalar) @composition.key)
  value: (flow_node))
 (#any-of? @composition.key "apiVersion" "kind" "metadata" "spec"))

; Kustomize-specific fields
((block_mapping_pair
  key: (flow_node (plain_scalar) @kustomize.key)
  value: (flow_node))
 (#any-of? @kustomize.key "resources" "patches" "patchesStrategicMerge" "patchesJson6902" "generators" "transformers" "namespace" "namePrefix" "nameSuffix"))

; Helm template function calls
((plain_scalar) @helm.function
 (#match? @helm.function ".*(include|template|toYaml|toJson|quote|squote|indent|nindent|upper|lower|title|untitle|repeat)\\s*\".*"))

; Template function calls like setResourceNameAnnotation
((plain_scalar) @function.call
 (#match? @function.call ".*setResourceNameAnnotation.*"))

; Template variables and pipelines
((plain_scalar) @template.variable
 (#match? @template.variable ".*\\$[a-zA-Z_][a-zA-Z0-9_]*.*"))

; Template control structures
((plain_scalar) @template.control
 (#match? @template.control ".*(if|else|end|range|with|template|define|block)\\s.*"))

; Crossplane resource names and kinds  
((block_mapping_pair
  key: (flow_node (plain_scalar) @resource.key)
  value: (flow_node (plain_scalar) @resource.value))
 (#eq? @resource.key "kind")
 (#match? @resource.value ".*XR|.*Composition|.*Function.*"))

; API versions for Crossplane
((block_mapping_pair
  key: (flow_node (plain_scalar) @api.key)  
  value: (flow_node (plain_scalar) @api.value))
 (#eq? @api.key "apiVersion")
 (#match? @api.value ".*crossplane\\.io.*|.*fn\\.crossplane\\.io.*"))

; Helm Chart.yaml fields
((block_mapping_pair
  key: (flow_node (plain_scalar) @chart.key)
  value: (flow_node))
 (#any-of? @chart.key "name" "version" "appVersion" "description" "keywords" "home" "sources" "maintainers" "dependencies"))

; Kustomization file detection
((block_mapping_pair
  key: (flow_node (plain_scalar) @kustomization.key)
  value: (flow_node (plain_scalar) @kustomization.value))
 (#eq? @kustomization.key "apiVersion")
 (#match? @kustomization.value "kustomize\\.config\\.k8s\\.io.*"))