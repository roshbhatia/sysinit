; Enhanced highlighting for Go templates with Crossplane, Kustomize, and Helm functions

; Template delimiters
[
  "{{"
  "}}"
] @punctuation.bracket

; Crossplane-specific template functions
((identifier) @function.builtin
 (#any-of? @function.builtin
   "setResourceNameAnnotation"
   "getResourceNameAnnotation"
   "fromCompositeFieldPath"
   "toCompositeFieldPath"
   "fromEnvironmentFieldPath"
   "toEnvironmentFieldPath"
   "combine"
   "convert"
   "string"
   "base64"
   "sha1"
   "sha256"))

; Helm template functions
((identifier) @function.builtin
 (#any-of? @function.builtin
   "include" "template" "toYaml" "toJson" "fromYaml" "fromJson"
   "quote" "squote" "cat" "indent" "nindent"
   "upper" "lower" "title" "untitle" "repeat"
   "trimSuffix" "trimPrefix" "trim" "trimAll"
   "replace" "contains" "hasPrefix" "hasSuffix"
   "split" "splitList" "join" "sortAlpha"
   "reverse" "first" "rest" "last" "initial"
   "append" "prepend" "concat" "slice"
   "until" "untilStep" "seq"
   "dict" "get" "set" "unset" "hasKey" "pluck" "keys" "pick" "omit"
   "merge" "mergeOverwrite" "deepCopy"
   "default" "empty" "coalesce" "compact"
   "typeOf" "typeIs" "typeIsLike" "kindOf" "kindIs"
   "deepEqual" "eq" "ne" "lt" "le" "gt" "ge"
   "semver" "semverCompare"
   "date" "dateInZone" "duration" "durationRound"
   "now" "ago" "toDate" "mustToDate"
   "b64enc" "b64dec" "b32enc" "b32dec"
   "encryptAES" "decryptAES"
   "uuidv4" "derivePassword"
   "buildCustomCert" "genCA" "genCAWithKey" "genSelfSignedCert"
   "genSelfSignedCertWithKey" "genSignedCert" "genSignedCertWithKey"
   "genPrivateKey" "derivePassword" "genRandomBytes"
   "htpasswd" "htdigest"
   "getHostByName"
   "fail" "required" "tpl"))

; Kustomize-specific functions (often used in patches)
((identifier) @function.builtin
 (#any-of? @function.builtin
   "nameReference" "namespace" "commonLabels" "commonAnnotations"
   "patchesStrategicMerge" "patchesJson6902" "images" "replicas"))

; Standard Go template functions
((identifier) @function.builtin
 (#any-of? @function.builtin
   "printf" "print" "println"
   "html" "js" "urlquery"
   "index" "slice" "len"
   "with" "if" "else" "end"
   "range" "template" "define" "block"
   "and" "or" "not"))

; Control flow keywords
((identifier) @keyword.control
 (#any-of? @keyword.control "if" "else" "end" "range" "with" "template" "define" "block"))

; Variables (starting with $)
((variable) @variable
 (#match? @variable "^\\$"))

; Pipeline operator
"|" @operator

; Field access (dot notation)
((field) @property)

; String literals
((string) @string)

; Numbers
((number) @number)

; Booleans
((boolean) @boolean)

; Comments
((comment) @comment)

; Helm built-in objects
((identifier) @variable.builtin
 (#any-of? @variable.builtin "Values" "Chart" "Release" "Capabilities" "Template" "Files"))

; Crossplane built-in objects
((identifier) @variable.builtin
 (#any-of? @variable.builtin "observed" "desired" "context"))

