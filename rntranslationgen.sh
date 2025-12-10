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
  --output-mode <mode>            Output mode: 'single' or 'dual' (default: single) (optional)
  --format                        Format generated files with Prettier (default: false) (optional)
  --noEmit                        Verify types without generating files, similar to tsc --noEmit (optional)
  --help, -h                      Display this help message

EXAMPLES:
  # Generate translation types (single file mode)
  rn-translation-gen --input ./locales --output ./generated

  # Generate with dual file mode
  rn-translation-gen --input ./locales --output ./generated --output-mode dual

  # Generate with config file (rn-translation-gen.json or rn-translation-gen.yml)
  rn-translation-gen

  # Exclude top-level key
  rn-translation-gen --input ./locales --output ./generated --exclude-key translation

  # Include eslint disable comments
  rn-translation-gen --input ./locales --output ./generated --disable-eslint-quotes

  # Check types without generating (for CI/CD pipelines)
  rn-translation-gen --input ./locales --output ./generated --noEmit

  # Generate and format with Prettier
  rn-translation-gen --input ./locales --output ./generated --format

OUTPUT FILES:
  Single mode (default):
    - translations.types.ts         TypeScript types and TRANSLATION_KEYS constant
  
  Dual mode:
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
FORMAT=false
OUTPUT_MODE="single"

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
    --format)
      FORMAT=true
      shift
      ;;
    --noEmit)
      NO_EMIT=true
      shift
      ;;
    --output-mode)
      OUTPUT_MODE="$2"
      if [ "$OUTPUT_MODE" != "single" ] && [ "$OUTPUT_MODE" != "dual" ]; then
        echo "❌ Invalid output mode: $OUTPUT_MODE. Use 'single' or 'dual'."
        exit 1
      fi
      shift 2
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

# Define output file paths based on output mode
if [ "$OUTPUT_MODE" = "single" ]; then
  # Single file mode: only translations.types.ts
  if [ "$NO_EMIT" = true ]; then
    TEMP_DIR=$(mktemp -d)
    VALUES_FILE="$TEMP_DIR/translations.types.ts"
    TYPES_FILE=""
  else
    VALUES_FILE="$OUTPUT_DIR/translations.types.ts"
    TYPES_FILE=""
  fi
else
  # Dual file mode: both .d.ts and .ts files
  if [ "$NO_EMIT" = true ]; then
    TEMP_DIR=$(mktemp -d)
    TYPES_FILE="$TEMP_DIR/translations.types.d.ts"
    VALUES_FILE="$TEMP_DIR/translations.types.ts"
  else
    TYPES_FILE="$OUTPUT_DIR/translations.types.d.ts"
    VALUES_FILE="$OUTPUT_DIR/translations.types.ts"
  fi
fi

# Prepare eslint disable comment based on flag
if [ "$DISABLE_ESLINT_QUOTES" = true ]; then
  ESLINT_DISABLE="/* eslint-disable quotes */"
else
  ESLINT_DISABLE=""
fi

# Generate translations.d.ts (only in dual mode)
if [ "$OUTPUT_MODE" = "dual" ]; then
  if [ -n "$ESLINT_DISABLE" ]; then
    echo "$ESLINT_DISABLE" > "$TYPES_FILE"
    echo "/* This file is auto-generated. Disabling quotes rule to avoid conflicts with extracted translation keys. */" >> "$TYPES_FILE"
  else
    echo "/* This file is auto-generated. */" > "$TYPES_FILE"
  fi
  echo "export type TranslationKey =" >> "$TYPES_FILE"
  echo "$FILTERED_JSON" | jq -r 'paths | map(tostring) | join(".")' | sed 's/^/  | "/;s/$/"/' >> "$TYPES_FILE"
  echo ";" >> "$TYPES_FILE"
fi

# Generate translations.ts
if [ -n "$ESLINT_DISABLE" ]; then
  echo "$ESLINT_DISABLE" > "$VALUES_FILE"
  echo "/* This file is auto-generated. */" >> "$VALUES_FILE"
else
  echo "/* This file is auto-generated. */" > "$VALUES_FILE"
fi

