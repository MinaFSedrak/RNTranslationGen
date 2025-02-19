#!/bin/bash

# Default values for input and output paths
TRANSLATION_DIR=""
OUTPUT_DIR=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --input)
      TRANSLATION_DIR="$2"
      shift 2
      ;;
    --output)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    *)
      echo "❌ Unknown option: $1"
      exit 1
      ;;
  esac
done


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

# Define output file paths
TYPES_FILE="$OUTPUT_DIR/translations.d.ts"
VALUES_FILE="$OUTPUT_DIR/translations.ts"

# Generate translations.d.ts
echo "/* eslint-disable quotes */" > "$TYPES_FILE"
echo "/* This file is auto-generated. Disabling quotes rule to avoid conflicts with extracted translation keys. */" >> "$TYPES_FILE"

echo "export type TranslationKey =" >> "$TYPES_FILE"
jq -r 'paths | map(tostring) | join(".")' "$MAIN_FILE" | sed 's/^/  | "/;s/$/"/' >> "$TYPES_FILE"
echo ";" >> "$TYPES_FILE"

# Generate translations.ts
echo "/* eslint-disable quotes */" > "$VALUES_FILE"
echo "/* This file is auto-generated. Contains actual translation key values. */" >> "$VALUES_FILE"

echo "export const TRANSLATION_KEYS = " >> "$VALUES_FILE"
jq 'def transform(prefix): 
      with_entries(
        .key as $k | 
        if (.value | type) == "object" 
        then .value |= transform("\(prefix)\($k).") 
        else .value = "\(prefix)\($k)" 
        end
      ); 
    transform("")' "$MAIN_FILE" >> "$VALUES_FILE"
echo ";" >> "$VALUES_FILE"

# Generate translationHelper.ts
# cat <<EOL > "$HELPER_FILE"
# export const t = (key: TranslationKeys): string => {
#   // Replace this with your actual translation function (i18next.t, react-native-localize, etc.)
#   return key; // Simulating translation function (replace this with actual translation logic)
# };
# EOL

echo "✅ 🎯 Successfully generated translation types and constants in '$OUTPUT_DIR'!"
