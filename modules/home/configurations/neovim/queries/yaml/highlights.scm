;; Crossplane Composition specific highlighting
;; Highlight Crossplane-specific keys in block mapping pairs
(block_mapping_pair
  key: (flow_node (plain_scalar) @keyword)
  (#match? @keyword "^(apiVersion|kind|metadata|spec|name|namespace|resourceTemplates|resources|patches|transforms|connectionDetails|environment|readinessChecks|writeConnectionSecretsToNamespace|compositeTypeRef|compositionRef|base|patch|type|fromFieldPath|toFieldPath|policy|combine|string|convert|math|map|mode|pipeline|step|functionRef|input|source|inline|template)$"))

;; Highlight Crossplane function names
(block_mapping_pair
  key: (flow_node (plain_scalar) @keyword (#eq? @keyword "name"))
  value: (flow_node (plain_scalar) @function (#match? @function "^function-")))

;; Highlight GoTemplate kind specifically
(block_mapping_pair
  key: (flow_node (plain_scalar) @keyword (#eq? @keyword "kind"))
  value: (flow_node (plain_scalar) @type.builtin (#eq? @type.builtin "GoTemplate")))

;; General YAML highlighting
(string_scalar) @string
(double_quote_scalar) @string
(single_quote_scalar) @string
(plain_scalar) @string
(integer_scalar) @number
(float_scalar) @number.float
(boolean_scalar) @boolean
(null_scalar) @constant.builtin
(alias) @string.escape
(anchor) @label
(tag) @type
(comment) @comment

;; Highlight Go template expressions ONLY in block_scalars for Crossplane compositions
;; This prevents over-highlighting and avoids conflicts with normal YAML
(block_scalar) @go_template
  (#contains? @go_template "{{")

