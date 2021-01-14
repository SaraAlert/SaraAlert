---
layout: default
title: Coming Soon
parent: API
nav_order: 2
---

**Below you will find a list of ongoing work that affects the Sara Alert™ API. This page will be updated regularly. If you have any questions on the information here, please email them to our API Help Desk, saraalert-interop@mitre.org. For past release notes, please see [API Release Notes](api-release-notes).**

## Planned for 1.21\*:

- Add important side effects when certain data is modified via the API
  - "Closed at" is set to the current time and "Continuous Exposure" is set to `false` when "Monitoring Status" is changed to "Not Monitoring"
  - "Symptom Onset" is set to the time of the first symptomatic report (if such a report exists) if "Isolation" is set to `false`, or if "Symptom Onset" is deleted
  - Monitorees are added to the "Transferred In" and "Transferred Out" linelist as appropriate when jurisdiction changes
  - History items are created to track the side effects detailed above
- Improved validation error messaging: validation messages will more clearly indicate what value caused the validation error, and where that value is in the JSON document
- Support for Foreign Address (read/write)
- Expanded support for languages

---

\*_This list represents ongoing work. It is subject to change, and the intended release version is not a guarantee_
