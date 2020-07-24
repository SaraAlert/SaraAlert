# System Tests

System tests in SaraAlert are currently configured to run in Chrome in a 1400 x 1400 window locally and in a headless Chrome browser when in CI.
These configurations can be found in `test/application_system_test_case.rb`.

The tests are also retried upon failure by default up to 3 times, which is a configurable setting in `test/system_test_case.rb`

### Running

By default, the `rails test` command used to execute all the other tests will not run system tests. To run all the system tests:

```
bundle exec rails test:system
```

To run individual system test files:

```
ruby -I test <test_file_path>
```

Example:

```
ruby -I test test/system/roles/public_health/public_health_test.rb
```

### Organization

System tests in SaraAlert are mainly organized by the different types of users and roles,
with the exception of the workflow tests which test the app across multiple roles.

Within each `test/system/roles/<role>` directory, there is a main test file named `<role>_test.rb` which describes all the test cases and for some of the
larger roles, a `<role>_test_helper.rb` file is also present to contain the high level logic and steps to execute the actions and events involved in the test

### Form Data

The `test/system/form_data` directory contains test data used to populate forms during tests.
This is not to be confused with the test fixtures in the next section.

### Fixtures

Most tests rely on pre-populated data from the test database, which is defined in yml files within the `test/fixtures` directory.
The test database is also restored to a fresh state between every individual test to prevent different them from interfering with each other.
For details on the usage of fixtures, please check out the [fixtures documentation](https://api.rubyonrails.org/v6.0.3.2/classes/ActiveRecord/FixtureSet.html)

Some tests, such as the import tests, rely on file fixtures as well, which should be placed in the `test/fixtures/files` directory.
These file paths of these files can be referenced by calling `file_fixture(file_name)`.

### Downloads

Other tests, such as the export tests, involve downloads, which are configured to be automatically saved to the `tmp/downloads` directory.
This downloads directory is cleared between every test run (not every individual test).

### Screenshots

Whenever a system test fails, a screenshot is taken at the point of failure, which can be helpful for debugging.
These screenshots are located in the `tmp/screenshots` directory and are not removed between each test run.

