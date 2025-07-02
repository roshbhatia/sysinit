; Highlight Go template delimiters in YAML for kustomize, helm, crossplane, etc.

; Block scalars (multiline strings)
(block_scalar) @go_template
  (#any-of? @go_template "{{" "{{-" "{{ ." "{{- .")
  (#match? @go_template "{{.*?}}")

; Plain scalars
(plain_scalar) @go_template
  (#any-of? @go_template "{{" "{{-" "{{ ." "{{- .")
  (#match? @go_template "{{.*?}}")

; Double-quoted scalars
(double_quote_scalar) @go_template
  (#any-of? @go_template "{{" "{{-" "{{ ." "{{- .")
  (#match? @go_template "{{.*?}}")

; Single-quoted scalars
(single_quote_scalar) @go_template
  (#any-of? @go_template "{{" "{{-" "{{ ." "{{- .")
  (#match? @go_template "{{.*?}}")

