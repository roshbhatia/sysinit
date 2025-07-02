;; Injections for YAML Go templates under `inline`

;; Inject Go templates specifically under `inline`
(block_scalar (key_scalar "inline")) @gotemplate.embedded
(block_scalar (key_scalar "template")) @gotemplate.embedded

;; Handle fallback YAML multiline cases with embedded content
(block_scalar) @yaml.embedded

;; YAML compatibility fix: Remove problematic node types

;; General embedded JSONPath (example fallback for multiline)
(string_scalar "{{") @template.expression

