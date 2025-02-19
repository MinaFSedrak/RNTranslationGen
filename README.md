# Translation Key Generator for TypeScript

This library automatically generates **strongly typed translation keys** from JSON files for React Native and TypeScript projects.  
It ensures **compile-time safety**, preventing errors caused by incorrect translation keys.

Additionally, this tool is designed as a **build-time utility**, meaning it should be installed as a **devDependency** rather than a regular dependency. This prevents unnecessary bloating of the production bundle, as the generated types are only required during development.

---

## **🚀 Features**
✅ **Generates TypeScript types (`translations.d.ts`)** for all translation keys.  
✅ **Creates a `TRANSLATION_KEYS` object (`translations.ts`)** for type-safe key usage.  
✅ **Ensures compile-time errors** if an incorrect key is used.  
✅ **Works with deeply nested translation JSON structures.**  
✅ **Customizable input and output paths for translation files.**

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
### **Example:**
```sh
npx rn-translation-gen --input ./translations --output ./src/types
```
This will scan the `./translations` folder for JSON files and generate the `translations.d.ts` file and `translations.ts` inside `./src/types`.

---

## **📌 Example Output**
### **Given a translation file (`en.json`):**
```json
{
  "home": {
    "title": "Welcome Home",
    "description": "This is the home page."
  }
}
```

### **The library will generate:**
#### **`translations.d.ts` (Type Definitions for Safety)**
```ts
export type TranslationKey =
  | "home.title"
  | "home.description";
```

#### **`translations.ts` (Constants for Easy Access)**
```ts
export const TRANSLATION_KEYS = {
  home: {
    title: "home.title",
    description: "home.description"
  }
};
```

With this setup, you can use the generated types and constants in your application to avoid hardcoded strings and typos:
```ts
import { TRANSLATION_KEYS } from "./translations";

const titleKey = TRANSLATION_KEYS.home.title;
console.log(titleKey); // Output: "home.title"
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
