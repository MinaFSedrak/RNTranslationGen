# Translation Key Generator for TypeScript

This library automatically generates **strongly typed translation keys** from JSON files for React Native and TypeScript projects.\
It ensures **compile-time safety**, preventing errors caused by incorrect translation keys.

Additionally, this tool is designed as a **build-time utility**, meaning it should be installed as a **devDependency** rather than a regular dependency. This prevents unnecessary bloating of the production bundle, as the generated types are only required during development.

---

## **🚀 Features**

✅ **Generates TypeScript types (`translations.types.d.ts`)** for all translation keys.\
✅ **Creates a `TRANSLATION_KEYS` object (`translations.types.ts`)** for type-safe key usage.\
✅ **Ensures compile-time errors** if an incorrect key is used.\
✅ **Works with deeply nested translation JSON structures.**\
✅ **Customizable input and output paths for translation files.**\
✅ **Supports configuration via both JSON (`rn-translation-gen.json`) and YAML (`rn-translation-gen.yml`) files.**\
✅ **Flexible output modes: Single-file (default) or dual-file mode using `--output-mode`.**\
✅ **Optionally exclude a top-level key (e.g., "translation") and unwrap its children using `--exclude-key`.**\
✅ **Control eslint quote disabling in generated files using `--disable-eslint-quotes` flag.**\
✅ **Verify types without generating files using `--noEmit` flag (perfect for CI/CD pipelines).**\
✅ **Optional Prettier formatting with `--format` flag for 80-character line wrapping and code style compliance.**\
✅ **Built-in help documentation with `--help` and `-h` flags.**

---

## **📦 Installation**

Since this is a build-time tool, install it as a **devDependency**:

```sh
npm install rn-translation-gen --save-dev
```

or using Yarn:

```sh
yarn add rn-translation-gen --dev
```

---

## **⚙️ Usage**

To generate translation types and keys, run the following command:

```sh
npx rn-translation-gen --input <path-to-json-files> --output <path-to-generated-files> [--output-mode single|dual] [--exclude-key <key-to-exclude>] [--disable-eslint-quotes] [--noEmit]
```

### **Flags:**

- `--input` (required): Path to the directory containing translation JSON files
- `--output` (required): Path to the output directory for generated files
- `--output-mode` (optional): Output mode - `single` (default) generates one file, `dual` generates two files
- `--exclude-key` (optional): Exclude a top-level key and unwrap its children
- `--disable-eslint-quotes` (optional): Include `/* eslint-disable quotes */` comments in generated files
- `--format` (optional): Format generated files with Prettier for code style compliance (default: false)
- `--noEmit` (optional): Verify types without generating files (similar to `tsc --noEmit`)
- `--help, -h` (optional): Display help documentation with all available options

Alternatively, you can use a config file for input and output paths. The tool will automatically detect either:

- `rn-translation-gen.json`
- `rn-translation-gen.yml`

### **Examples:**

**Single-file mode (default) with exclude-key:**

```sh
npx rn-translation-gen --input ./src/translations/json_files --output ./src/generated/translation_types --exclude-key translation
```

**Dual-file mode with exclude-key:**

```sh
npx rn-translation-gen --input ./src/translations/json_files --output ./src/generated/translation_types --output-mode dual --exclude-key translation
```

**Using CLI arguments with eslint disable comments:**

```sh
npx rn-translation-gen --input ./src/translations/json_files --output ./src/generated/translation_types --disable-eslint-quotes
```

**Verifying types without generating files (for CI/CD pipelines):**

```sh
npx rn-translation-gen --input ./src/translations/json_files --output ./src/generated/translation_types --noEmit
```

This fails if translation files have changed but types haven't been regenerated, perfect for catching out-of-sync translations in your pipeline.

**Formatting generated files with Prettier:**

```sh
npx rn-translation-gen --input ./src/translations/json_files --output ./src/generated/translation_types --format
```

This applies Prettier formatting with 80-character line wrapping for better code readability and style compliance.

**Using a JSON config file (`rn-translation-gen.json`):**

```json
{
  "input": "./src/translations/json_files",
  "output": "./src/generated/translation_types",
  "excludeKey": "translation",
  "disableEslintQuotes": true,
  "format": true
}
```

**Using a YAML config file (`rn-translation-gen.yml`):**

```yaml
input: ./src/translations/json_files
output: ./src/generated/translation_types
excludeKey: translation
disableEslintQuotes: true
format: true
```

---

## **📌 Example**

Let’s say you’re building a **Multi-Screen App** with screens like **Chat**, **Profile**, and **Error Handling**.

### **Translation file (`en.json`):**

```json
{
  "screens": {
    "Chat": {
      "title": "Chats",
      "actions": {
        "send": "Send",
        "delete": "Delete"
      }
    },
    "Profile": {
      "title": "Profile",
      "actions": {
        "edit": "Edit Profile",
        "logout": "Logout"
      }
    }
  },
  "messages": {
    "notifications": {
      "newMessage": "You have a new message!",
      "userOnline": "{username} is now online."
    },
    "errors": {
      "network": "Network error. Please try again.",
      "unauthorized": "Unauthorized access."
    }
  }
}
```

---

### **Generated output:**

**Type Definitions (`translations.d.ts`):**

```ts
export type TranslationKey =
  | "screens.Chat.title"
  | "screens.Chat.actions.send"
  | "screens.Chat.actions.delete"
  | "screens.Profile.title"
  | "screens.Profile.actions.edit"
  | "screens.Profile.actions.logout"
  | "messages.notifications.newMessage"
  | "messages.notifications.userOnline"
  | "messages.errors.network"
  | "messages.errors.unauthorized";
```

**Key Constants (`translations.ts`):**

```ts
export const TRANSLATION_KEYS = {
  screens: {
    Chat: {
      title: "screens.Chat.title",
      actions: {
        send: "screens.Chat.actions.send",
        delete: "screens.Chat.actions.delete",
      },
    },
    Profile: {
      title: "screens.Profile.title",
      actions: {
        edit: "screens.Profile.actions.edit",
        logout: "screens.Profile.actions.logout",
      },
    },
  },
  messages: {
    notifications: {
      newMessage: "messages.notifications.newMessage",
      userOnline: "messages.notifications.userOnline",
    },
    errors: {
      network: "messages.errors.network",
      unauthorized: "messages.errors.unauthorized",
    },
  },
};
```

---

### **Usage in a React component:**

```tsx
import React from "react";
import { Text, View, Button } from "react-native";
import { TRANSLATION_KEYS } from "./translations";
import { TranslationKey } from "./translations";

const Notification = ({ messageKey }: { messageKey: TranslationKey }) => {
  return <Text>{messageKey}</Text>; // Displays the translation key
};

const ChatScreen = () => {
  const titleKey: TranslationKey = TRANSLATION_KEYS.screens.Chat.title;
  const sendKey: TranslationKey = TRANSLATION_KEYS.screens.Chat.actions.send;

  return (
    <View>
      <Text>{titleKey}</Text>
      <Button title={sendKey} onPress={() => {}} />
      <Notification messageKey={TRANSLATION_KEYS.messages.errors.network} />
    </View>
  );
};

export default ChatScreen;
```

---

## **📜 Notes**

- Ensure your translation files (`en.json`, `ar.json`, etc.) are valid JSON format.
- **Prerequisite:** This tool requires `jq`, a lightweight JSON processor. Install it if not already available:
  - **Mac**: `brew install jq`
  - **Linux**: `sudo apt install jq`
  - **Windows**: `choco install jq`

---

✅ Enjoy seamless translations! Feel free to contribute or report issues. 🚀
