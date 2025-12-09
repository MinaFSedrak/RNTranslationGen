#!/bin/bash

# Help function
show_help() {
  cat << 'EOF'
Usage: rn-translation-gen [OPTIONS]

Generate strongly typed translation keys from JSON files for React Native and TypeScript projects.

OPTIONS:
  --input <path>                  Path to the directory containing translation JSON files (required)
  --output <path>                 Path to the output directory for generated files (required)
  --exclude-key <key>             Exclude a top-level key and unwrap its children (optional)
  --disable-eslint-quotes         Include eslint-disable-quotes comments in generated files (optional)
  --noEmit                        Verify types without generating files, similar to tsc --noEmit (optional)
  --help, -h                      Display this help message

EXAMPLES:
  # Generate translation types
  rn-translation-gen --input ./locales --output ./generated

  # Generate with config file (rn-translation-gen.json or rn-translation-gen.yml)
  rn-translation-gen

  # Exclude top-level key
  rn-translation-gen --input ./locales --output ./generated --exclude-key translation

  # Include eslint disable comments
  rn-translation-gen --input ./locales --output ./generated --disable-eslint-quotes

  # Check types without generating (for CI/CD pipelines)
  rn-translation-gen --input ./locales --output ./generated --noEmit

OUTPUT FILES:
  - translations.types.d.ts       TypeScript type definitions for translation keys
  - translations.types.ts         TRANSLATION_KEYS constant and type re-export

For more information, visit: https://github.com/MinaFSedrak/RNTranslationGen
EOF
  exit 0
}

# Get the project root (the directory containing node_modules) and removing node_modules from the path
PROJECT_ROOT=$(dirname "$(dirname "$(realpath "$0")")" | sed 's|/node_modules.*||')

# Default values for input and output paths
TRANSLATION_DIR=""
OUTPUT_DIR=""
EXCLUDE_KEY=""
DISABLE_ESLINT_QUOTES=false
NO_EMIT=false

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --help|-h)
      show_help
      ;;
    --input)
      TRANSLATION_DIR="$2"
      shift 2
      ;;
    --output)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --exclude-key)
      EXCLUDE_KEY="$2"
      shift 2
      ;;
    --disable-eslint-quotes)
      DISABLE_ESLINT_QUOTES=true
      shift
      ;;
    --noEmit)
      NO_EMIT=true
      shift
      ;;
    *)
      echo "❌ Unknown option: $1"
      echo "Run with --help for usage information"
      exit 1
      ;;
  esac
done

# If CLI args are empty, check for config files
if [ -z "$TRANSLATION_DIR" ] || [ -z "$OUTPUT_DIR" ]; then
  for file in "$PROJECT_ROOT/rn-translation-gen.yml" "$PROJECT_ROOT/rn-translation-gen.json"; do
    if [ -f "$file" ]; then
      if [[ "$file" == *.yml ]]; then
        # Basic YAML to JSON conversion using awk (no external tools like yq)
        TRANSLATION_DIR=$(awk -F ': ' '/input:/ {print $2}' "$file" | tr -d '"')
        OUTPUT_DIR=$(awk -F ': ' '/output:/ {print $2}' "$file" | tr -d '"')
        EXCLUDE_KEY=$(awk -F ': ' '/excludeKey:/ {print $2}' "$file" | tr -d '"')
        DISABLE_ESLINT=$(awk -F ': ' '/disableEslintQuotes:/ {print $2}' "$file" | tr -d '"')
      else
        TRANSLATION_DIR=$(jq -r '.input // empty' "$file")
        OUTPUT_DIR=$(jq -r '.output // empty' "$file")
        EXCLUDE_KEY=$(jq -r '.excludeKey // empty' "$file")
        DISABLE_ESLINT=$(jq -r '.disableEslintQuotes // empty' "$file")
      fi
      # Convert YAML/JSON boolean to bash boolean
      if [ "$DISABLE_ESLINT" = "true" ] || [ "$DISABLE_ESLINT" = "True" ]; then
        DISABLE_ESLINT_QUOTES=true
      fi
      break
    fi
  done
fi

# Ensure jq is installed
if ! command -v jq &> /dev/null; then
    echo "❌ jq is not installed. Install it using:"
    echo "   - Mac: brew install jq"
    echo "   - Linux: sudo apt install jq"
    echo "   - Windows: choco install jq"
    exit 1
fi

# Ensure input and output paths are provided
if [ -z "$TRANSLATION_DIR" ]; then
    echo "❌ No input directory specified. Use --input <path>."
    exit 1
fi
if [ -z "$OUTPUT_DIR" ]; then
    echo "❌ No output directory specified. Use --output <path>."
    exit 1
fi

# Ensure the input directory exists
if [ ! -d "$TRANSLATION_DIR" ]; then
    echo "❌ Translation directory '$TRANSLATION_DIR' does not exist."
    exit 1
