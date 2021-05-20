module.exports = {
  trailingComma: 'es5',
  tabWidth: 2,
  singleQuote: true,
  printWidth: 160,
  jsxBracketSameLine: true,
  arrowParens: "avoid",
  overrides: [
    {
      files: '*.test.js',
      options: {
        printWidth: 500,
      },
    },
  ],
};
