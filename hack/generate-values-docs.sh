#!/usr/bin/env bash

# Generate documentation for values.nix from the values schema definition
# Extracts information from modules/lib/values/default.nix mkOption definitions

set -euo pipefail

README_FILE="${1:-README.md}"
VALUES_SCHEMA_FILE="modules/lib/values/default.nix"
START_MARKER="<!-- VALUES_SCHEMA_START -->"
END_MARKER="<!-- VALUES_SCHEMA_END -->"

# Temporary file for building documentation
TEMP_FILE=$(mktemp)

# Build the values schema documentation
cat >"$TEMP_FILE" <<'EOF'

## Values Configuration Schema

| Field | Type | Default | Required | Description |
|-------|------|---------|----------|-------------|
EOF

echo "Parsing values schema from $VALUES_SCHEMA_FILE..." >&2

# Parse the values schema file and extract field information
parse_schema() {
  local current_path=""
  local in_option=false
  local field_name=""
  local field_type=""
  local field_default=""
  local field_description=""
  local is_required=false

  while IFS= read -r line; do
    # Detect field names (like username = mkOption {)
    if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*=[[:space:]]*\{[[:space:]]*$ ]]; then
      # This is a nested section, update path
      section_name="${BASH_REMATCH[1]}"
      # Skip the "options" section name
      if [[ "$section_name" != "options" ]]; then
        if [[ -n "$current_path" ]]; then
          current_path="${current_path}.${section_name}"
        else
          current_path="${section_name}"
        fi
      fi
    elif [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*=[[:space:]]*mkOption[[:space:]]*\{[[:space:]]*$ ]]; then
      # This is an option definition
      in_option=true
      if [[ -n "$current_path" ]]; then
        field_name="${current_path}.${BASH_REMATCH[1]}"
      else
        field_name="${BASH_REMATCH[1]}"
      fi
      field_type=""
      field_default=""
      field_description=""
      is_required=true # Default to required unless we find a default value
    elif [[ "$in_option" == true ]]; then
      # Parse option properties
      if [[ "$line" =~ ^[[:space:]]*type[[:space:]]*=[[:space:]]*(.+)\;[[:space:]]*$ ]]; then
        field_type="${BASH_REMATCH[1]}"
        # Clean up type formatting
        field_type="${field_type#types.}"
        field_type="${field_type//types\.//g}"
        field_type="${field_type//\/g/}" # Remove /g artifacts
        if [[ "$field_type" == "nullOr str" ]]; then
          field_type="string?"
        elif [[ "$field_type" == "str" ]]; then
          field_type="string"
        elif [[ "$field_type" == "bool" ]]; then
          field_type="boolean"
        elif [[ "$field_type" == "int" ]]; then
          field_type="integer"
        elif [[ "$field_type" == "float" ]]; then
          field_type="float"
        elif [[ "$field_type" =~ listOf[[:space:]]+str ]]; then
          field_type="list(string)"
        elif [[ "$field_type" =~ "listOf str" ]]; then
          field_type="list(string)"
        fi
      elif [[ "$line" =~ ^[[:space:]]*default[[:space:]]*=[[:space:]]*(.+)\;[[:space:]]*$ ]]; then
        field_default="${BASH_REMATCH[1]}"
        is_required=false # Has a default, so not required
        if [[ "$field_default" == "null" ]]; then
          field_default="null"
        elif [[ "$field_default" =~ ^\[[[:space:]]*\]$ ]]; then
          field_default="[]"
        elif [[ "$field_default" =~ ^\".*\"$ ]]; then
          # Keep quoted strings as-is
          :
        elif [[ "$field_default" =~ ^(true|false)$ ]]; then
          # Keep booleans as-is
          :
        else
          field_default="\`$field_default\`"
        fi
      elif [[ "$line" =~ ^[[:space:]]*description[[:space:]]*=[[:space:]]*\"(.+)\"\;[[:space:]]*$ ]]; then
        field_description="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ ^[[:space:]]*\}\;[[:space:]]*$ ]]; then
        # End of option definition
        if [[ -n "$field_name" ]]; then
          required_mark=""
          if [[ "$is_required" == true ]]; then
            required_mark="✓"
            if [[ -z "$field_default" ]]; then
              field_default="-"
            fi
          fi

          echo "| \`$field_name\` | $field_type | $field_default | $required_mark | $field_description |"
        fi
        in_option=false
        field_name=""
      fi
    elif [[ "$line" =~ ^[[:space:]]*\}\;?[[:space:]]*$ ]]; then
      # End of nested section, pop from path
      if [[ "$current_path" == *.* ]]; then
        current_path="${current_path%.*}"
      else
        current_path=""
      fi
    fi
  done <"$VALUES_SCHEMA_FILE"
}

parse_schema | sort >>"$TEMP_FILE"

# Add usage examples and patterns
cat >>"$TEMP_FILE" <<'EOF'
EOF

# Inject the documentation into README.md
if [[ -f "$README_FILE" ]]; then
  if grep -q "$START_MARKER" "$README_FILE" && grep -q "$END_MARKER" "$README_FILE"; then
    # Replace content between markers
    awk -v start="$START_MARKER" -v end="$END_MARKER" '
      BEGIN { in_section=0; printed_new=0 }
      $0 == start {
        print $0
        while ((getline line < "'"$TEMP_FILE"'") > 0) print line
        close("'"$TEMP_FILE"'")
        in_section=1
        printed_new=1
        next
      }
      $0 == end {
        print $0
        in_section=0
        next
      }
      !in_section { print $0 }
    ' "$README_FILE" >"${README_FILE}.tmp"

    mv "${README_FILE}.tmp" "$README_FILE"
    echo "Documentation injected into $README_FILE" >&2
  else
    echo "Warning: Markers not found in $README_FILE. Add the following markers where you want the documentation:" >&2
    echo "  $START_MARKER" >&2
    echo "  $END_MARKER" >&2
  fi
else
  echo "Error: $README_FILE not found" >&2
  exit 1
fi

# Clean up
rm -f "$TEMP_FILE"
