---
layout: default
title: API
nav_order: 2
has_children: true
has_toc: false
---
<details open markdown="block">
  <summary>
    Table of contents
  </summary>
  {: .text-delta }
1. TOC
{:toc}
</details>

# Introduction
Sara Alert strives to support interoperability standards in public health, and as a result provides a [FHIR](https://www.hl7.org/fhir/overview.html) RESTful API for reading, writing, and updating monitoree data. The data format accepted and returned by the API corresponds to [FHIR version R4](https://hl7.org/fhir/R4/).

The Sara Alert API does this by following SMART on FHIR API [standards and profiles](http://docs.smarthealthit.org/), as described [here](https://smarthealthit.org/smart-on-fhir-api/):
> A key innovation in the SMART on FHIR platform is the use of a standards-based data layer building on the emerging FHIR API and resource definitions. SMART on FHIR, provides a health app interface based on open standards including HL7’s FHIR, OAuth2, and OpenID Connect. FHIR provides a detailed set of “core” data models, but leaves many fields optional and vocabularies under-constrained, in order to support diverse requirements across varied regions and use cases. But to enable substitutable health apps as well as third-party application services, developers need stronger contracts. To this end, SMART on FHIR applies a set of “profiles” that provide developers with expectations about the vocabularies that will be used to express medications, problems, labs, and other clinical data.

Sara Alert also provides an API endpoint for exporting monitorees in the Public Health Document Container (PHDC) format to support interoperability with users of [NBS](https://www.cdc.gov/nbs/index.html). This endpoint does not conform to the FHIR standard, but does follow the same security procedures as the FHIR API described in more detail in the [Getting Started](api-getting-started) page.

This API is intended for use by public health organizations using Sara Alert, and thus Sara  Alert admins maintain a registered list of supported client applications. For access to a live production or demonstration environment, please contact system administrators at `sarasupport@aimsplatform.com` to discuss adding your client application to the approved list.

# Security
As indicated in the previous section, the API follows SMART on FHIR API standards, which includes support for both the [SMART App Launch](http://hl7.org/fhir/smart-app-launch/index.html) and [SMART Backend Services](https://hl7.org/fhir/uv/bulkdata/authorization/index.html) protocols. The SMART App Launch protocol is intended for use by user-facing apps, where access is granted based on a human user entering their existing Sara Alert username and password. The SMART Backend Services protocol is intended for backend services to autonomously use the Sara Alert API and access is granted based on a signed token. Detailed documentation of these two workflows can be found in the [Getting Started](api-getting-started) page.

# What can the Sara Alert™ API do?

The API exists to allow other software systems to **read** and **write** Sara Alert data. Reading can mean either requesting specific data, e.g. "give me Monitoree X's information", or it can mean searching data, e.g. "give me the Monitoree with the e-mail address jane@example<span></span>.com". Writing data can mean putting new data into the system, e.g. "enroll this person as a new Monitoree", or it can mean updating existing data, e.g. "change this Monitoree's preferred reporting method to Opt-Out".

The examples above are in terms of Monitorees, but the API also supports reading/writing of Close Contacts, Vaccinations, and Lab Results and reading of Symptom Reports.

### For Monitorees
**A client can read and write the following data elements:**<br>Workflow, First Name, Middle Name, Last Name, Date of Birth, Sex, White, Black or African American, American Indian or Alaskan Native, Asian, Native Hawaiian or Other Pacific Islander, Ethnicity, Primary Language, Secondary Language, Interpretation Requirement, Address 1, Address 2, Town/City, State, Zip, County, Address 1 (Foreign), Address 2 (Foreign), Address 3 (Foreign), Town/City (Foreign), State/Province (Foreign), Postal Code (Foreign), Country (Foreign), Preferred Reporting Method, Preferred Contact Time, Primary Telephone Number, Secondary Telephone Number, E-mail Address, Last Date of Exposure, Symptom Onset Date, Monitoring Status, Assigned Jurisdiction, Monitoring Plan, Assigned User, Additional Planned Travel Start Date, Additional Planned Travel Notes, Port of Origin, Date of Departure, Flight or Vessel Number, Flight or Vessel Carrier, Date of Arrival, Travel Related Notes, Exposure Notes, Primary Telephone Type, Secondary Telephone Type, State/Local ID, CDC ID, NNDSS ID, Exposure Location, Exposure Country, Risk Assessment, Latest Public Health Action, Extend Isolation To, Follow-up Reason, Follow-up Note

**A client can read (but not write) the following data elements:**<br>End of Monitoring, Eligible for Purge After, Reason for Closure, Address 1 (Monitored), Address 2 (Monitored), Town/City (Monitored), State (Monitored), Zip (Monitored), County (Monitored), Address 1 (Foreign Monitored), Address 2 (Foreign Monitored), Town/City (Foreign Monitored), State (Foreign Monitored), Zip (Foreign Monitored), County (Foreign Monitored), Transfer Created Date, Transfer Updated Date, Transfer From Jurisdiction, Transfer To Jurisdiction, Transfer ID, Who Initiated Transfer, Close Contact with a Known Case, Contact of Known Case ID, Member of a Common Exposure Cohort, Common Exposure Cohort Name, Laboratory Personnel, Laboratory Personnel Facility Name, Health Care Personnel, Health Care Personnel Facility Name, Was in Health Care Facility With Known Cases, Health Care Facility with Known Cases Name, Travel from Affected Country or Area, Crew on Passenger or Cargo Flight, Source of Report, Source of Report Specify, Additional Planned Travel Destination, Additional Planned Travel Destination Country, Additional Planned Travel Destination State, Additional Planned Travel End Date, Additional Planned Travel Port of Departure, Additional Planned Travel Type, Port of Entry Into USA, Case Status, Closed At, Gender Identity, Sexual Orientation, Head of Household, ID of Reporter, Last Assessment Reminder Sent, Paused Notifications, Status, User Defined Symptom Onset

**A client can search by the following data elements:**<br>First Name, Last Name, Primary Telephone Number, E-mail Address, Monitoring Status

### For Close Contacts
**A client can read and write the following data elements:**<br>First Name, Last Name, Primary Telephone, Email, Notes, Enrolled ID, Contact Attempts, Last Date of Exposure, Assigned User, Patient ID

**A client can read (but not write) the following data elements:**<br>Created Date

**A client can search by the following data elements:**<br>ID, Patient ID

### For Vaccinations
**A client can read and write the following data elements:**<br>Vaccine Group, Product Name, Administration Date, Dose Number, Notes, Patient ID

**A client can read (but not write) the following data elements:**<br>Created Date

**A client can search by the following data elements:**<br>ID, Patient ID

### For Histories
**A client can read the following data elements:**<br>Patient ID, Comment, History Type, Created By

**A client can read (but not write) the following data elements:**<br>Deleted By, Delete Reason, Original Comment ID

**A client can search by the following data elements:**<br>ID, Patient ID

### For Symptom Reports
**A client can read the following data elements:**<br>Name, Answer, Patient ID

**A client can read (but not write) the following data elements:**<br>Created Date, Symptomatic, Who Reported

**A client can search by the following data elements:**<br>ID, Patient ID


### For Lab Results
**A client can read and write the following data elements:**<br>Report Date, Specimen Collection Date, Lab Type, Result, Patient ID

**A client can read (but not write) the following data elements:**<br>Created Date

**A client can search by the following data elements:**<br>ID, Patient ID

# Tentative Roadmap
**DISCLAIMER**: This roadmap is **tentative**, meaning we are not making any promises. Future work is subject to change at all times; we can and will modify and prioritize future work based on user needs as they arise.

Below are the items currently planned for future work in the Sara Alert API, in roughly the order which we plan to implement them. Also note that these do not necessarily occur serially; multiple items may be worked in parallel.
1. Expand support for more data elements: Currently the API supports a subset of the data elements supported by the Sara Alert application. We want to get to a place where all or most of those data elements are supported in the API. We are prioritizing these elements based on user needs.
2. Add support for Excel import and CDA PHDC XML export: In order to better support integration with NBS.
3. Improve validation and error reporting: We are always looking to improve data validation and reporting of errors in the API in order to make the system more robust, and to make it easier to test and debug API clients.
4. Improve FHIR compliance: We are also always striving to align the API as closely as possible with the FHIR specification.

For detailed information about what is currently being worked, please see the Coming Soon page [here](api-coming-soon)