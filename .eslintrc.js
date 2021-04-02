module.exports = {
    "parser": "babel-eslint",
    "env": {
        "browser": true,
        "es6": true,
        jest: true
    },
    "extends": [
        "eslint:recommended",
        "plugin:react/recommended",
        "plugin:security/recommended"
    ],
    "globals": {
        "Atomics": "readonly",
        "SharedArrayBuffer": "readonly"
    },
    "parserOptions": {
        "ecmaFeatures": {
            "jsx": true
        },
        "ecmaVersion": 2018,
        "sourceType": "module"
    },
    "plugins": [
        "react",
        "security"
    ],
    "rules": {
      "eol-last": 2,
      "no-trailing-spaces": 2,
      "prefer-arrow-callback": 2,
      "semi": 2
    },
    "settings": {
        "react": {
            "version": "detect"
        }
    }
};
