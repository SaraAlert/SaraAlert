# React Component Tests

The React component tests in Sara Alert are unit tests that focus on rendering each component tree in the application.  The tests are written using Jest, a JavaScript test runner that lets you access the DOM via jsdom, and the React Testing Library, a set of helpers that let you test React components without relying on their implementation details.

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

React component tests in Sara Alert are located in `app/components/tests` and are organized using the same file structure as their component counter parts.  Each react component has its own testing file, called `<react_component_name>.test.js`.

In addition, there is a folder for mocks (see section below) in `app/components/tests`, which is the only folder that does not contain any react component tests.

### Mocks

Mock objects that are props for Sara Alert components are kept in `app/components/tests/mocks`.  These objects can then be imported into the test files and used as props when the tests render each component.  Each file represents a different Sara Alert object (i.e. patient, user, etc).

### Best Practices

#### Writing tests

Unit tests should each test the smallest amount of functionality as possible. For that reason, each test should be succinct.

##### Test blocks

Each test should resemble the following format:
```
test('a descriptive test name', async () => {
 // test code here
});
```

##### Expect method

Within each test, the most common testing call will probably be `expect()`:
```      
test('TestComponent Properly Renders Header Text', async () => {
  render(<TestComponent/>);
  const headerText = "Test Header!"
  expect(screen.getByText(headerText)).toBeInTheDocument();
});
```
A list of functions that can be `expect()` (_e.g. toBeInTheDocument()_) can be found in the documentation [here](https://github.com/testing-library/jest-dom#custom-matchers).

##### Describe blocks

Because unit tests should test the smallest amount of funtionality as possible, certain functions might require multiple tests.  In this case, these tests should be logically grouped using a `describe` block:
```
describe('ComponentX properly renders', () => {
  test('section headers', () => {
    // test code here
  });

  test('submit button', () => {
    // test code here
  });
});
```

#### Accessing elements

When accessing elements in a test, use a combination of a variant and a query.  Each query uses a different identifier (i.e. role, text, title, etc) to select the element in the DOM and variant specifies by what method and how many elements will be returned

##### Queries

`ByLabelText` find by label or aria-label text content

`ByPlaceholderText` find by input placeholder value

`ByText` find by element text content

`ByDisplayValue` find by form element current value

`ByAltText` find by img alt attribute

`ByTitle` find by title attribute or svg title tag

`ByRole` find by aria role

`ByTestId` find by data-testid attribute

`data-testid` should only be used an element cannot reliably be selected by any of the other queries. For further details on what query should be used, see this query priority list [here](https://testing-library.com/docs/guide-which-query).

##### Variants

`getBy*` queries return the first matching node for a query, and throw an error if no elements match or if more than one match is found (use getAllBy instead).

`getAllBy*` queries return an array of all matching nodes for a query, and throw an error if no elements match.

`queryBy*` queries return the first matching node for a query, and return null if no elements match. This is useful for asserting an element that is not present. This throws if more than one match is found (use queryAllBy instead).

`queryAllBy*` queries return an array of all matching nodes for a query, and return an empty array ([]) if no elements match.

`findBy*` queries return a promise which resolves when an element is found which matches the given query. The promise is rejected if no element is found or if more than one element is found after a default timeout of 1000ms. If you need to find more than one element, then use findAllBy.

`findAllBy*` queries return a promise which resolves to an array of elements when any elements are found which match the given query. The promise is rejected if no elements are found after a default timeout of 1000ms.

##### Examples

This test expects the text `title` to be in the DOM:
```
expect(screen.getByText('title')).toBeInTheDocument();
```

This test expects the element with `data_testid = 'test_id'` to contain the text `hello`:
```
expect(screen.getByTestId('test_id')).toHaveTextContent('hello');
```

See [here](https://testing-library.com/docs/dom-testing-library/cheatsheet) for a full cheatsheet on queries and variants

### Logging

`screen.debug();` allows logging for the test files and will create a DOM-dump to assist with debugging.  This is essentially `console.log()` for Jest.
