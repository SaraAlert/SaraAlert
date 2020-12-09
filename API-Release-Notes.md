1.16.0
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