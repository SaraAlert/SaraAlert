# React Component Tests

The React component tests in Sara Alert are unit tests that focus on rendering each component tree in the application.  The tests are written using Jest, a JavaScript test runner that lets you access the DOM via jsdom, and the React Testing Library, a set of helpers that let you test React components without relying on their implementation details.

### Configuration

Root directory for the tests is set in the `package.json` file here
```  
"jest": {
    "roots": [
      "<rootDir>/app/javascript/tests"
    ],
```
All of the test files located in the component test folder set here will run with `yarn run test`.

### Running
When running the tests for the first time, run `yarn install` to install the react testing library.

To run all the react component tests:
```
yarn run test
```

To run individual react test files:

```
yarn test <test_file_path>
```

Example:

```
yarn test app/javascript/tests/layout/Breadcrumb.test.js
```

### Organization

React component tests in Sara Alert are located in `app/components/tests` and are organized using the same file structure as their component counter parts.  Each react component has its own testing file, called `<react_component_name>.test.js`.

In addition, there is a folder for mocks (see section below) in `app/components/tests`, which is the only folder that does not contain any react component tests.

### Mocks

ADD ME

### Best Practices

writting tests
accessing elements
logging - separate section?