Pull requests into Sara Alert require the following. Submitter and reviewer should :white_check_mark: when done. For items that are not-applicable, note it's not-applicable ("N/A") and :white_check_mark:.

Prepend your PR title like `SARAALERT-<Jira number>: <title>`, and include all tickets if the PR covers more than one, e.g. `SARAALERT-1, SARAALERT-2: <title>`. If the PR is not related to a Jira task, just give it a descriptive title.

When assigning a reviewer, tag their GitHub username in the reviewer checklist section below.


# Description
Jira Ticket: [SARAALERT-###](https://tracker.codev.mitre.org/browse/SARAALERT-###)

Write out a concise summary of this pull request and what it addresses.

## (Feature) Demo/Screenshots
Insert demo video or photos for a new or updated feature or capability.

## (Bugfix) How to Replicate
Insert steps for how to replicate the bug this PR addresses.

## (Bugfix) Solution
Insert description for the solution this PR implements to address the bug.

## Important Changes
Please list important files (meaning substantial or integral to the PR) along with a list of the general changes that should be highlighted for reviewers.

`example_file.js`
- Example change (ex: refactored import function)


# Checklists

**Submitter:**
- [ ] This PR describes why these changes were made.
- [ ] This PR is into the correct branch.
- [ ] This PR includes the correct JIRA ticket reference.
- [ ] Code diff has been reviewed (it **does not** contain: additional white space, not applicable code changes, debug statements, etc.)
- [ ] If UI changes have been made, Chrome Dev Tools Lighthouse accessibility test has been executed to ensure no 508 issues were introduced.
- [ ] Tests are included and test edge cases
- [ ] Tests have been run locally and pass (remember to update Gemfile when applicable)
- [ ] Test fixtures updated and documented as necessary


@ :
- [ ] Code is maintainable and reusable, reuses existing code and infrastructure where appropriate, and accomplishes the task’s purpose
- [ ] The tests appropriately test the new code, including edge cases
- [ ] You have tried to break the code
- [ ] If applicable, you have tested changes against a large database, and considered possible performance regressions


@ :
- [ ] Code is maintainable and reusable, reuses existing code and infrastructure where appropriate, and accomplishes the task’s purpose
- [ ] The tests appropriately test the new code, including edge cases
- [ ] You have tried to break the code
- [ ] If applicable, you have tested changes against a large database, and considered possible performance regressions


@ :
- [ ] Code is maintainable and reusable, reuses existing code and infrastructure where appropriate, and accomplishes the task’s purpose
- [ ] The tests appropriately test the new code, including edge cases
- [ ] You have tried to break the code
- [ ] If applicable, you have tested changes against a large database, and considered possible performance regressions
