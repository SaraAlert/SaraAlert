# React Component Tests

The React component tests in Sara Alert are unit tests that focus on rendering each component tree in the application.  The tests are written using Jest, a JavaScript test runner that lets you access the DOM via jsdom, and Enzyme, a utility for React that makes it easier to test React Components' output by manipulating, traversing, and in some ways simulating the runtime given the output.

### Configuration

Root directory for the tests is set in the `package.json` file here:
```
"jest": {
    "roots": [
      "<rootDir>/app/javascript/tests"
    ],
```
All of the test files located in the component test folder set here will run with `yarn run test`.

### Running
When running the tests for the first time, run `yarn install` to install the React Testing Library.

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

React component tests in Sara Alert are located in `app/javascript/tests` and are organized using the same file structure as their component counter parts.  Each react component has its own testing file, called `<react_component_name>.test.js`.

In addition, there is a folder for mocks (see section below) in `app/javascript/tests`, which is the only folder that does not contain any react component tests.

### Mocks

Mock objects that are props for Sara Alert components are kept in `app/javascript/tests/mocks`.  These objects can then be imported into the test files and used as props when the tests render each component.  Each file represents a different Sara Alert object (i.e. patient, user, etc).

### Best Practices

#### Writing tests

Unit tests should each test the smallest amount of functionality as possible. For that reason, each test should be succinct.

EnzymeJS uses three main ways of rendering components: Shallow, Full, and Static Rendering.

[Shallow Rendering](https://enzymejs.github.io/enzyme/docs/api/shallow.html) is useful to constrain testing of a component as a unit, and to ensure that tests aren't indirectly asserting on behavior of child components.

[Full Rendering](https://enzymejs.github.io/enzyme/docs/api/mount.html) is ideal for use cases where the components may interact with DOM APIs or need to test components that are wrapped in higher order components.

[Static Rendering](https://enzymejs.github.io/enzyme/docs/api/render.html) is used for to generate HTML from tge React tree, and analyze the resulting HTML structure.

##### Describe blocks

Because unit tests should test the smallest amount of funtionality as possible, certain components might require multiple tests.  In this case, these tests should be logically grouped using a `describe` block:
```
describe('ComponentX', () => {
  test('properly renders', () => {
    // test code here
  });

  test('contains the header text', () => {
    // test code here
  });

  test('contains the correct data', () => {
    // test code here
  });
});
```

##### Expect method

Within each test, the most common testing call will probably be `expect()`:
```
  it('properly renders', () => {
    expect(wrapped).toMatchSnapshot();
  });
```
A list of functions that can be used with `expect()` (_e.g. toMatchSnapshot()_) can be found in the documentation [here](https://jestjs.io/docs/en/expect).
