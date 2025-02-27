# Translation Key Generator for TypeScript

This library automatically generates **strongly typed translation keys** from JSON files for React Native and TypeScript projects.\
It ensures **compile-time safety**, preventing errors caused by incorrect translation keys.

Additionally, this tool is designed as a **build-time utility**, meaning it should be installed as a **devDependency** rather than a regular dependency. This prevents unnecessary bloating of the production bundle, as the generated types are only required during development.

---

## **🚀 Features**

✅ **Generates TypeScript types (`translations.d.ts`)** for all translation keys.\
✅ **Creates a `TRANSLATION_KEYS` object (`translations.ts`)** for type-safe key usage.\
✅ **Ensures compile-time errors** if an incorrect key is used.\
✅ **Works with deeply nested translation JSON structures.**\
✅ **Customizable input and output paths for translation files.**\
✅ **Supports configuration via both JSON (`rn-translation-gen.json`) and YAML (`rn-translation-gen.yml`) files.**

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
npx rn-translation-gen --input <path-to-json-files> --output <path-to-generated-files>
```

Alternatively, you can use a config file for input and output paths. The tool will automatically detect either:

- `rn-translation-gen.json`
- `rn-translation-gen.yml`

### **Examples:**

**Using CLI arguments:**

```sh
npx rn-translation-gen --input ./src/translations/json_files --output ./src/generated/translation_types
```

**Using a JSON config file (`rn-translation-gen.json`):**

```json
{
  "input": "./src/translations/json_files",
  "output": "./src/generated/translation_types"
}
```

**Using a YAML config file (`rn-translation-gen.yml`):**

```yaml
input: ./src/translations/json_files
output: ./src/generated/translation_types
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
        delete: "screens.Chat.actions.delete"
      }
    },
    Profile: {
      title: "screens.Profile.title",
      actions: {
        edit: "screens.Profile.actions.edit",
        logout: "screens.Profile.actions.logout"
      }
    }
  },
  messages: {
    notifications: {
      newMessage: "messages.notifications.newMessage",
      userOnline: "messages.notifications.userOnline"
    },
    errors: {
      network: "messages.errors.network",
      unauthorized: "messages.errors.unauthorized"
    }
  }
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

