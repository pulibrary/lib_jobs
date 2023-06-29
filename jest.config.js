const path = require("path")

module.exports = {
  verbose: true,
  rootDir: path.resolve(__dirname),
  modulePaths: ["<rootDir>"],
  moduleFileExtensions: [
    "js",
    "json",
    "vue"
  ],
  moduleNameMapper: {
    "^@/(.*)$": "<rootDir>/app/javascript/$1",
  },
  setupFiles: [
    "<rootDir>/app/javascript/__tests__/setup"
  ],
  coverageDirectory: "<rootDir>/app/javascript/__tests__/coverage",
  testMatch: [
    "<rootDir>/app/javascript/__tests__/**/*\\.spec\\.js"
  ]
};
