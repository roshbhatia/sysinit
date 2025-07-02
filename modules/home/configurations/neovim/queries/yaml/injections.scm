;; Injections for YAML and Crossplane compositions

;; Inject embedded JSONPath templates (used in Crossplane compositions)
(mapping_value (string_scalar)) @jsonpath

;; Inject Go templates (optional, depends on Crossplane usage)
(mapping_value (double_quote_scalar "{{")) @gotemplate

;; Embed schemas within YAML structure
;; Automatically detect inline raw schema definitions
(mapping_key "schema") @yaml.embedded

