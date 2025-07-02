;; Injections for YAML Go templates under `template`

;; Inject Go templates specifically under `template`
(block_scalar (key_scalar "template")) @gotemplate.embedded

;; Handle fallback YAML multiline cases with embedded content
(block_scalar) @yaml.embedded

;; General embedded JSONPath (example fallback for multiline)
(string_scalar "{{") @template.expression

