module.exports = {
  "setupFilesAfterEnv": [
    "<rootDir>/app/javascript/tests/setupTests.js"
  ],
  "snapshotSerializers": [
    "enzyme-to-json/serializer"
  ],
  "roots": [
    "<rootDir>/app/javascript/tests"
  ],
  "verbose": true,
  "testURL": "http://localhost",
  "moduleFileExtensions": [
    "js",
    "json"
  ],
  "moduleDirectories": [
    "node_modules",
    "<rootDir>/app/javascript"
  ],
  "moduleNameMapper": {
    "^@/(.*)$": "<rootDir>/$1",
    "\\.(css|sass|scss)$": "identity-obj-proxy"
  },
  "transform": {
    "^.+\\.js$": "<rootDir>/node_modules/babel-jest"
  },
  "transformIgnorePatterns": [
    "node_modules/(?!(rc-slider|@amcharts)/)"
  ]
}