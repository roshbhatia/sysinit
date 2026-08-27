const correctness = {
  "for-direction": "error",
  "getter-return": "error",
  "no-const-assign": "error",
  "no-constant-condition": "error",
  "no-dupe-keys": "error",
  "no-duplicate-case": "error",
  "no-fallthrough": "error",
  "no-redeclare": "error",
  "no-self-assign": "error",
  "no-undef": "error",
  "no-unreachable": "error",
  "no-unused-vars": ["error", { args: "after-used", caughtErrors: "none" }],
  "use-isnan": "error",
};

export default [
  {
    files: ["**/*.js", "**/*.mjs"],
    ignores: ["**/package-lock.json"],
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
    },
    rules: correctness,
  },
  {
    files: ["modules/darwin/home/hammerspoon/**/*.js"],
    languageOptions: {
      sourceType: "script",
      globals: {
        document: "readonly",
        window: "readonly",
      },
    },
    // panel.lua concatenates these scripts, so their entry points resolve in the combined document.
    rules: {
      "no-unused-vars": [
        "error",
        { args: "after-used", caughtErrors: "none", varsIgnorePattern: "^(calculate|prepare|rank)$" },
      ],
    },
  },
  {
    files: ["**/*.mjs"],
    languageOptions: {
      globals: {
        process: "readonly",
      },
    },
  },
];
