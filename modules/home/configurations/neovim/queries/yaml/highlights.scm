;; Crossplane Composition specific highlighting
;; Highlight Crossplane-specific keys in block mapping pairs
(block_mapping_pair
  key: (flow_node (plain_scalar) @keyword)
  (#match? @keyword "^(apiVersion|kind|metadata|spec|name|namespace|resourceTemplates|resources|patches|transforms|connectionDetails|environment|readinessChecks|writeConnectionSecretsToNamespace|compositeTypeRef|compositionRef|base|patch|type|fromFieldPath|toFieldPath|policy|combine|string|convert|math|map)$"))

;; Highlight Go template expressions in strings
(string_scalar) @string
  (#contains? @string "{{")

(double_quote_scalar) @string
  (#contains? @string "{{")

(single_quote_scalar) @string
  (#contains? @string "{{")

;; Highlight multiline strings that likely contain Go templates
(block_scalar) @string.special
  (#contains? @string.special "{{")

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

