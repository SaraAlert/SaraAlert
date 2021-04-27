# Migration Tests

These tests are not included to be run with every `rails test`. Specifically run these tests one-at-a-time with `rails test test/migrations/{filename}` syntax.

## Structure of the Test

Must call `super` in the `setup` and `teardown` methods.

The recommended structure is to have a `test_full_migration` method. This method needs to have a call to `rollback_to_previous_of!` and `upgrade_to!`.

Before the rollback, populate the database with factories. Call the rollback method. Assert that the data got rolled back into the correct form. Now, call the upgrade method. Assert that the data is **returned to the same form it started in**.

Quick Tips:

* Use `require_migration!` to load the actual migration file to test any methods you may have outside of a full migration test.
* You can reference the `Migration` object itself with `@migration` in the tests.
* Name the migration test file the same name as the migration without the timestamp followed by _test.
* In the `setup` method `destroy_all` any data for Models that are being migrated.
