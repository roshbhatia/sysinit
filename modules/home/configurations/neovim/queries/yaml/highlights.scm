;; Crossplane Composition specific highlighting
;; Highlight Crossplane-specific keys
(key_scalar) @keyword
  (#match? @keyword "^(apiVersion|kind|metadata|spec|name|namespace|resourceTemplates|resources|patches|transforms|connectionDetails|environment|readinessChecks|writeConnectionSecretsToNamespace|compositeTypeRef|compositionRef|base|patch|type|fromFieldPath|toFieldPath|policy|combine|string|convert|math|map)$")

;; Highlight Go template delimiters and expressions in strings
(string_scalar) @string
  (#contains? @string "{{")
(string_scalar) @string
  (#contains? @string "}}")

;; Highlight multiline strings that likely contain Go templates
(block_scalar) @string.special
  (#contains? @string.special "{{")

;; General YAML highlighting
(string_scalar) @string
(integer_scalar) @number
(float_scalar) @number.float
(boolean_scalar) @boolean
(null_scalar) @constant.builtin
(alias_scalar) @string.escape
(anchor_scalar) @label
(tag_scalar) @type
(comment) @comment

