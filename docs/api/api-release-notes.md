---
layout: default
title: Release Notes
parent: API
nav_order: 1
---
# 1.36.0
* Add support for bulk export via the API according to the FHIR bulk data [specification](https://hl7.org/fhir/uv/bulkdata/). See the [bulk data export](/api/fhir-api-specification.html#bulk-data-export) section for full details.
* Add support for reading all Sara Alert data elements via the API. See the [list of supported fields](/api/#what-can-the-sara-alert-api-do) for more details. The [FHIR Interface Specification](/api/fhir-api-specification.html) contains additional information about how Sara Alert fields are represented in FHIR.

***
# 1.32.0
* Support for writing Lab Results via a FHIR Observation.
* Support for writing Monitorees and Lab Results in bulk via a FHIR transaction Bundle. This will allow for Monitorees to be enrolled alongside their Lab Results, which will enable support for asymptomatic enrollment of Monitorees in the Isolation workflow.
* Support for reading History via a FHIR Provenance.

***
# 1.29.0
*  Support for bulk export of Public Health Document Container (PHDC) representations of Monitorees via an API endpoint. The Monitorees to export can be filtered by Workflow, Case Status, Monitoring Status, and date most recently updated. See the [NBS documentation](nbs-api-specification) for more details.
* More strict validation validation of the `communication.language` field on the FHIR Patient Resource. The `communication.language.coding.code` must now be a 2-letter ISO 639-1 code (for example, “en” for “English”) or a 3-letter ISO 639-2 code (for example, “ace” for “Achinese”). See the [Sara Alert Language ValueSet](https://saraalert.github.io/saraalert-fhir-ig/ValueSet-SaraAlertLanguage.html) for a full list of allowed codes.

***

# 1.28.0
* Support for reading and writing Vaccines via a FHIR Immunization.
* Improve performance of search, especially when searching FHIR Patients.

***
# 1.27.0
* Improved validation error messaging: validation messages will more clearly indicate what value caused the validation error, and where that value is in the JSON document

***

# 1.26.0
* Support for Close Contacts (read/write) via a FHIR RelatedPerson

***

# 1.24.0
* Support for Continuous Exposure

***

# 1.23.0
* Support for Foreign Address (read/write)

***

# 1.22.0
* Add important side effects when certain data is modified via the API
  * "Closed at" is set to the current time and "Continuous Exposure" is set to `false` when "Monitoring Status" is changed to "Not Monitoring"
  * "Symptom Onset" is set to the time of the first symptomatic report (if such a report exists) if "Isolation" is set to `false`, or if "Symptom Onset" is deleted
  * Transfers are handled correctly when jurisdiction changes
  * History items are created to track the side effects detailed above

***

# 1.20.0
* Fixed a bug which prevented multiple races from being set at once via the [race](https://www.hl7.org/fhir/us/core/StructureDefinition-us-core-race.html) extension

***

# 1.18.1
* Added support for the following attributes on the Patient resource:
  * **Monitoring Plan**
    * Validates one of: 'None', 'Daily active monitoring', 'Self-monitoring with public health supervision', 'Self-monitoring with delegated supervision', 'Self-observation'
  * **Assigned User**
    * Validates in range [1, 999999]
  * **Additional Planned Travel Start Date**
  * **Port of Origin**
  * **Date of Departure**
  * **Date of Arrival**
  * **Flight or Vessel Number**
  * **Flight or Vessel Carrier**
  * **Notes**
  * **Travel Related Notes**
  * **Additional Planned Travel Notes**
  * **Primary Phone Type**
    * Validates one of: 'Smartphone', 'Plain Cell', 'Landline'
  * **Secondary Phone Type**
    * Validates one of: 'Smartphone', 'Plain Cell', 'Landline'
  * **State/Local ID**
    * Expressed as a `Patient.identifier`, where `Identifier.system` is equal to `http://saraalert.org/SaraAlert/state-local-id`, and `Identifier.value` is set to the State/Local ID.
* Added a `Patient` PATCH endpoint. This allows for PATCH style updates with JSON Patch in addition to the existing PUT.
* Added a check for JSON validity in POST and PUT endpoints. The service will now return a 400 error in the event of invalid JSON.

***

# 1.16.0
* The following data elements are now required on the Patient resource:
  * **State**, **Date of Birth**, **First Name**, **Last Name** are always required
  * **Symptom Onset** is required if **Isolation** is true (Monitoree is in the Isolation Workflow)
  * **Last Date of Exposure** is required if **Isolation** is false (Monitoree is in the Exposure Workflow)
  * **Email** is required if **Preferred Contact Method** is ‘E-mailed Web Link’
  * **Primary Phone Number** is required if **Preferred Contact Method** is any of 'SMS Texted Weblink', 'Telephone call', or 'SMS Text-message'
* The following validations are also now enforced on the Patient resource:
  * **State** is a valid state name, with proper capitalization.
  * **Ethnicity** is one of: 'Not Hispanic or Latino', 'Hispanic or Latino'
  * **Preferred Contact Method** is one of: 'E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message', 'Opt-out', 'Unknown'
  * **Preferred Contact Time** is one of: ‘Morning’, ‘Afternoon’, ‘Evening’
  * **Sex** is one of: ‘Male’, ‘Female’, ‘Unknown’
  * **Primary Telephone** and **Secondary Telephone** are valid phone numbers
  * **Date of Birth** is a valid date between 1/1/1900 and the current day
  * **Last Date of Exposure**, and **Symptom Onset** are valid dates between 1/1/2020 and 30 days from the current day
  * **Email** is a valid email address
* If any of the above validations fail, the API will now respond with a 422 error (Unprocessible Entity), and include specific validation error messages
* **Full Assigned Jurisdiction Path** is now supported on the Patient resource in the API. It is a string field extension, and values are expected exactly as they are in the Sara Alert format import. Here is an example of what this extension looks like in JSON:

      {
        “extension”: [
          {
            "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
            "valueString": "USA, State 1"
          }
        ]
      }
  Acceptable values for `valueString` are the same as what is accepted for Full Assigned Jurisdiction Path in the Sara Alert™ Import Format.  For full documentation of the Sara Alert™ Import Format, please see section 9.1.5 of the [Sara Alert™ User Guide](https://saraalert.org/wp-content/uploads/2020/10/Sara-Alert-User-Guide-v1.15.pdf).

***

**Please email saraalert-interop@mitre.org with any questions or feedback you may have.**