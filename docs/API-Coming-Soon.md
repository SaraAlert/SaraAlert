**Below you will find a list of ongoing work that affects the Sara Alert™ API. This page will be updated regularly. If you have any questions on the information here, please email them to our API Help Desk, saraalert-interop@mitre.org. For past release notes, please see [API Release Notes](https://github.com/SaraAlert/SaraAlert/wiki/API-Release-Notes).**

## Planned for 1.18.0* (previously was targeting 1.17):
* Adding support for the following attributes on the Patient resource:
  * Monitoring Plan
    * Validates one of: 'None', 'Daily active monitoring', 'Self-monitoring with public health supervision', 'Self-monitoring with delegated supervision', 'Self-observation'
  * Assigned User
    * Validates in range [1, 9999]
  * Additional Planned Travel Start Date
  * Port of Origin
  * Date of Departure
  * Date of Arrival
  * Flight or Vessel Number
  * Flight or Vessel Carrier
  * Notes
  * Travel Related Notes
  * Additional Planned Travel Notes
  * Primary Phone Type
  * Secondary Phone Type
  * State/Local ID
* Adding a `Patient` PATCH endpoint. This will allow for PATCH style updates in addition to the existing PUT.

***


*_This list represents ongoing work. It is subject to change, and the intended release version is not a guarantee_