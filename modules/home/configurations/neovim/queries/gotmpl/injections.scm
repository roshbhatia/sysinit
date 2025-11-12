; Treesitter injections for gotmpl (Go templates containing YAML / JSON)
; Objective: Re-inject YAML or JSON inside raw text regions of templates so that
; YAML structure and embedded JSON objects still highlight properly when the filetype
; is gotmpl (e.g. *.yaml.tmpl, Crossplane template: | blocks, etc.)
;
; Strategy:
; - Detect lines starting with common YAML document keys and map them back to YAML.
; - Fallback: treat block scalar-like regions as YAML unless clearly JSON.
; - Use heuristic: if content starts with '{' or '[' choose json.
; - Multi-line JSON support: also detect quoted JSON keys and closing braces so
;   interior lines of objects/arrays are injected as json, not yaml.
; - Overrides: {{/* yaml */}}, {{/* json */}}, {{/* raw */}}.
;
; NOTE: gotmpl parser provides text nodes for plain content. We match them broadly.
; If this becomes too noisy, refine with additional predicates.
 
; JSON opening brace / array start
((text) @injection.content
  (#match? @injection.content "^[\t ]*{")
  (#set! injection.language "json"))
 
((text) @injection.content
  (#match? @injection.content "^[\t ]*\\[")
  (#set! injection.language "json"))
 
; JSON interior key lines (quoted key typical of JSON object entries)
((text) @injection.content
  (#match? @injection.content "^[\t ]*\"[A-Za-z0-9_.-]\+\"[ \t]*:")
  (#set! injection.language "json"))

; YAML key-value heuristic: lines with key: value or just key:
((text) @injection.content
  (#match? @injection.content "^[\t ]*[A-Za-z0-9_-]+:[ ]")
  (#set! injection.language "yaml"))
 
; Common YAML document start or apiVersion/kind metadata (Kubernetes)
((text) @injection.content
  (#match? @injection.content "^(---|apiVersion:|kind:|metadata:|spec:|template:)" )
  (#set! injection.language "yaml"))
 
; Explicit override comment to force YAML: {{/* yaml */}}
((text) @injection.content
  (#match? @injection.content "{{/\* yaml \*/}}")
  (#set! injection.language "yaml"))
 
; Explicit override comment to force JSON: {{/* json */}}
((text) @injection.content
  (#match? @injection.content "{{/\* json \*/}}")
  (#set! injection.language "json"))
 
; Explicit override comment to force raw (disable nested injection): {{/* raw */}}
; We set language to gotmpl explicitly; since filetype already gotmpl this prevents
; other rules from re-injecting by ordering (place late so higher-priority earlier
; matches won't override explicit raw hint).
((text) @injection.content
  (#match? @injection.content "{{/\* raw \*/}}")
  (#set! injection.language "gotmpl"))
 
; Narrow fallback: only if typical Kubernetes structural keys present somewhere in line
((text) @injection.content
  (#match? @injection.content "(apiVersion:|kind:|metadata:|spec:|labels:|annotations:)")
  (#not-match? @injection.content "{{")
  (#not-match? @injection.content "}}")
  (#not-match? @injection.content "^[\t ]*{")
   (#not-match? @injection.content "^[\t ]*\\[")
   (#not-match? @injection.content "^[\t ]*\"[A-Za-z0-9_.-]\+\"[ \t]*:")
    (#set! injection.language "yaml"))
  

