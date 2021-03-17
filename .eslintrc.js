module.exports = {
  extends: ["plugin:vue/recommended", "plugin:prettier-vue/recommended"],

  settings: {
    "prettier-vue": {
      SFCBlocks: {
        template: true,
        script: true,
        style: true,
        customBlocks: {
          docs: { lang: "markdown" },
          config: { lang: "json" },
          module: { lang: "js" },
          comments: false
        }
      },
      usePrettierrc: true,
      fileInfoOptions: {
        ignorePath: ".prettierignore",
        withNodeModules: false
      }
    }
  },

  rules: {
    "prettier-vue/prettier": [
      "warn",
      {
        printWidth: 100,
        singleQuote: false,
        trailingComma: "es5",
        bracketSpacing: true,
        jsxBracketSameLine: false,
        semi: false,
        requirePragma: false,
        insertPragma: false,
        useTabs: false,
        tabWidth: 2,
        arrowParens: "avoid",
        proseWrap: "preserve",
        overrides: [
          {
            files: "*.scss",
            options: {
              parser: "scss"
            }
          }
        ]
      }
    ]
  }
};
