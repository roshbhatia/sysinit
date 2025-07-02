; Highlight Go template delimiters in various YAML contexts for kustomize, helm, and crossplane

; Go templates in block scalars (multiline strings)
; Go templates in block scalars (multiline strings)
(block_scalar) @go_template
  (#match? @go_template "{{[^{]*}}")

; Injection: highlight embedded Go templates in block_scalars for crossplane compositions
; Only effective if filetype is set to yaml.crossplane or similar
; NOTE: This requires an appropriate treesitter parser (gotmpl) and correct filetype switching
(block_scalar) @inject_gotmpl

; Go templates in plain scalars
(plain_scalar) @go_template
  (#match? @go_template "{{[^{]*}}")

; Go templates in double-quoted scalars
(double_quote_scalar) @go_template
  (#match? @go_template "{{[^{]*}}")

; Go templates in single-quoted scalars
(single_quote_scalar) @go_template
  (#match? @go_template "{{[^{]*}}")