fi

# Ensure the output directory exists
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "❌ Output directory '$OUTPUT_DIR' does not exist. Please create it first."
    exit 1
fi

# Find the first translation file (assuming all have the same structure)
MAIN_FILE=$(find "$TRANSLATION_DIR" -maxdepth 1 -type f -name "*.json" | head -n 1)

# Ensure the JSON file is valid
if [ -z "$MAIN_FILE" ]; then
    echo "❌ No JSON translation files found in '$TRANSLATION_DIR'."
    exit 1
fi
if ! jq empty "$MAIN_FILE" >/dev/null 2>&1; then
    echo "❌ JSON format error in '$MAIN_FILE'! Please fix it."
    exit 1
fi

# Prepare filtered JSON content, replacing root with the value of the excluded key if provided
if [ -n "$EXCLUDE_KEY" ]; then
  FILTERED_JSON=$(jq "if has(\"$EXCLUDE_KEY\") then .[\"$EXCLUDE_KEY\"] else . end" "$MAIN_FILE")
else
  FILTERED_JSON=$(cat "$MAIN_FILE")
fi

# Define output file paths
if [ "$NO_EMIT" = true ]; then
  # Use temporary directory for --noEmit mode
  TEMP_DIR=$(mktemp -d)
  TYPES_FILE="$TEMP_DIR/translations.types.d.ts"
  VALUES_FILE="$TEMP_DIR/translations.types.ts"
else
  TYPES_FILE="$OUTPUT_DIR/translations.types.d.ts"
  VALUES_FILE="$OUTPUT_DIR/translations.types.ts"
fi

# Prepare eslint disable comment based on flag
if [ "$DISABLE_ESLINT_QUOTES" = true ]; then
  ESLINT_DISABLE="/* eslint-disable quotes */"
else
  ESLINT_DISABLE=""
fi

# Generate translations.d.ts
if [ -n "$ESLINT_DISABLE" ]; then
  echo "$ESLINT_DISABLE" > "$TYPES_FILE"
  echo "/* This file is auto-generated. Disabling quotes rule to avoid conflicts with extracted translation keys. */" >> "$TYPES_FILE"
else
  echo "/* This file is auto-generated. */" > "$TYPES_FILE"
fi
echo "export type TranslationKey =" >> "$TYPES_FILE"
echo "$FILTERED_JSON" | jq -r 'paths | map(tostring) | join(".")' | sed 's/^/  | "/;s/$/"/' >> "$TYPES_FILE"
echo ";" >> "$TYPES_FILE"

# Generate translations.ts
if [ -n "$ESLINT_DISABLE" ]; then
  echo "$ESLINT_DISABLE" > "$VALUES_FILE"
  echo "/* This file is auto-generated. Contains actual translation key values. */" >> "$VALUES_FILE"
else
  echo "/* This file is auto-generated. */" > "$VALUES_FILE"
fi
echo "export type { TranslationKey } from './translations.d';" >> "$VALUES_FILE"
echo "export const TRANSLATION_KEYS = " >> "$VALUES_FILE"
echo "$FILTERED_JSON" | jq 'def transform(prefix): 
      with_entries(
        .key as $k | 
        if (.value | type) == "object" 
        then .value |= transform("\(prefix)\($k).") 
        else .value = "\(prefix)\($k)" 
        end
      ); 
    transform("")' >> "$VALUES_FILE"
echo ";" >> "$VALUES_FILE"

# Handle --noEmit mode
if [ "$NO_EMIT" = true ]; then
  # Check if output directory has existing files to compare
  if [ ! -f "$OUTPUT_DIR/translations.types.d.ts" ]; then
    echo "❌ Output file '$OUTPUT_DIR/translations.types.d.ts' not found. Run generation first."
    rm -rf "$TEMP_DIR"
    exit 1
  fi
  
  # Compare generated types with existing files
  if ! diff -q "$TEMP_DIR/translations.types.d.ts" "$OUTPUT_DIR/translations.types.d.ts" >/dev/null 2>&1; then
    echo "❌ Type check failed: Generated types don't match existing files!"
    echo "   Translation files have changed. Run without --noEmit to regenerate types."
    rm -rf "$TEMP_DIR"
    exit 1
  fi
  
  if ! diff -q "$TEMP_DIR/translations.types.ts" "$OUTPUT_DIR/translations.types.ts" >/dev/null 2>&1; then
    echo "❌ Type check failed: Generated constants don't match existing files!"
    echo "   Translation files have changed. Run without --noEmit to regenerate types."
    rm -rf "$TEMP_DIR"
    exit 1
  fi
  
  rm -rf "$TEMP_DIR"
  echo "✅ 🎯 Type check passed! All translation types are up-to-date."
else
  echo "✅ 🎯 Successfully generated translation types and constants in '$OUTPUT_DIR'!"
fi