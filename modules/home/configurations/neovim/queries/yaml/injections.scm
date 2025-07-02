; Inject Go template parser into YAML block, plain, and quoted scalars containing Go templates
(block_scalar) @gotmpl
  (#match? @gotmpl "{{.*?}}")
  (#set! injection.language "gotmpl")
  (#set! injection.combined)

(plain_scalar) @gotmpl
  (#match? @gotmpl "{{.*?}}")
  (#set! injection.language "gotmpl")
  (#set! injection.combined)

(double_quote_scalar) @gotmpl
  (#match? @gotmpl "{{.*?}}")
  (#set! injection.language "gotmpl")
  (#set! injection.combined)

(single_quote_scalar) @gotmpl
  (#match? @gotmpl "{{.*?}}")
  (#set! injection.language "gotmpl")
  (#set! injection.combined)