# Add type export based on mode
if [ "$OUTPUT_MODE" = "single" ]; then
  # Single file: TRANSLATION_KEYS first, then types inline
  echo "export const TRANSLATION_KEYS = " >> "$VALUES_FILE"
  echo "$FILTERED_JSON" | jq -S 'def transform(prefix): 
        with_entries(
          .key as $k | 
          if (.value | type) == "object" 
          then .value |= transform("\(prefix)\($k).") 
          else .value = "\(prefix)\($k)" 
          end
        ); 
      transform("")' | sed "s/\"/'/g" | sed "s/'\\([a-zA-Z_][a-zA-Z0-9_]*\\)':/\1:/g" | sed '$s/$/;/' >> "$VALUES_FILE"
  echo "" >> "$VALUES_FILE"
  echo "export type TranslationKey =" >> "$VALUES_FILE"
  KEYS=$(echo "$FILTERED_JSON" | jq -r 'paths | map(tostring) | join(".")')
  LAST_KEY=$(echo "$KEYS" | tail -1)
  echo "$KEYS" | sed '$d' | sed "s/^/  | '/;s/$/'/" >> "$VALUES_FILE"
  echo "  | '$LAST_KEY';" >> "$VALUES_FILE"
else
  # Dual file: re-export type from .d.ts file
  echo "export type { TranslationKey } from './translations.types.d';" >> "$VALUES_FILE"
  echo "" >> "$VALUES_FILE"
  echo "export const TRANSLATION_KEYS = " >> "$VALUES_FILE"
  echo "$FILTERED_JSON" | jq -S 'def transform(prefix): 
        with_entries(
          .key as $k | 
          if (.value | type) == "object" 
          then .value |= transform("\(prefix)\($k).") 
          else .value = "\(prefix)\($k)" 
          end
        ); 
      transform("")' | sed "s/\"/'/g" | sed "s/'\\([a-zA-Z_][a-zA-Z0-9_]*\\)':/\1:/g" | sed '$s/$/;/' >> "$VALUES_FILE"
  echo "" >> "$VALUES_FILE"
fi

# Format files with Prettier if available and enabled
format_with_prettier() {
  local file=$1
  if command -v prettier &> /dev/null; then
    prettier --write "$file" --print-width 80 --single-quote --semi --trailing-comma es5 --tab-width 2 --use-tabs false 2>/dev/null || true
  elif command -v npx &> /dev/null; then
    npx prettier --write "$file" --print-width 80 --single-quote --semi --trailing-comma es5 --tab-width 2 --use-tabs false 2>/dev/null || true
  fi
}

# Format the generated file(s) only if --format flag is enabled
if [ "$FORMAT" = true ]; then
  if [ "$OUTPUT_MODE" = "single" ]; then
    format_with_prettier "$VALUES_FILE"
  else
    format_with_prettier "$VALUES_FILE"
    format_with_prettier "$TYPES_FILE"
  fi
fi

# Handle --noEmit mode
if [ "$NO_EMIT" = true ]; then
  # Check for files to validate based on output mode
  if [ "$OUTPUT_MODE" = "single" ]; then
    if [ ! -f "$OUTPUT_DIR/translations.types.ts" ]; then
      echo "❌ Output file '$OUTPUT_DIR/translations.types.ts' not found. Run generation first."
      rm -rf "$TEMP_DIR"
      exit 1
    fi
    if ! diff -q "$TEMP_DIR/translations.types.ts" "$OUTPUT_DIR/translations.types.ts" >/dev/null 2>&1; then
      echo "❌ Type check failed: Generated file doesn't match existing file!"
      echo "   Translation files have changed. Run without --noEmit to regenerate types."
      rm -rf "$TEMP_DIR"
      exit 1
    fi
  else
    # Dual mode: check both files
    if [ ! -f "$OUTPUT_DIR/translations.types.d.ts" ]; then
      echo "❌ Output file '$OUTPUT_DIR/translations.types.d.ts' not found. Run generation first."
      rm -rf "$TEMP_DIR"
      exit 1
    fi
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
  fi
  
  rm -rf "$TEMP_DIR"
  echo "✅ 🎯 Type check passed! All translation types are up-to-date."
else
  if [ "$OUTPUT_MODE" = "single" ]; then
    echo "✅ 🎯 Successfully generated translations.types.ts in '$OUTPUT_DIR'!"
  else
    echo "✅ 🎯 Successfully generated translation types and constants in '$OUTPUT_DIR'!"
  fi
fi