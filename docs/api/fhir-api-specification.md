---
layout: default
title: FHIR Interface Specification
parent: API
nav_order: 4
---
<details open markdown="block">
  <summary>
    Table of contents
  </summary>
  {: .text-delta }
1. TOC
{:toc}
</details>

# FHIR API Specification

For the purposes of this documentation, when describing an API route, [base] includes `/fhir/r4`.
JSON is currently the only supported format. Please make use of the `application/fhir+json` mime type for the Accept header. When using a POST or PUT endpoint, please also use `application/fhir+json` for the Content-Type header, and when using a PATCH endpoint, please use `application/json-patch+json`.

<a name="data-representation"/>

### Data Representation
Because the Sara Alert API follows the FHIR specification, there is a mapping between known kinds of Sara Alert data and their associated FHIR resources.

| Sara Alert                | FHIR Resource |
| :---------------          | :------------ |
| Monitoree                 | [Patient](https://hl7.org/fhir/R4/patient.html)|
| Monitoree Lab Result      | [Observation](https://hl7.org/fhir/R4/observation.html)|
| Monitoree Daily Report    | [QuestionnaireResponse](https://www.hl7.org/fhir/questionnaireresponse.html)|
| Monitoree Close Contact   | [RelatedPerson](https://www.hl7.org/fhir/relatedperson.html)|
| Monitoree Immunization    | [Immunization](https://www.hl7.org/fhir/immunization.html)|
| Monitoree History         | [Provenance](https://hl7.org/fhir/provenance.html)|

<a name="supported-scopes"/>

## Supported Scopes
For applications following the [SMART-on-FHIR App Launch Framework "Standalone Launch" Workflow](#standalone-launch), these are the available scopes:

* `user/Patient.read`
* `user/Patient.write`
* `user/Patient.*` (for both read and write access to this resource)
* `user/Observation.read`
* `user/QuestionnaireResponse.read`
* `user/RelatedPerson.read`
* `user/RelatedPerson.write`
* `user/RelatedPerson.*`
* `user/Immunization.read`
* `user/Immunization.write`
* `user/Immunization.*`,
* `user/Provenance.read`

For applications following the [SMART on FHIR Backend Services Workflow](#backend-services), these are the available scopes:

* `system/Patient.read`
* `system/Patient.write`
* `system/Patient.*` (for both read and write access to this resource)
* `system/Observation.read`
* `system/Observation.write`
* `system/Observation.*`
* `system/QuestionnaireResponse.read`
* `system/RelatedPerson.read`
* `system/RelatedPerson.write`
* `system/RelatedPerson.*`
* `system/Immunization.read`
* `system/Immunization.write`
* `system/Immunization.*`
* `system/Provenance.read`

Please note a given application and request for access token can have have multiple scopes, which must be space-separated. For example:
```
user/Patient.read system/Patient.read system/Observation.read
```

<a name="cap"/>

## CapabilityStatement and Well-Known Uniform Resource Identifiers

<a name="cap-get"/>

A capability statement is available at `[base]/metadata`:

### GET `[base]/metadata`

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "status": "active",
  "date": "2021-05-04T00:00:00+00:00",
  "kind": "instance",
  "software": {
    "name": "Sara Alert",
    "version": "v1.30"
  },
  "implementation": {
    "description": "Sara Alert API"
  },
  "fhirVersion": "4.0.1",
  "format": ["json"],
  "rest": [
    {
      "mode": "server",
      "security": {
        "extension": [
          {
            "extension": [
              {
                "url": "token",
                "valueUri": "http://localhost:3000/oauth/token"
              },
              {
                "url": "authorize",
                "valueUri": "http://localhost:3000/oauth/authorize"
              },
              {
                "url": "introspect",
                "valueUri": "http://localhost:3000/oauth/introspect"
              },
              {
                "url": "revoke",
                "valueUri": "http://localhost:3000/oauth/revoke"
              }
            ],
            "url": "http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris"
          }
        ],
        "cors": true,
        "service": [
          {
            "coding": [
              {
                "system": "http://hl7.org/fhir/restful-security-service",
                "code": "SMART-on-FHIR"
              }
            ],
            "text": "OAuth2 using SMART-on-FHIR profile (see http://docs.smarthealthit.org)"
          }
        ]
      },
      "resource": [
        {
          "type": "Patient",
          "interaction": [
            {
              "code": "read"
            },
            {
              "code": "update"
            },
            {
              "code": "patch"
            },
            {
              "code": "create"
            },
            {
              "code": "search-type"
            }
          ],
          "searchParam": [
            {
              "name": "family",
              "type": "string"
            },
            {
              "name": "given",
              "type": "string"
            },
            {
              "name": "telecom",
              "type": "string"
            },
            {
              "name": "email",
              "type": "string"
            },
            {
              "name": "active",
              "type": "boolean"
            },
            {
              "name": "_id",
              "type": "string"
            },
            {
              "name": "_count",
              "type": "string"
            }
          ]
        },
        {
          "type": "RelatedPerson",
          "interaction": [
            {
              "code": "read"
            },
            {
              "code": "update"
            },
            {
              "code": "patch"
            },
            {
              "code": "create"
            },
            {
              "code": "search-type"
            }
          ],
          "searchParam": [
            {
              "name": "patient",
              "type": "reference"
            },
            {
              "name": "_id",
              "type": "string"
            },
            {
              "name": "_count",
              "type": "string"
            }
          ]
        },
        {
          "type": "Immunization",
          "interaction": [
            {
              "code": "read"
            },
            {
              "code": "update"
            },
            {
              "code": "patch"
            },
            {
              "code": "create"
            },
            {
              "code": "search-type"
            }
          ],
          "searchParam": [
            {
              "name": "patient",
              "type": "reference"
            },
            {
              "name": "_id",
              "type": "string"
            },
            {
              "name": "_count",
              "type": "string"
            }
          ]
        },
        {
          "type": "Provenance",
          "interaction": [
            {
              "code": "read"
            },
            {
              "code": "search-type"
            }
          ],
          "searchParam": [
            {
              "name": "patient",
              "type": "reference"
            },
            {
              "name": "_id",
              "type": "string"
            },
            {
              "name": "_count",
              "type": "string"
            }
          ]
        },
        {
          "type": "Observation",
          "interaction": [
            {
              "code": "read"
            },
            {
              "code": "update"
            },
            {
              "code": "patch"
            },
            {
              "code": "create"
            },
            {
              "code": "search-type"
            }
          ],
          "searchParam": [
            {
              "name": "subject",
              "type": "reference"
            },
            {
              "name": "_id",
              "type": "string"
            },
            {
              "name": "_count",
              "type": "string"
            }
          ]
        },
        {
          "type": "QuestionnaireResponse",
          "interaction": [
            {
              "code": "read"
            },
            {
              "code": "search-type"
            }
          ],
          "searchParam": [
            {
              "name": "subject",
              "type": "reference"
            },
            {
              "name": "_id",
              "type": "string"
            },
            {
              "name": "_count",
              "type": "string"
            }
          ]
        }
      ]
    }
  ],
  "resourceType": "CapabilityStatement"
}

```
  </div>
</details>

<a name="wk-get"/>

A Well Known statement is also available at `/.well-known/smart-configuration` or `[base]/.well-known/smart-configuration`:

### GET `[base]/.well-known/smart-configuration`

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "authorization_endpoint": "http://localhost:3000/oauth/authorize",
  "token_endpoint": "http://localhost:3000/oauth/token",
  "token_endpoint_auth_methods_supported": [
    "client_secret_basic",
    "private_key_jwt"
  ],
  "token_endpoint_auth_signing_alg_values_supported": ["RS384"],
  "introspection_endpoint": "http://localhost:3000/oauth/introspect",
  "revocation_endpoint": "http://localhost:3000/oauth/revoke",
  "scopes_supported": [
    "user/Patient.read",
    "user/Patient.write",
    "user/Patient.*",
    "user/Observation.read",
    "user/Observation.*",
    "user/QuestionnaireResponse.read",
    "user/RelatedPerson.read",
    "user/RelatedPerson.write",
    "user/RelatedPerson.*",
    "user/Immunization.read",
    "user/Immunization.write",
    "user/Immunization.*",
    "user/Provenance.read",
    "system/Patient.read",
    "system/Patient.write",
    "system/Patient.*",
    "system/Observation.read",
    "system/Observation.*",
    "system/QuestionnaireResponse.read",
    "system/RelatedPerson.read",
    "system/RelatedPerson.write",
    "system/RelatedPerson.*",
    "system/Immunization.read",
    "system/Immunization.write",
    "system/Immunization.*",
    "system/Provenance.read"
  ],
  "capabilities": ["launch-standalone"]
}

```
  </div>
</details>

<a name="read"/>

## Reading

The API supports reading monitorees, monitoree lab results, monitoree daily reports, monitoree close contacts, and monitoree vaccinations.

<a name="read-get-pat"/>

### GET `[base]/Patient/[:id]`

Get a monitoree via an id, e.g.:

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "id": 43,
  "meta": {
    "lastUpdated": "2021-07-27T15:31:08+00:00"
  },
  "contained": [
    {
      "target": [
        {
          "reference": "/fhir/r4/Patient/43"
        }
      ],
      "recorded": "2021-06-23T09:03:19+00:00",
      "activity": {
        "coding": [
          {
            "system": "http://terminology.hl7.org/CodeSystem/v3-DataOperation",
            "code": "CREATE",
            "display": "create"
          }
        ]
      },
      "agent": [
        {
          "who": {
            "identifier": {
              "value": 6
            },
            "display": "locals2c4_enroller@example.com"
          }
        }
      ],
      "resourceType": "Provenance"
    }
  ],
  "extension": [
    {
      "extension": [
        {
          "url": "ombCategory",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "2106-3",
            "display": "White"
          }
        },
        {
          "url": "ombCategory",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "1002-5",
            "display": "American Indian or Alaska Native"
          }
        },
        {
          "url": "ombCategory",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "2076-8",
            "display": "Native Hawaiian or Other Pacific Islander"
          }
        },
        {
          "url": "detailed",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "2131-1",
            "display": "Other Race"
          }
        },
        {
          "url": "text",
          "valueString": "White, American Indian or Alaska Native, Native Hawaiian or Other Pacific Islander, Other"
        }
      ],
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race"
    },
    {
      "extension": [
        {
          "url": "ombCategory",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "2186-5",
            "display": "Not Hispanic or Latino"
          }
        },
        {
          "url": "text",
          "valueString": "Not Hispanic or Latino"
        }
      ],
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity"
    },
    {
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex",
      "valueCode": "M"
    },
    {
      "extension": [
        {
          "url": "id",
          "valuePositiveInt": 18
        },
        {
          "url": "updated-at",
          "valueDateTime": "2021-06-26T11:12:46+00:00"
        },
        {
          "url": "created-at",
          "valueDateTime": "2021-06-26T11:12:46+00:00"
        },
        {
          "url": "who-initiated-transfer",
          "valueString": "state1_epi@example.com"
        },
        {
          "url": "from-jurisdiction",
          "valueString": "USA, State 1, County 1"
        },
        {
          "url": "to-jurisdiction",
          "valueString": "USA, State 2"
        }
      ],
      "url": "http://saraalert.org/StructureDefinition/transfer"
    },
    {
      "extension": [
        {
          "url": "id",
          "valuePositiveInt": 211
        },
        {
          "url": "updated-at",
          "valueDateTime": "2021-07-04T19:11:57+00:00"
        },
        {
          "url": "created-at",
          "valueDateTime": "2021-07-04T19:11:57+00:00"
        },
        {
          "url": "who-initiated-transfer",
          "valueString": "state2_epi@example.com"
        },
        {
          "url": "from-jurisdiction",
          "valueString": "USA, State 2"
        },
        {
          "url": "to-jurisdiction",
          "valueString": "USA, State 1"
        }
      ],
      "url": "http://saraalert.org/StructureDefinition/transfer"
    },
    {
      "extension": [
        {
          "extension": [
            {
              "url": "contact-of-known-case",
              "valueBoolean": true
            },
            {
              "url": "contact-of-known-case-id",
              "valueString": "00929074, 01304440, 00162388"
            }
          ],
          "url": "http://saraalert.org/StructureDefinition/contact-of-known-case"
        },
        {
          "extension": [
            {
              "url": "was-in-health-care-facility-with-known-cases",
              "valueBoolean": true
            },
            {
              "url": "was-in-health-care-facility-with-known-cases-facility-name",
              "valueString": "Facility123"
            }
          ],
          "url": "http://saraalert.org/StructureDefinition/was-in-health-care-facility-with-known-cases"
        },
        {
          "extension": [
            {
              "url": "laboratory-personnel",
              "valueBoolean": true
            },
            {
              "url": "laboratory-personnel-facility-name",
              "valueString": "Facility123"
            }
          ],
          "url": "http://saraalert.org/StructureDefinition/laboratory-personnel"
        },
        {
          "extension": [
            {
              "url": "healthcare-personnel",
              "valueBoolean": true
            },
            {
              "url": "healthcare-personnel-facility-name",
              "valueString": "Facility123"
            }
          ],
          "url": "http://saraalert.org/StructureDefinition/healthcare-personnel"
        },
        {
          "extension": [
            {
              "url": "member-of-a-common-exposure-cohort",
              "valueBoolean": true
            },
            {
              "url": "member-of-a-common-exposure-cohort-type",
              "valueString": "Cruiseline cohort"
            }
          ],
          "url": "http://saraalert.org/StructureDefinition/member-of-a-common-exposure-cohort"
        },
        {
          "url": "http://saraalert.org/StructureDefinition/travel-from-affected-country-or-area",
          "valueBoolean": false
        },
        {
          "url": "http://saraalert.org/StructureDefinition/crew-on-passenger-or-cargo-flight",
          "valueBoolean": false
        }
      ],
      "url": "http://saraalert.org/StructureDefinition/exposure-risk-factors"
    },
    {
      "extension": [
        {
          "url": "source-of-report",
          "valueString": "Surveillance Screening"
        }
      ],
      "url": "http://saraalert.org/StructureDefinition/source-of-report"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/preferred-contact-method",
      "valueString": "E-mailed Web Link"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/symptom-onset-date",
      "valueDate": "2021-06-24"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/isolation",
      "valueBoolean": false
    },
    {
      "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
      "valueString": "USA, State 1"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/monitoring-plan",
      "valueString": "Daily active monitoring"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/assigned-user",
      "valuePositiveInt": 1234
    },
    {
      "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-start-date",
      "valueDate": "2021-06-24"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-end-date",
      "valueDate": "2021-06-25"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/port-of-origin",
      "valueString": "New Charleyhaven"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/port-of-entry-into-usa",
      "valueString": "South Anamaria"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/date-of-departure",
      "valueDate": "2021-06-23"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/flight-or-vessel-number",
      "valueString": "V595"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/flight-or-vessel-carrier",
      "valueString": "Clora Airlines"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/date-of-arrival",
      "valueDate": "2021-06-23"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/travel-related-notes",
      "valueString": "Pleasure in the job puts perfection in the work."
    },
    {
      "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-notes",
      "valueString": "Chuck Norris hosting is 101% uptime guaranteed."
    },
    {
      "url": "http://saraalert.org/StructureDefinition/continuous-exposure",
      "valueBoolean": false
    },
    {
      "url": "http://saraalert.org/StructureDefinition/end-of-monitoring",
      "valueString": "2021-07-07"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/expected-purge-date",
      "valueDateTime": "2021-08-10T15:31:08+00:00"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/exposure-risk-assessment",
      "valueString": "No Identified Risk"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/public-health-action",
      "valueString": "None"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/potential-exposure-location",
      "valueString": "Arronton"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/potential-exposure-country",
      "valueString": "Brazil"
    },
    {
      "url": "http://hl7.org/fhir/StructureDefinition/patient-interpreterRequired",
      "valueBoolean": false
    },
    {
      "url": "http://saraalert.org/StructureDefinition/reason-for-closure",
      "valueString": "Meets Case Definition"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-destination",
      "valueString": "Pourosside"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-destination-state",
      "valueString": "District of Columbia"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-port-of-departure",
      "valueString": "New Natalia"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-type",
      "valueString": "Domestic"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/case-status",
      "valueString": "Confirmed"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/closed-at",
      "valueDateTime": "2021-07-27T15:29:34+00:00"
    },
    {
      "url": "http://hl7.org/fhir/StructureDefinition/patient-genderIdentity",
      "valueCodeableConcept": {
        "coding": [
          {
            "system": "http://hl7.org/fhir/gender-identity",
            "code": "transgender-female"
          }
        ],
        "text": "Transgender Female (Male-to-Female [MTF])"
      }
    },
    {
      "url": "http://saraalert.org/StructureDefinition/head-of-household",
      "valueBoolean": true
    },
    {
      "url": "http://saraalert.org/StructureDefinition/id-of-reporter",
      "valuePositiveInt": 43
    },
    {
      "url": "http://saraalert.org/StructureDefinition/last-assessment-reminder-sent",
      "valueDateTime": "2021-06-20T04:00:00+00:00"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/paused-notifications",
      "valueBoolean": false
    },
    {
      "url": "http://saraalert.org/StructureDefinition/status",
      "valueString": "closed"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/user-defined-symptom-onset",
      "valueBoolean": false
    }
  ],
  "identifier": [
    {
      "system": "http://saraalert.org/SaraAlert/cdc-id",
      "value": "0952379687"
    }
  ],
  "active": false,
  "name": [
    {
      "family": "Johns78",
      "given": ["Gerardo58", "Reinger57"]
    }
  ],
  "telecom": [
    {
      "system": "email",
      "value": "3822316898fake@example.com",
      "rank": 1
    }
  ],
  "birthDate": "1981-10-15",
  "address": [
    {
      "line": ["8181 Diana Lodge"],
      "district": "Royal Creek",
      "state": "New Jersey",
      "postalCode": "94336"
    },
    {
      "extension": [
        {
          "url": "http://saraalert.org/StructureDefinition/address-type",
          "valueString": "Monitored"
        }
      ],
      "line": ["8181 Diana Lodge"],
      "district": "Royal Creek",
      "state": "New Jersey",
      "postalCode": "94336"
    }
  ],
  "communication": [
    {
      "language": {
        "coding": [
          {
            "system": "urn:ietf:bcp:47",
            "code": "en",
            "display": "English"
          }
        ]
      },
      "preferred": true
    },
    {
      "language": {
        "coding": [
          {
            "system": "urn:ietf:bcp:47",
            "code": "bho",
            "display": "Bhojpuri"
          }
        ]
      },
      "preferred": false
    }
  ],
  "resourceType": "Patient"
}
```
  </div>
</details>

#### Read-Only Patient Extensions

The `http://saraalert.org/StructureDefinition/end-of-monitoring` extension represents the system calculated end of monitoring period. This field is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/end-of-monitoring",
  "valueDate": "2021-06-15"
}
```

The `http://saraalert.org/StructureDefinition/expected-purge-date` extension represents the date and time that the monitoree's identifiers will be eligible to be purged from the system. This field is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/expected-purge-date",
  "valueDateTime": "2021-06-29T21:04:08+00:00"
}
```

The `http://saraalert.org/StructureDefinition/reason-for-closure` extension represents the reason a monitoree was closed by the user or system. This field is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/reason-for-closure",
  "valueString": "Completed Monitoring"
}
```

The `http://saraalert.org/StructureDefinition/additional-planned-travel-end-date` extension represents the end date for a monitoree's additional planned travel. This field is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-end-date",
  "valueDate": "2021-06-25"
}
```

The `http://saraalert.org/StructureDefinition/additional-planned-travel-destination` extension represents the destination for a monitoree's additional planned travel. This field is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-destination",
  "valueString": "Pourosside"
}
```


The `http://saraalert.org/StructureDefinition/additional-planned-travel-destination-state` extension represents the destination state for a monitoree's additional planned travel. This field is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-destination-state",
  "valueString": "District of Columbia"
}
```

The `http://saraalert.org/StructureDefinition/additional-planned-travel-destination-country` extension represents the destination country for a monitoree's additional planned travel. This field is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-destination-country",
  "valueString": "Albania"
}
```

The `http://saraalert.org/StructureDefinition/additional-planned-travel-port-of-departure` extension represents the port of departure for a monitoree's additional planned travel. This field is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-port-of-departure",
  "valueString": "New Natalia"
}
```

The `http://saraalert.org/StructureDefinition/additional-planned-travel-type` extension represents the type of a monitoree's additional planned travel. This field is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-type",
  "valueString": "International"
}
```

The `http://saraalert.org/StructureDefinition/case-status` extension represents the case status of a monitoree. This field is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/case-status",
  "valueString": "Confirmed"
}
```

The `http://saraalert.org/StructureDefinition/closed-at` extension represents the time at which a monitoree was closed. This field is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/closed-at",
  "valueDateTime": "2021-07-07T18:10:47+00:00"
}
```

The `http://hl7.org/fhir/StructureDefinition/patient-genderIdentity` extension represents the gender identity of a monitoree. This field is read-only.
```json
{
  "url": "http://hl7.org/fhir/StructureDefinition/patient-genderIdentity",
  "valueCodeableConcept": {
    "coding": [
      {
        "system": "http://hl7.org/fhir/gender-identity",
        "code": "transgender-female"
      }
    ],
    "text": "Transgender Female (Male-to-Female [MTF])"
  }
}
```

The `http://saraalert.org/StructureDefinition/sexual-orientation` extension represents the sexual orientation of a monitoree. This field is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/sexual-orientation",
  "valueCodeableConcept": {
    "coding": [
      {
        "system": "http://snomed.info/sct",
        "code": "38628009"
      }
    ],
    "text": "Lesbian, Gay, or Homosexual"
  }
}
```

The `http://saraalert.org/StructureDefinition/head-of-household` extension represents whether the monitoree is the head of a household. This field is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/head-of-household",
  "valueBoolean": true
}
```

The `http://saraalert.org/StructureDefinition/id-of-reporter` extension represents the ID of the monitoree responsible for reporting for this monitoree. If the monitoree is responsible for their own reporting, this will just be the monitoree's ID. This field is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/id-of-reporter",
  "valuePositiveInt": 43
}
```

The `http://saraalert.org/StructureDefinition/last-assessment-reminder-sent` extension indicates the time at which the monitoree was last sent an assessment reminder. This field is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/last-assessment-reminder-sent",
  "valueDateTime": "2021-06-20T04:00:00+00:00"
}
```

The `http://saraalert.org/StructureDefinition/paused-notifications` extension represents whether notifications to the monitoree are paused. This field is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/paused-notifications",
  "valueBoolean": false
}
```

The `http://saraalert.org/StructureDefinition/status` extension represents the current status of the monitoree. This field is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/status",
  "valueString": "symptomatic"
}
```

The `http://saraalert.org/StructureDefinition/user-defined-symptom-onset` extension indicates whether the symptom onset for this monitoree is user defined. This field is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/user-defined-symptom-onset",
  "valueBoolean": false
}
```

The complex `http://saraalert.org/StructureDefinition/transfer` extension represents a transfer that occurred for the monitoree. This field is read-only.
```json
{
  "extension": [
    {
      "url": "id",
      "valuePositiveInt": 18
    },
    {
      "url": "updated-at",
      "valueDateTime": "2021-06-26T11:12:46+00:00"
    },
    {
      "url": "created-at",
      "valueDateTime": "2021-06-26T11:12:46+00:00"
    },
    {
      "url": "who-initiated-transfer",
      "valueString": "state1_epi@example.com"
    },
    {
      "url": "from-jurisdiction",
      "valueString": "USA, State 1, County 1"
    },
    {
      "url": "to-jurisdiction",
      "valueString": "USA, State 2"
    }
  ],
  "url": "http://saraalert.org/StructureDefinition/transfer"
}
```

The complex `http://saraalert.org/StructureDefinition/exposure-risk-factors` extension represents the exposure risk factors that apply for the monitoree. This field is read-only.
```json
{
  "extension": [
    {
      "extension": [
        {
          "url": "contact-of-known-case",
          "valueBoolean": true
        },
        {
          "url": "contact-of-known-case-id",
          "valueString": "00929074, 01304440, 00162388"
        }
      ],
      "url": "http://saraalert.org/StructureDefinition/contact-of-known-case"
    },
    {
      "extension": [
        {
          "url": "was-in-health-care-facility-with-known-cases",
          "valueBoolean": true
        },
        {
          "url": "was-in-health-care-facility-with-known-cases-facility-name",
          "valueString": "Facility123"
        }
      ],
      "url": "http://saraalert.org/StructureDefinition/was-in-health-care-facility-with-known-cases"
    },
    {
      "extension": [
        {
          "url": "laboratory-personnel",
          "valueBoolean": true
        },
        {
          "url": "laboratory-personnel-facility-name",
          "valueString": "Facility123"
        }
      ],
      "url": "http://saraalert.org/StructureDefinition/laboratory-personnel"
    },
    {
      "extension": [
        {
          "url": "healthcare-personnel",
          "valueBoolean": true
        },
        {
          "url": "healthcare-personnel-facility-name",
          "valueString": "Facility123"
        }
      ],
      "url": "http://saraalert.org/StructureDefinition/healthcare-personnel"
    },
    {
      "extension": [
        {
          "url": "member-of-a-common-exposure-cohort",
          "valueBoolean": true
        },
        {
          "url": "member-of-a-common-exposure-cohort-type",
          "valueString": "Cruiseline cohort"
        }
      ],
      "url": "http://saraalert.org/StructureDefinition/member-of-a-common-exposure-cohort"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/travel-from-affected-country-or-area",
      "valueBoolean": false
    },
    {
      "url": "http://saraalert.org/StructureDefinition/crew-on-passenger-or-cargo-flight",
      "valueBoolean": false
    }
  ],
  "url": "http://saraalert.org/StructureDefinition/exposure-risk-factors"
}
```

The complex `http://saraalert.org/StructureDefinition/source-of-report` extension represents the source of the report for a monitoree's arrival information. This field is read-only.
```json
{
  "extension": [
    {
      "url": "source-of-report",
      "valueString": "Other"
    },
    {
      "url": "specify",
      "valueString": "Pipey"
    }
  ],
  "url": "http://saraalert.org/StructureDefinition/source-of-report"
}
```



<a name="read-get-obs"/>

### GET `[base]/Observation/[:id]`

Get a monitoree lab result via an id, e.g.:

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "id": 34,
  "meta": {
    "lastUpdated": "2021-06-23T13:25:48+00:00"
  },
  "extension": [
    {
      "url": "http://saraalert.org/StructureDefinition/created-at",
      "valueDateTime": "2021-06-23T13:25:48+00:00"
    }
  ],
  "status": "final",
  "category": [
    {
      "coding": [
        {
          "system": "http://terminology.hl7.org/CodeSystem/observation-category",
          "code": "laboratory"
        }
      ]
    }
  ],
  "code": {
    "coding": [
      {
        "system": "http://terminology.hl7.org/CodeSystem/v3-NullFlavor",
        "code": "OTH"
      }
    ],
    "text": "Other"
  },
  "subject": {
    "reference": "Patient/12"
  },
  "effectiveDateTime": "2021-06-19",
  "issued": "2021-06-23T00:00:00+00:00",
  "valueCodeableConcept": {
    "coding": [
      {
        "system": "http://snomed.info/sct",
        "code": "10828004"
      }
    ],
    "text": "positive"
  },
  "resourceType": "Observation"
}
```
  </div>
</details>

#### Read-Only Observation Extensions

The `http://saraalert.org/StructureDefinition/created-at` extension indicates the time at which the laboratory was created. This extension is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/created-at",
  "valueDateTime": "2021-06-23T23:34:35+00:00"
}
```


<a name="read-get-que"/>

### GET `[base]/QuestionnaireResponse/[:id]`

Get a monitoree daily report via an id, e.g.:

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "id": 1,
  "meta": {
    "lastUpdated": "2021-06-27T20:51:51+00:00"
  },
  "extension": [
    {
      "url": "http://saraalert.org/StructureDefinition/symptomatic",
      "valueBoolean": false
    },
    {
      "url": "http://saraalert.org/StructureDefinition/created-at",
      "valueDateTime": "2021-06-23T13:34:09+00:00"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/who-reported",
      "valueString": "Monitoree"
    }
  ],
  "status": "completed",
  "subject": {
    "reference": "Patient/20"
  },
  "item": [
    {
      "linkId": "0",
      "text": "cough",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "1",
      "text": "difficulty-breathing",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "2",
      "text": "new-loss-of-smell",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "3",
      "text": "new-loss-of-taste",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "4",
      "text": "shortness-of-breath",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "5",
      "text": "fever",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "6",
      "text": "used-a-fever-reducer",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "7",
      "text": "chills",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "8",
      "text": "repeated-shaking-with-chills",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "9",
      "text": "muscle-pain",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "10",
      "text": "headache",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "11",
      "text": "sore-throat",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "12",
      "text": "nausea-or-vomiting",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "13",
      "text": "diarrhea",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "14",
      "text": "fatigue",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    },
    {
      "linkId": "15",
      "text": "congestion-or-runny-nose",
      "answer": [
        {
          "valueBoolean": false
        }
      ]
    }
  ],
  "resourceType": "QuestionnaireResponse"
}

```
  </div>
</details>

#### Read-Only QuestionnaireResponse Extensions

The `http://saraalert.org/StructureDefinition/created-at` extension indicates the time at which the assessment was created. This extension is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/created-at",
  "valueDateTime": "2021-06-23T23:34:35+00:00"
}
```

The `http://saraalert.org/StructureDefinition/symptomatic` extension indicates whether an assessment indicates a symptomatic monitoree. This extension is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/symptomatic",
  "valueBoolean": true
}
```

The `http://saraalert.org/StructureDefinition/who-reported` extension indicates who reported the assessment. This extension is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/who-reported",
  "valueString": "epi_enroller_all@example.com"
}
```

<a name="read-get-related"/>

### GET `[base]/RelatedPerson/[:id]`

Get a monitoree close contact via an id, e.g.:

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "id": 1,
  "meta": {
    "lastUpdated": "2021-06-23T23:34:35+00:00"
  },
  "extension": [
    {
      "url": "http://saraalert.org/StructureDefinition/notes",
      "valueString": "Try to back up the EXE alarm, maybe it will override the virtual interface!"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/enrolled-patient",
      "valueReference": {
        "reference": "Patient/9"
      }
    },
    {
      "url": "http://saraalert.org/StructureDefinition/created-at",
      "valueDateTime": "2021-06-23T23:34:35+00:00"
    }
  ],
  "patient": {
    "reference": "Patient/23"
  },
  "name": [
    {
      "family": "Marvin72",
      "given": ["Chris91"]
    }
  ],
  "telecom": [
    {
      "system": "phone",
      "value": "+15555550110",
      "rank": 1
    },
    {
      "system": "email",
      "value": "3068326388fake@example.com",
      "rank": 1
    }
  ],
  "resourceType": "RelatedPerson"
}
```
  </div>
</details>

#### Read-Only RelatedPerson Extensions

The `http://saraalert.org/StructureDefinition/created-at` extension indicates the time at which the close contact was created. This extension is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/created-at",
  "valueDateTime": "2021-06-23T23:34:35+00:00"
}
```

The `http://saraalert.org/StructureDefinition/enrolled-patient` extension is used to reference the full Patient resource that corresponds to the close contact, if such a Patient exists. This extension is read-only. This field may only be updated by manually enrolling a new Patient for this close contact via the user interface.
```json
{
  "url": "http://saraalert.org/StructureDefinition/enrolled-patient",
  "valueReference": {
    "reference": "Patient/567"
  }
}
```


<a name="read-get-immunization"/>

### GET `[base]/Immunization/[:id]`

Get a monitoree vaccination via an id, e.g.:

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "id": 1,
  "meta": {
    "lastUpdated": "2021-06-23T10:40:04+00:00"
  },
  "extension": [
    {
      "url": "http://saraalert.org/StructureDefinition/created-at",
      "valueDateTime": "2021-06-23T10:40:04+00:00"
    }
  ],
  "status": "completed",
  "vaccineCode": [
    {
      "coding": [
        {
          "system": "http://hl7.org/fhir/sid/cvx",
          "code": "212"
        }
      ],
      "text": "Janssen (J&J) COVID-19 Vaccine"
    }
  ],
  "patient": {
    "reference": "Patient/6"
  },
  "occurrenceDateTime": "2021-06-19",
  "note": [
    {
      "text": "Defy Noxus and taste your own blood."
    }
  ],
  "protocolApplied": [
    {
      "targetDisease": [
        {
          "coding": [
            {
              "system": "http://hl7.org/fhir/sid/cvx",
              "code": "213"
            }
          ],
          "text": "COVID-19"
        }
      ]
    }
  ],
  "resourceType": "Immunization"
}

```
  </div>
</details>

#### Read-Only Immunization Extensions

The `http://saraalert.org/StructureDefinition/created-at` extension indicates the time at which the vaccination was created. This extension is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/created-at",
  "valueDateTime": "2021-06-23T23:34:35+00:00"
}
```

<a name="read-get-provenance"/>

### GET `[base]/Provenance/[:id]`

Get a monitoree history via an id, e.g.:

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "id": 12554,
  "meta": {
    "lastUpdated": "2021-07-21T00:07:30+00:00"
  },
  "contained": [
    {
      "id": "c1f6be4f-32ff-4fb8-b803-7bb8be7cb77b",
      "target": [
        {
          "reference": "Provenance/12554"
        }
      ],
      "recorded": "2021-07-21T00:07:30+00:00",
      "reason": [
        {
          "text": "Entered in error"
        }
      ],
      "activity": {
        "coding": [
          {
            "system": "http://terminology.hl7.org/CodeSystem/v3-DataOperation",
            "code": "DELETE",
            "display": "delete"
          }
        ]
      },
      "agent": [
        {
          "who": {
            "identifier": {
              "value": "state1_epi_enroller@example.com"
            }
          }
        }
      ],
      "resourceType": "Provenance"
    }
  ],
  "extension": [
    {
      "url": "http://saraalert.org/StructureDefinition/comment",
      "valueString": "test"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/history-type",
      "valueString": "Comment"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/original-id",
      "valuePositiveInt": 12554
    }
  ],
  "target": [
    {
      "reference": "Patient/82"
    }
  ],
  "recorded": "2021-07-21T00:07:18+00:00",
  "agent": [
    {
      "who": {
        "identifier": {
          "value": "state1_epi_enroller@example.com"
        }
      },
      "onBehalfOf": {
        "reference": "Patient/82"
      }
    }
  ],
  "resourceType": "Provenance"
}
```
  </div>
</details>

#### Read-Only Provenance Extensions

The `http://saraalert.org/StructureDefinition/comment` extension represents the comment for a history. This extension is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/comment",
  "valueString": "User changed latest public health action to \"Recommended medical evaluation of symptoms\". Reason: Lost to follow-up during monitoring period, details"
}
```

The `http://saraalert.org/StructureDefinition/history-type` extension indicates the type of history that was created. This extension is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/history-type",
  "valueString": "Monitoring Change"
}
```

The `http://saraalert.org/StructureDefinition/original-id` extension indicates the original ID of a history that has been edited. This extension is read-only.
```json
{
  "url": "http://saraalert.org/StructureDefinition/original-id",
  "valuePositiveInt": 12572
}
```


<a name="read-get-all"/>

### GET `[base]/Patient/[:id]/$everything`

Use this route to retrieve a FHIR Bundle containing the monitoree and all their lab results, daily reports, vaccinations, close contacts, and histories. Note that the example below has had resources removed for brevity.

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "id": "d8691bbb-e8b0-4ee9-8da1-b0a59f5e8030",
  "meta": {
    "lastUpdated": "2021-07-22T15:07:06-04:00"
  },
  "type": "searchset",
  "total": 67,
  "entry": [
    {
      "fullUrl": "http://localhost:3000/fhir/r4/Patient/43",
      "resource": {
        "id": 43,
        "meta": {
          "lastUpdated": "2021-07-22T18:18:28+00:00"
        },
        "contained": [
          {
            "target": [
              {
                "reference": "/fhir/r4/Patient/43"
              }
            ],
            "recorded": "2021-06-23T09:03:19+00:00",
            "activity": {
              "coding": [
                {
                  "system": "http://terminology.hl7.org/CodeSystem/v3-DataOperation",
                  "code": "CREATE",
                  "display": "create"
                }
              ]
            },
            "agent": [
              {
                "who": {
                  "identifier": {
                    "value": 6
                  },
                  "display": "locals2c4_enroller@example.com"
                }
              }
            ],
            "resourceType": "Provenance"
          }
        ],
        "extension": [
          {
            "extension": [
              {
                "url": "ombCategory",
                "valueCoding": {
                  "system": "urn:oid:2.16.840.1.113883.6.238",
                  "code": "2106-3",
                  "display": "White"
                }
              },
              {
                "url": "ombCategory",
                "valueCoding": {
                  "system": "urn:oid:2.16.840.1.113883.6.238",
                  "code": "1002-5",
                  "display": "American Indian or Alaska Native"
                }
              },
              {
                "url": "ombCategory",
                "valueCoding": {
                  "system": "urn:oid:2.16.840.1.113883.6.238",
                  "code": "2076-8",
                  "display": "Native Hawaiian or Other Pacific Islander"
                }
              },
              {
                "url": "detailed",
                "valueCoding": {
                  "system": "urn:oid:2.16.840.1.113883.6.238",
                  "code": "2131-1",
                  "display": "Other Race"
                }
              },
              {
                "url": "text",
                "valueString": "White, American Indian or Alaska Native, Native Hawaiian or Other Pacific Islander, Other"
              }
            ],
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race"
          },
          {
            "extension": [
              {
                "url": "ombCategory",
                "valueCoding": {
                  "system": "urn:oid:2.16.840.1.113883.6.238",
                  "code": "2186-5",
                  "display": "Not Hispanic or Latino"
                }
              },
              {
                "url": "text",
                "valueString": "Not Hispanic or Latino"
              }
            ],
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity"
          },
          {
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex",
            "valueCode": "M"
          },
          {
            "extension": [
              {
                "url": "id",
                "valuePositiveInt": 18
              },
              {
                "url": "updated-at",
                "valueDateTime": "2021-06-26T11:12:46+00:00"
              },
              {
                "url": "created-at",
                "valueDateTime": "2021-06-26T11:12:46+00:00"
              },
              {
                "url": "who-initiated-transfer",
                "valueString": "state1_epi@example.com"
              },
              {
                "url": "from-jurisdiction",
                "valueString": "USA, State 1, County 1"
              },
              {
                "url": "to-jurisdiction",
                "valueString": "USA, State 2"
              }
            ],
            "url": "http://saraalert.org/StructureDefinition/transfer"
          },
          {
            "extension": [
              {
                "url": "id",
                "valuePositiveInt": 211
              },
              {
                "url": "updated-at",
                "valueDateTime": "2021-07-04T19:11:57+00:00"
              },
              {
                "url": "created-at",
                "valueDateTime": "2021-07-04T19:11:57+00:00"
              },
              {
                "url": "who-initiated-transfer",
                "valueString": "state2_epi@example.com"
              },
              {
                "url": "from-jurisdiction",
                "valueString": "USA, State 2"
              },
              {
                "url": "to-jurisdiction",
                "valueString": "USA, State 1"
              }
            ],
            "url": "http://saraalert.org/StructureDefinition/transfer"
          },
          {
            "extension": [
              {
                "extension": [
                  {
                    "url": "contact-of-known-case",
                    "valueBoolean": true
                  },
                  {
                    "url": "contact-of-known-case-id",
                    "valueString": "00929074, 01304440, 00162388"
                  }
                ],
                "url": "http://saraalert.org/StructureDefinition/contact-of-known-case"
              },
              {
                "extension": [
                  {
                    "url": "was-in-health-care-facility-with-known-cases",
                    "valueBoolean": true
                  },
                  {
                    "url": "was-in-health-care-facility-with-known-cases-facility-name",
                    "valueString": "Facility123"
                  }
                ],
                "url": "http://saraalert.org/StructureDefinition/was-in-health-care-facility-with-known-cases"
              },
              {
                "extension": [
                  {
                    "url": "laboratory-personnel",
                    "valueBoolean": true
                  },
                  {
                    "url": "laboratory-personnel-facility-name",
                    "valueString": "Facility123"
                  }
                ],
                "url": "http://saraalert.org/StructureDefinition/laboratory-personnel"
              },
              {
                "extension": [
                  {
                    "url": "healthcare-personnel",
                    "valueBoolean": true
                  },
                  {
                    "url": "healthcare-personnel-facility-name",
                    "valueString": "Facility123"
                  }
                ],
                "url": "http://saraalert.org/StructureDefinition/healthcare-personnel"
              },
              {
                "extension": [
                  {
                    "url": "member-of-a-common-exposure-cohort",
                    "valueBoolean": true
                  },
                  {
                    "url": "member-of-a-common-exposure-cohort-type",
                    "valueString": "Cruiseline cohort"
                  }
                ],
                "url": "http://saraalert.org/StructureDefinition/member-of-a-common-exposure-cohort"
              },
              {
                "url": "http://saraalert.org/StructureDefinition/travel-from-affected-country-or-area",
                "valueBoolean": false
              },
              {
                "url": "http://saraalert.org/StructureDefinition/crew-on-passenger-or-cargo-flight",
                "valueBoolean": false
              }
            ],
            "url": "http://saraalert.org/StructureDefinition/exposure-risk-factors"
          },
          {
            "extension": [
              {
                "url": "source-of-report",
                "valueString": "Surveillance Screening"
              }
            ],
            "url": "http://saraalert.org/StructureDefinition/source-of-report"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/preferred-contact-method",
            "valueString": "E-mailed Web Link"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/symptom-onset-date",
            "valueDate": "2021-06-24"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/isolation",
            "valueBoolean": false
          },
          {
            "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
            "valueString": "USA, State 1"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/monitoring-plan",
            "valueString": "Daily active monitoring"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/assigned-user",
            "valuePositiveInt": 205610
          },
          {
            "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-start-date",
            "valueDate": "2021-06-24"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-end-date",
            "valueDate": "2021-06-25"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/port-of-origin",
            "valueString": "New Charleyhaven"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/port-of-entry-into-usa",
            "valueString": "South Anamaria"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/date-of-departure",
            "valueDate": "2021-06-23"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/flight-or-vessel-number",
            "valueString": "V595"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/flight-or-vessel-carrier",
            "valueString": "Clora Airlines"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/date-of-arrival",
            "valueDate": "2021-06-23"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/travel-related-notes",
            "valueString": "Pleasure in the job puts perfection in the work."
          },
          {
            "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-notes",
            "valueString": "Chuck Norris hosting is 101% uptime guaranteed."
          },
          {
            "url": "http://saraalert.org/StructureDefinition/continuous-exposure",
            "valueBoolean": true
          },
          {
            "url": "http://saraalert.org/StructureDefinition/end-of-monitoring",
            "valueString": "Continuous Exposure"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/exposure-risk-assessment",
            "valueString": "No Identified Risk"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/public-health-action",
            "valueString": "None"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/potential-exposure-location",
            "valueString": "Arronton"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/potential-exposure-country",
            "valueString": "Brazil"
          },
          {
            "url": "http://hl7.org/fhir/StructureDefinition/patient-interpreterRequired",
            "valueBoolean": false
          },
          {
            "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-destination",
            "valueString": "Pourosside"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-destination-state",
            "valueString": "District of Columbia"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-port-of-departure",
            "valueString": "New Natalia"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-type",
            "valueString": "Domestic"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/case-status",
            "valueString": "Confirmed"
          },
          {
            "url": "http://hl7.org/fhir/StructureDefinition/patient-genderIdentity",
            "valueCodeableConcept": {
              "coding": [
                {
                  "system": "http://hl7.org/fhir/gender-identity",
                  "code": "transgender-female"
                }
              ],
              "text": "Transgender Female (Male-to-Female [MTF])"
            }
          },
          {
            "url": "http://saraalert.org/StructureDefinition/head-of-household",
            "valueBoolean": true
          },
          {
            "url": "http://saraalert.org/StructureDefinition/id-of-reporter",
            "valuePositiveInt": 43
          },
          {
            "url": "http://saraalert.org/StructureDefinition/last-assessment-reminder-sent",
            "valueDateTime": "2021-06-20T04:00:00+00:00"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/paused-notifications",
            "valueBoolean": false
          },
          {
            "url": "http://saraalert.org/StructureDefinition/status",
            "valueString": "symptomatic"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/user-defined-symptom-onset",
            "valueBoolean": false
          }
        ],
        "identifier": [
          {
            "system": "http://saraalert.org/SaraAlert/cdc-id",
            "value": "0952379687"
          }
        ],
        "active": true,
        "name": [
          {
            "family": "Johns78",
            "given": ["Gerardo58", "Reinger57"]
          }
        ],
        "telecom": [
          {
            "system": "email",
            "value": "3822316898fake@example.com",
            "rank": 1
          }
        ],
        "birthDate": "1981-10-15",
        "address": [
          {
            "line": ["8181 Diana Lodge"],
            "district": "Royal Creek",
            "state": "New Jersey",
            "postalCode": "94336"
          },
          {
            "extension": [
              {
                "url": "http://saraalert.org/StructureDefinition/address-type",
                "valueString": "Monitored"
              }
            ],
            "line": ["8181 Diana Lodge"],
            "district": "Royal Creek",
            "state": "New Jersey",
            "postalCode": "94336"
          }
        ],
        "communication": [
          {
            "language": {
              "coding": [
                {
                  "system": "urn:ietf:bcp:47",
                  "code": "en",
                  "display": "English"
                }
              ]
            },
            "preferred": true
          },
          {
            "language": {
              "coding": [
                {
                  "system": "urn:ietf:bcp:47",
                  "code": "bho",
                  "display": "Bhojpuri"
                }
              ]
            },
            "preferred": false
          }
        ],
        "resourceType": "Patient"
      }
    },
    {
      "fullUrl": "http://localhost:3000/fhir/r4/QuestionnaireResponse/21",
      "resource": {
        "id": 21,
        "meta": {
          "lastUpdated": "2021-07-06T16:10:01+00:00"
        },
        "extension": [
          {
            "url": "http://saraalert.org/StructureDefinition/symptomatic",
            "valueBoolean": true
          },
          {
            "url": "http://saraalert.org/StructureDefinition/created-at",
            "valueDateTime": "2021-06-24T11:51:44+00:00"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/who-reported",
            "valueString": "Monitoree"
          }
        ],
        "status": "completed",
        "subject": {
          "reference": "Patient/43"
        },
        "item": [
          {
            "linkId": "0",
            "text": "cough",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "1",
            "text": "difficulty-breathing",
            "answer": [
              {
                "valueBoolean": true
              }
            ]
          },
          {
            "linkId": "2",
            "text": "new-loss-of-smell",
            "answer": [
              {
                "valueBoolean": true
              }
            ]
          },
          {
            "linkId": "3",
            "text": "new-loss-of-taste",
            "answer": [
              {
                "valueBoolean": true
              }
            ]
          },
          {
            "linkId": "4",
            "text": "shortness-of-breath",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "5",
            "text": "fever",
            "answer": [
              {
                "valueBoolean": true
              }
            ]
          },
          {
            "linkId": "6",
            "text": "used-a-fever-reducer",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "7",
            "text": "chills",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "8",
            "text": "repeated-shaking-with-chills",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "9",
            "text": "muscle-pain",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "10",
            "text": "headache",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "11",
            "text": "sore-throat",
            "answer": [
              {
                "valueBoolean": true
              }
            ]
          },
          {
            "linkId": "12",
            "text": "nausea-or-vomiting",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "13",
            "text": "diarrhea",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "14",
            "text": "fatigue",
            "answer": [
              {
                "valueBoolean": true
              }
            ]
          },
          {
            "linkId": "15",
            "text": "congestion-or-runny-nose",
            "answer": [
              {
                "valueBoolean": true
              }
            ]
          },
          {
            "linkId": "16",
            "text": "pulse-ox",
            "answer": [
              {
                "valueDecimal": 6.0
              }
            ]
          }
        ],
        "resourceType": "QuestionnaireResponse"
      }
    },
    {
      "fullUrl": "http://localhost:3000/fhir/r4/Observation/134",
      "resource": {
        "id": 134,
        "meta": {
          "lastUpdated": "2021-06-25T14:50:13+00:00"
        },
        "extension": [
          {
            "url": "http://saraalert.org/StructureDefinition/created-at",
            "valueDateTime": "2021-06-25T14:50:13+00:00"
          }
        ],
        "status": "final",
        "category": [
          {
            "coding": [
              {
                "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                "code": "laboratory"
              }
            ]
          }
        ],
        "code": {
          "coding": [
            {
              "system": "http://loinc.org",
              "code": "94564-2"
            }
          ],
          "text": "IgM Antibody"
        },
        "subject": {
          "reference": "Patient/43"
        },
        "effectiveDateTime": "2021-06-24",
        "issued": "2021-06-25T00:00:00+00:00",
        "valueCodeableConcept": {
          "coding": [
            {
              "system": "http://snomed.info/sct",
              "code": "10828004"
            }
          ],
          "text": "positive"
        },
        "resourceType": "Observation"
      }
    },
    {
      "fullUrl": "http://localhost:3000/fhir/r4/RelatedPerson/13",
      "resource": {
        "id": 13,
        "meta": {
          "lastUpdated": "2021-06-24T14:28:06+00:00"
        },
        "extension": [
          {
            "url": "http://saraalert.org/StructureDefinition/created-at",
            "valueDateTime": "2021-06-24T14:28:06+00:00"
          }
        ],
        "patient": {
          "reference": "Patient/43"
        },
        "name": [
          {
            "family": "Sipes28",
            "given": ["Jeffrey23"]
          }
        ],
        "telecom": [
          {
            "system": "phone",
            "value": "+15555550150",
            "rank": 1
          },
          {
            "system": "email",
            "value": "5842094680fake@example.com",
            "rank": 1
          }
        ],
        "resourceType": "RelatedPerson"
      }
    },
    {
      "fullUrl": "http://localhost:3000/fhir/r4/Immunization/57",
      "resource": {
        "id": 57,
        "meta": {
          "lastUpdated": "2021-06-27T19:54:16+00:00"
        },
        "extension": [
          {
            "url": "http://saraalert.org/StructureDefinition/created-at",
            "valueDateTime": "2021-06-27T19:54:16+00:00"
          }
        ],
        "status": "completed",
        "vaccineCode": [
          {
            "coding": [
              {
                "system": "http://hl7.org/fhir/sid/cvx",
                "code": "208"
              }
            ],
            "text": "Pfizer-BioNTech COVID-19 Vaccine (COMIRNATY)"
          }
        ],
        "patient": {
          "reference": "Patient/43"
        },
        "occurrenceDateTime": "2021-06-25",
        "note": [
          {
            "text": "My profession?! You know, now that I think of it, I've always wanted to be a baker."
          }
        ],
        "protocolApplied": [
          {
            "targetDisease": [
              {
                "coding": [
                  {
                    "system": "http://hl7.org/fhir/sid/cvx",
                    "code": "213"
                  }
                ],
                "text": "COVID-19"
              }
            ]
          }
        ],
        "resourceType": "Immunization"
      }
    },
    {
      "fullUrl": "http://localhost:3000/fhir/r4/Provenance/141",
      "resource": {
        "id": 141,
        "meta": {
          "lastUpdated": "2021-06-23T09:03:19+00:00"
        },
        "extension": [
          {
            "url": "http://saraalert.org/StructureDefinition/comment",
            "valueString": "User enrolled monitoree."
          },
          {
            "url": "http://saraalert.org/StructureDefinition/history-type",
            "valueString": "Enrollment"
          }
        ],
        "target": [
          {
            "reference": "Patient/43"
          }
        ],
        "recorded": "2021-06-23T09:03:19+00:00",
        "agent": [
          {
            "who": {
              "identifier": {
                "value": "locals2c3_enroller@example.com"
              }
            },
            "onBehalfOf": {
              "reference": "Patient/43"
            }
          }
        ],
        "resourceType": "Provenance"
      }
    }
  ],
  "resourceType": "Bundle"
}
```
  </div>
</details>


<a name="create"/>

## Creating

The API supports creating new monitorees.

### POST `[base]/Patient`

<a name="create-post-pat"/>

To create a new monitoree, simply POST a FHIR Patient resource.

**Request Body:**
<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "extension": [
    {
      "extension": [
        {
          "url": "ombCategory",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "2054-5",
            "display": "Black or African American"
          }
        },
        {
          "url": "text",
          "valueString": "Black or African American"
        }
      ],
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race"
    },
    {
      "extension": [
        {
          "url": "ombCategory",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "2186-5",
            "display": "Not Hispanic or Latino"
          }
        },
        {
          "url": "text",
          "valueString": "Not Hispanic or Latino"
        }
      ],
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity"
    },
    {
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex",
      "valueCode": "M"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/preferred-contact-method",
      "valueString": "E-mailed Web Link"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/symptom-onset-date",
      "valueDate": "2020-05-23"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/last-exposure-date",
      "valueDate": "2020-05-18"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/isolation",
      "valueBoolean": false
    },
    {
      "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
      "valueString": "USA, State 1"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/exposure-risk-assessment",
      "valueString": "Low"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/public-health-action",
      "valueString": "Document results of medical evaluation"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/potential-exposure-location",
      "valueString": "Collierview"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/potential-exposure-country",
      "valueString": "Angola"
    },
    {
      "url": "http://hl7.org/fhir/StructureDefinition/patient-interpreterRequired",
      "valueBoolean": true
    },
    {
      "url": "http://hl7.org/fhir/StructureDefinition/follow-up-reason",
      "valueString": "Duplicate"
    },
    {
      "url": "http://hl7.org/fhir/StructureDefinition/follow-up-note",
      "valueString": "This is a duplicate."
    }
  ],
  "active": true,
  "name": [
    {
      "family": "O'Kon89",
      "given": [
        "Malcolm94",
        "Bogan39"
      ]
    }
  ],
  "telecom": [
    {
      "system": "phone",
      "value": "(333) 333-3333",
      "rank": 1
    },
    {
      "system": "phone",
      "value": "(333) 333-3333",
      "rank": 2
    },
    {
      "system": "email",
      "value": "2966977816fake@example.com",
      "rank": 1
    }
  ],
  "birthDate": "1981-03-30",
  "address": [
    {
      "line": [
        "22424 Daphne Key"
      ],
      "city": "West Gabrielmouth",
      "state": "Maine",
      "postalCode": "24683"
    }
  ],
  "communication": [
    {
      "language": {
        "coding": [
          {
            "system": "urn:ietf:bcp:47",
            "code": "en",
            "display": "English"
          }
        ]
      }
    }
  ],
  "resourceType": "Patient"
}
```
  </div>
</details>


**Response:**

On success, the server will return the newly created resource with an id. This is can be used to retrieve or update the record moving forward.

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "id": 1109,
  "meta": {
    "lastUpdated": "2020-05-29T00:56:18+00:00"
  },
  "extension": [
    {
      "extension": [
        {
          "url": "ombCategory",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "2054-5",
            "display": "Black or African American"
          }
        },
        {
          "url": "text",
          "valueString": "Black or African American"
        }
      ],
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race"
    },
    {
      "extension": [
        {
          "url": "ombCategory",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "2186-5",
            "display": "Not Hispanic or Latino"
          }
        },
        {
          "url": "text",
          "valueString": "Not Hispanic or Latino"
        }
      ],
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity"
    },
    {
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex",
      "valueCode": "M"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/preferred-contact-method",
      "valueString": "E-mailed Web Link"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/symptom-onset-date",
      "valueDate": "2020-05-23"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/last-exposure-date",
      "valueDate": "2020-05-18"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/isolation",
      "valueBoolean": false
    },
    {
      "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
      "valueString": "USA, State 1"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/end-of-monitoring",
      "valueString": "2020-05-29"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/exposure-risk-assessment",
      "valueString": "Low"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/public-health-action",
      "valueString": "Document results of medical evaluation"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/potential-exposure-location",
      "valueString": "Collierview"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/potential-exposure-country",
      "valueString": "Angola"
    },
    {
      "url": "http://hl7.org/fhir/StructureDefinition/patient-interpreterRequired",
      "valueBoolean": true
    }
  ],
  "active": true,
  "name": [
    {
      "family": "O'Kon89",
      "given": [
        "Malcolm94",
        "Bogan39"
      ]
    }
  ],
  "telecom": [
    {
      "system": "phone",
      "value": "+13333333333",
      "rank": 1
    },
    {
      "system": "phone",
      "value": "+13333333333",
      "rank": 2
    },
    {
      "system": "email",
      "value": "2966977816fake@example.com",
      "rank": 1
    }
  ],
  "birthDate": "1981-03-30",
  "address": [
    {
      "line": [
        "22424 Daphne Key"
      ],
      "city": "West Gabrielmouth",
      "state": "Maine",
      "postalCode": "24683"
    }
  ],
  "communication": [
    {
      "language": {
        "coding": [
          {
            "system": "urn:ietf:bcp:47",
            "code": "en",
            "display": "English"
          }
        ]
      }
    }
  ],
  "resourceType": "Patient"
}
```
  </div>
</details>

#### Patient Extensions

<a name="create-pat-ext"/>

Along with supporting the US Core extensions for [race](https://www.hl7.org/fhir/us/core/StructureDefinition-us-core-race.html), [ethnicity](https://www.hl7.org/fhir/us/core/StructureDefinition-us-core-ethnicity.html), and [birthsex](https://www.hl7.org/fhir/us/core/StructureDefinition-us-core-birthsex.html), Sara Alert includes additional extensions for attributes specific to the Sara Alert workflows.

Use `http://saraalert.org/StructureDefinition/preferred-contact-method` to specify the monitoree's Sara Alert preferred contact method (options are: `E-mailed Web Link`, `SMS Texted Weblink`, `Telephone call`, `SMS Text-message`, `Opt-out`, and `Unknown`).

```json
{
  "url": "http://saraalert.org/StructureDefinition/preferred-contact-method",
  "valueString": "E-mailed Web Link"
}
```

Use `http://saraalert.org/StructureDefinition/preferred-contact-time` to specify the monitoree's Sara Alert preferred contact time (options are: `Morning`, `Afternoon`, and `Evening`).

```json
{
  "url": "http://saraalert.org/StructureDefinition/preferred-contact-time",
  "valueString": "Morning"
}
```

Use `http://saraalert.org/StructureDefinition/symptom-onset-date` to specify when the monitoree's first symptoms appeared for use in the Sara Alert isolation workflow.

```json
{
  "url": "http://saraalert.org/StructureDefinition/symptom-onset-date",
  "valueDate": "2020-05-23"
}
```

Use `http://saraalert.org/StructureDefinition/last-exposure-date` to specify when the monitoree's last exposure occurred for use in the Sara Alert exposure workflow.


```json
{
  "url": "http://saraalert.org/StructureDefinition/last-exposure-date",
  "valueDate": "2020-05-18"
}
```

Use `http://saraalert.org/StructureDefinition/isolation` to specify if the monitoree should be in the isolation workflow (omitting this extension defaults this value to false, leaving the monitoree in the exposure workflow).

```json
{
  "url": "http://saraalert.org/StructureDefinition/isolation",
  "valueBoolean": false
}
```

Use `http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path` to specify the monitoree's assigned jurisdiction.
```json
{
  "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
  "valueString": "USA, State 1"
}
```

Use `http://saraalert.org/StructureDefinition/monitoring-plan` to specify the monitoree's Sara Alert monitoring plan (options are: `None`, `Daily active monitoring`, `Self-monitoring with public health supervision`, `Self-monitoring with delegated supervision`, and `Self-observation`).
```json
{
  "url": "http://saraalert.org/StructureDefinition/monitoring-plan",
  "valueString": "Daily active monitoring"
}
```

Use `http://saraalert.org/StructureDefinition/assigned-user` to specify the monitoree's assigned user.
```json
{
  "url": "http://saraalert.org/StructureDefinition/assigned-user",
  "valuePositiveInt": 123
}
```

Use `http://saraalert.org/StructureDefinition/additional-planned-travel-start-date` to specify when the monitoree is planning to begin their travel.
```json
{
  "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-start-date",
  "valueDate": "2020-06-15"
}
```

Use `http://saraalert.org/StructureDefinition/port-of-origin` to specify the port that the monitoree traveled from.
```json
{
  "url": "http://saraalert.org/StructureDefinition/port-of-origin",
  "valueString": "MSP Airport"
}
```

Use `http://saraalert.org/StructureDefinition/date-of-departure` to specify when the monitoree departed from the port of origin.
```json
{
  "url": "http://saraalert.org/StructureDefinition/date-of-departure",
  "valueDate": "2020-05-25"
}
```

Use `http://saraalert.org/StructureDefinition/flight-or-vessel-number` to specify the plane, train, ship, or other vessel that the monitoree used to travel to their destination.
```json
{
  "url": "http://saraalert.org/StructureDefinition/flight-or-vessel-number",
  "valueString": "QQ1234"
}
```

Use `http://saraalert.org/StructureDefinition/flight-or-vessel-carrier` to specify the carrier, operating company, or provider of the flight or vessel.
```json
{
  "url": "http://saraalert.org/StructureDefinition/flight-or-vessel-carrier",
  "valueString": "QQ Airways"
}
```

Use `http://saraalert.org/StructureDefinition/date-of-arrival` to specify when the monitoree
entered the United States after travel.
```json
{
  "url": "http://saraalert.org/StructureDefinition/date-of-arrival",
  "valueDate": "2020-05-28"
}
```

Use `http://saraalert.org/StructureDefinition/exposure-notes` to specify additional notes about the monitoree's exposure history or case information history.
```json
{
  "url": "http://saraalert.org/StructureDefinition/exposure-notes",
  "valueString": "Sample exposure notes."
}
```

Use `http://saraalert.org/StructureDefinition/travel-related-notes` to specify additional notes
about the monitoree’s travel history.
```json
{
  "url": "http://saraalert.org/StructureDefinition/travel-related-notes",
  "valueString": "Sample travel notes."
}
```

Use `http://saraalert.org/StructureDefinition/additional-planned-travel-notes` to specify additional notes about the monitoree's planned travel.
```json
{
  "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-notes",
  "valueString": "Sample planned travel notes."
}
```

Use `http://saraalert.org/StructureDefinition/exposure-risk-assessment` to specify the risk assessment of the monitoree's exposure to disease.
```json
{
  "url": "http://saraalert.org/StructureDefinition/exposure-risk-assessment",
  "valueString": "Low"
}
```

Use `http://saraalert.org/StructureDefinition/public-health-action` to specify the public health recommendation provided to a monitoree.
```json
{
  "url": "http://saraalert.org/StructureDefinition/public-health-action",
  "valueString": "Document results of medical evaluation"
}
```

Use `http://saraalert.org/StructureDefinition/potential-exposure-location` to specify a description of the location where the monitoree was potentially last exposed to a case.
```json
{
  "url": "http://saraalert.org/StructureDefinition/potential-exposure-location",
  "valueString": "Boise"
}
```

Use `http://saraalert.org/StructureDefinition/potential-exposure-country` to specify the country where the monitoree was potentially last exposed to a case.
```json
{
  "url": "http://saraalert.org/StructureDefinition/potential-exposure-country",
  "valueString": "Angola"
}
```

Use `http://hl7.org/fhir/StructureDefinition/patient-interpreterRequired` to specify if the monitoree needs a language interpreter when speaking with public health representatives.
```json
{
  "url": "http://hl7.org/fhir/StructureDefinition/patient-interpreterRequired",
  "valueBoolean": true
}
```

Use `http://saraalert.org/StructureDefinition/extended-isolation` to specify a user-defined date that determines eligibility for a monitoree appearing on the Records Requiring Review linelist.
```json
{
  "url": "http://saraalert.org/StructureDefinition/extended-isolation",
  "valueDate": "2021-06-15"
}
```

Use `http://saraalert.org/StructureDefinition/follow-up-reason` to specify a reason to follow up on the monitoree (options are: `Deceased`, `Duplicate`, `High-Risk`, `Hospitalized`, `In Need of Follow-up`, `Lost to Follow-up`, `Needs Interpretation`, `Quality Assurance`, `Refused Active Monitoring`, and `Other`).
```json
{
  "url": "http://saraalert.org/StructureDefinition/follow-up-reason",
  "valueString": "Duplicate"
}
```

Use `http://saraalert.org/StructureDefinition/follow-up-note` to specify additional details for follow up reason on the monitoree. This requires the follow up reason to be set.
```json
{
  "url": "http://saraalert.org/StructureDefinition/follow-up-note",
  "valueString": "This is a duplicate."
}
```

Use `http://saraalert.org/StructureDefinition/phone-type` to specify the type of phone attached to the primary or secondary phone number (options are: `Smartphone`, `Plain Cell`, and `Landline`). Note that this extension should be placed on the first element in the `Patient.telecom` array to specify the monitoree's primary phone type, and the second element in the `Patient.telecom` array to specify the monitoree's secondary phone type.
```json
"telecom": [
  {
    "system": "phone",
    "value": "(333) 333-3333",
    "rank": 1,
    "extension": {
      "url": "http://saraalert.org/StructureDefinition/phone-type",
      "valueString": "Smartphone"
    }
  }
]
```

Use `http://saraalert.org/StructureDefinition/address-type` to specify the type of an address (options are: `USA`, `Foreign`, `Monitored`, and `ForeignMonitored`). Note that this extension should be placed on an element in the `Patient.address` array. If this extension is not present on an address in the `Patient.address` array, the address is assumed to be a `USA` address. Addresses of type `Monitored` or `ForeignMonitored` are read-only.
```json
"address": [
  {
    "extension": [
      {
        "url": "http://saraalert.org/StructureDefinition/address-type",
        "valueString": "Foreign"
      }
    ],
    "line": ["24961 Linnie Inlet", "Apt. 497"],
    "city": "Ottawa",
    "state": "Ontario",
    "country": "Canada",
    "postalCode": "192387"
  },
  {
    "line": ["35047 Van Light"],
    "city": "New Tambra",
    "state": "Mississippi",
    "district": "Summer Square",
    "postalCode": "05657",
  }
]
```

### POST `[base]/RelatedPerson`

<a name="create-post-related"/>

To create a new monitoree close contact, simply POST a FHIR RelatedPerson resource that references the monitoree.

**Request Body:**
<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "extension": [
    {
      "url": "http://saraalert.org/StructureDefinition/contact-attempts",
      "valueUnsignedInt": 5
    },
    {
      "url": "http://saraalert.org/StructureDefinition/notes",
      "valueString": "Parsing the panel won't do anything, we need to program the optical ib array!"
    }
  ],
  "patient": {
    "reference": "Patient/222"
  },
  "name": [
    {
      "family": "Pollich97",
      "given": ["Nam32"]
    }
  ],
  "telecom": [
    {
      "system": "phone",
      "value": "+15555550104",
      "rank": 1
    },
    {
      "system": "email",
      "value": "1845823000fake@example.com",
      "rank": 1
    }
  ],
  "resourceType": "RelatedPerson"
}
```
  </div>
</details>

#### RelatedPerson Extensions

<a name="create-related-ext"/>

Sara Alert includes additional extensions for attributes specific to a monitoree close contact.


Use `http://saraalert.org/StructureDefinition/last-date-of-exposure` to specify when the close contact's last exposure occurred.
```json
{
  "url": "http://saraalert.org/StructureDefinition/last-date-of-exposure",
  "valueDate": "2020-05-18"
}
```

Use `http://saraalert.org/StructureDefinition/assigned-user` to specify the close contacts's assigned user.
```json
{
  "url": "http://saraalert.org/StructureDefinition/assigned-user",
  "valuePositiveInt": 123
}
```

Use `http://saraalert.org/StructureDefinition/notes` to specify additional notes about the close contacts's case.
```json
{
  "url": "http://saraalert.org/StructureDefinition/notes",
  "valueString": "Sample notes."
}
```

Use `http://saraalert.org/StructureDefinition/contact-attempts` to specify the number of attempts made to contact the close contact.
```json
{
  "url": "http://saraalert.org/StructureDefinition/contact-attempts",
  "valueUnsignedInt": 2
}
```


### POST `[base]/Immunization`

<a name="create-post-immunization"/>

To create a new monitoree vaccination, simply POST a FHIR Immunization resource that references the monitoree.

**Request Body:**
<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "status": "completed",
  "vaccineCode": [
    {
      "coding": [
        {
          "system": "http://hl7.org/fhir/sid/cvx",
          "code": "207"
        }
      ],
      "text": "Moderna COVID-19 Vaccine (non-US Spikevax)"
    }
  ],
  "patient": {
    "reference": "Patient/1"
  },
  "occurrenceDateTime": "2021-03-30",
  "note": [
    {
      "text": "Notes here"
    }
  ],
  "protocolApplied": [
    {
      "targetDisease": [
        {
          "coding": [
            {
              "system": "http://hl7.org/fhir/sid/cvx",
              "code": "213"
            }
          ],
          "text": "COVID-19"
        }
      ],
      "doseNumberString": "1"
    }
  ],
  "resourceType": "Immunization"
}
```
  </div>
</details>

### POST `[base]/Observation`

<a name="create-post-immunization"/>

To create a new monitoree lab result, simply POST a FHIR Observation resource that references the monitoree.

**Request Body:**
<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "status": "final",
  "subject": {
    "reference": "Patient/10"
  },
  "code": {
    "coding": [
      {
        "system": "http://loinc.org",
        "code": "94564-2"
      }
    ]
  },
  "valueCodeableConcept": {
    "coding": [
      {
        "system": "http://snomed.info/sct",
        "code": "10828004"
      }
    ]
  },
  "effectiveDateTime": "2021-05-06",
  "issued": "2021-05-07T00:00:00+00:00",
  "resourceType": "Observation"
}
```
  </div>
</details>


<a name="update"/>

## Updating
An update request creates a new current version for an existing resource.

**PLEASE NOTE:** The API supports `PUT` and `PATCH` requests, which update an existing resource in different ways. A `PUT` request will replace the entire existing resource. This means that if certain attributes of the resource are omitted in the `PUT` requests, they will be replaced with null values. A `PATCH` request will only modify the attributes indicated in the request, which must follow the [JSON Patch specification](https://tools.ietf.org/html/rfc6902). Omitted attributes are unchanged. For further details on the contents of a `PATCH` request, see the [JSON Patch documentation](http://jsonpatch.com/).

<a name="update-put-pat"/>

### PUT `[base]/Patient/[:id]`

**NOTE:** This is a `PUT` operation, it will replace the entire resource. If you intend to modify specific attributes instead, see [PATCH](#update-patch-pat).

**Request Body:**
<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "extension": [
    {
      "extension": [
        {
          "url": "ombCategory",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "2054-5",
            "display": "Black or African American"
          }
        },
        {
          "url": "text",
          "valueString": "Black or African American"
        }
      ],
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race"
    },
    {
      "extension": [
        {
          "url": "ombCategory",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "2186-5",
            "display": "Not Hispanic or Latino"
          }
        },
        {
          "url": "text",
          "valueString": "Not Hispanic or Latino"
        }
      ],
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity"
    },
    {
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex",
      "valueCode": "M"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/preferred-contact-method",
      "valueString": "E-mailed Web Link"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/symptom-onset-date",
      "valueDate": "2020-05-23"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/last-exposure-date",
      "valueDate": "2020-05-18"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/isolation",
      "valueBoolean": true
    },
    {
      "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
      "valueString": "USA, State 1"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/exposure-risk-assessment",
      "valueString": "Low"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/public-health-action",
      "valueString": "Document results of medical evaluation"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/potential-exposure-location",
      "valueString": "Collierview"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/potential-exposure-country",
      "valueString": "Angola"
    },
    {
      "url": "http://hl7.org/fhir/StructureDefinition/patient-interpreterRequired",
      "valueBoolean": true
    },
    {
      "url": "http://hl7.org/fhir/StructureDefinition/follow-up-reason",
      "valueString": "Duplicate"
    },
    {
      "url": "http://hl7.org/fhir/StructureDefinition/follow-up-note",
      "valueString": "This is a duplicate."
    }
  ],
  "active": true,
  "name": [
    {
      "family": "O'Kon89",
      "given": [
        "Malcolm94",
        "Bogan39"
      ]
    }
  ],
  "telecom": [
    {
      "system": "phone",
      "value": "(333) 333-3333",
      "rank": 1
    },
    {
      "system": "phone",
      "value": "(333) 333-3333",
      "rank": 2
    },
    {
      "system": "email",
      "value": "2966977816fake@example.com",
      "rank": 1
    }
  ],
  "birthDate": "1981-03-30",
  "address": [
    {
      "line": [
        "22424 Daphne Key"
      ],
      "city": "West Gabrielmouth",
      "state": "Maine",
      "postalCode": "24683"
    }
  ],
  "communication": [
    {
      "language": {
        "coding": [
          {
            "system": "urn:ietf:bcp:47",
            "code": "en",
            "display": "English"
          }
        ]
      }
    }
  ],
  "resourceType": "Patient"
}
```
  </div>
</details>


**Response:**

On success, the server will update the existing resource given the id.

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "id": 1109,
  "meta": {
    "lastUpdated": "2020-05-29T00:57:40+00:00"
  },
  "extension": [
    {
      "extension": [
        {
          "url": "ombCategory",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "2054-5",
            "display": "Black or African American"
          }
        },
        {
          "url": "text",
          "valueString": "Black or African American"
        }
      ],
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race"
    },
    {
      "extension": [
        {
          "url": "ombCategory",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "2186-5",
            "display": "Not Hispanic or Latino"
          }
        },
        {
          "url": "text",
          "valueString": "Not Hispanic or Latino"
        }
      ],
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity"
    },
    {
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex",
      "valueCode": "M"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/preferred-contact-method",
      "valueString": "E-mailed Web Link"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/symptom-onset-date",
      "valueDate": "2020-05-23"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/last-exposure-date",
      "valueDate": "2020-05-18"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/isolation",
      "valueBoolean": true
    },
    {
      "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
      "valueString": "USA, State 1"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/end-of-monitoring",
      "valueString": "2020-05-29"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/exposure-risk-assessment",
      "valueString": "Low"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/public-health-action",
      "valueString": "Document results of medical evaluation"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/potential-exposure-location",
      "valueString": "Collierview"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/potential-exposure-country",
      "valueString": "Angola"
    },
    {
      "url": "http://hl7.org/fhir/StructureDefinition/patient-interpreterRequired",
      "valueBoolean": true
    }
  ],
  "active": true,
  "name": [
    {
      "family": "O'Kon89",
      "given": [
        "Malcolm94",
        "Bogan39"
      ]
    }
  ],
  "telecom": [
    {
      "system": "phone",
      "value": "+13333333333",
      "rank": 1
    },
    {
      "system": "phone",
      "value": "+13333333333",
      "rank": 2
    },
    {
      "system": "email",
      "value": "2966977816fake@example.com",
      "rank": 1
    }
  ],
  "birthDate": "1981-03-30",
  "address": [
    {
      "line": [
        "22424 Daphne Key"
      ],
      "city": "West Gabrielmouth",
      "state": "Maine",
      "postalCode": "24683"
    }
  ],
  "communication": [
    {
      "language": {
        "coding": [
          {
            "system": "urn:ietf:bcp:47",
            "code": "en",
            "display": "English"
          }
        ]
      }
    }
  ],
  "resourceType": "Patient"
}
```
  </div>
</details>

<a name="update-put-related"/>

### PUT `[base]/RelatedPerson/[:id]`

**Request Body:**
<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "extension": [
    {
      "url": "http://saraalert.org/StructureDefinition/contact-attempts",
      "valueUnsignedInt": 5
    },
    {
      "url": "http://saraalert.org/StructureDefinition/notes",
      "valueString": "Parsing the panel won't do anything, we need to program the optical ib array!"
    }
  ],
  "patient": {
    "reference": "Patient/222"
  },
  "name": [
    {
      "family": "Pollich97",
      "given": ["Nam32"]
    }
  ],
  "telecom": [
    {
      "system": "phone",
      "value": "+15555550104",
      "rank": 1
    },
    {
      "system": "email",
      "value": "1845823000fake@example.com",
      "rank": 1
    }
  ],
  "resourceType": "RelatedPerson"
}
```
  </div>
</details>

<a name="update-put-immunization"/>

### PUT `[base]/Immunization/[:id]`

**Request Body:**
<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "status": "completed",
  "vaccineCode": [
    {
      "coding": [
        {
          "system": "http://hl7.org/fhir/sid/cvx",
          "code": "207"
        }
      ],
      "text": "Moderna COVID-19 Vaccine (non-US Spikevax)"
    }
  ],
  "patient": {
    "reference": "Patient/1"
  },
  "occurrenceDateTime": "2021-03-30",
  "note": [
    {
      "text": "Notes here"
    }
  ],
  "protocolApplied": [
    {
      "targetDisease": [
        {
          "coding": [
            {
              "system": "http://hl7.org/fhir/sid/cvx",
              "code": "213"
            }
          ],
          "text": "COVID-19"
        }
      ],
      "doseNumberString": "1"
    }
  ],
  "resourceType": "Immunization"
}
```
  </div>
</details>

<a name="update-put-observation"/>
### PUT `[base]/Observation/[:id]`

**Request Body:**
<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "status": "final",
  "subject": {
    "reference": "Patient/10"
  },
  "code": {
    "coding": [
      {
        "system": "http://loinc.org",
        "code": "94564-2"
      }
    ]
  },
  "valueCodeableConcept": {
    "coding": [
      {
        "system": "http://snomed.info/sct",
        "code": "10828004"
      }
    ]
  },
  "effectiveDateTime": "2021-05-06",
  "issued": "2021-05-07T00:00:00+00:00",
  "resourceType": "Observation",
}
```
  </div>
</details>

<a name="update-patch-pat"/>

### PATCH `[base]/Patient/[:id]`

**NOTE:** This is a `PATCH` operation, it will only modify specified attributes. If you intend to replace the entire resource instead, see [PUT](#update-put-pat).

**Request Headers:**
```
Content-Type: application/json-patch+json
```

**Request Body:**

Assume the Patient resource was originally as shown in the example Patient [GET](#read-get-pat), and the patch is specified as below.

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
[
  { "op": "remove", "path": "/communication" },
  { "op": "replace", "path": "/birthDate", "value": "1985-03-30" }
]
```
  </div>
</details>


**Response:**

On success, the server will update the attributes indicated by the request.

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "id": 5,
  "meta": {
    "lastUpdated": "2020-05-29T00:19:18+00:00"
  },
  "extension": [
    {
      "extension": [
        {
          "url": "ombCategory",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "2054-5",
            "display": "Black or African American"
          }
        },
        {
          "url": "text",
          "valueString": "Black or African American"
        }
      ],
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race"
    },
    {
      "extension": [
        {
          "url": "ombCategory",
          "valueCoding": {
            "system": "urn:oid:2.16.840.1.113883.6.238",
            "code": "2186-5",
            "display": "Not Hispanic or Latino"
          }
        },
        {
          "url": "text",
          "valueString": "Not Hispanic or Latino"
        }
      ],
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity"
    },
    {
      "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex",
      "valueCode": "M"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/preferred-contact-method",
      "valueString": "E-mailed Web Link"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/symptom-onset-date",
      "valueDate": "2020-05-23"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/last-exposure-date",
      "valueDate": "2020-05-18"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/isolation",
      "valueBoolean": false
    },
    {
      "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
      "valueString": "USA, State 1"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/end-of-monitoring",
      "valueString": "2020-05-29"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/exposure-risk-assessment",
      "valueString": "Low"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/public-health-action",
      "valueString": "Document results of medical evaluation"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/potential-exposure-location",
      "valueString": "Collierview"
    },
    {
      "url": "http://saraalert.org/StructureDefinition/potential-exposure-country",
      "valueString": "Angola"
    },
    {
      "url": "http://hl7.org/fhir/StructureDefinition/patient-interpreterRequired",
      "valueBoolean": true
    }
  ],
  "active": true,
  "name": [
    {
      "family": "O'Kon89",
      "given": [
        "Malcolm94",
        "Bogan39"
      ]
    }
  ],
  "telecom": [
    {
      "system": "phone",
      "value": "(333) 333-3333",
      "rank": 1
    },
    {
      "system": "phone",
      "value": "(333) 333-3333",
      "rank": 2
    },
    {
      "system": "email",
      "value": "2966977816fake@example.com",
      "rank": 1
    }
  ],
  "birthDate": "1985-03-30",
  "address": [
    {
      "line": [
        "22424 Daphne Key"
      ],
      "city": "West Gabrielmouth",
      "state": "Maine",
      "postalCode": "24683"
    }
  ],
  "resourceType": "Patient"
}
```
  </div>
</details>

<a name="update-patch-related"/>

### PATCH `[base]/RelatedPerson/[:id]`

**NOTE:** See the [Patient PATCH documentation](#update-patch-pat) for a more complete explanation of PATCH.

**Request Headers:**
```
Content-Type: application/json-patch+json
```

**Request Body:**


<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
[
  { "op": "remove", "path": "/name/0/family" },
]
```
  </div>
</details>

<a name="update-patch-immunization"/>

### PATCH `[base]/Immunization/[:id]`

**NOTE:** See the [Patient PATCH documentation](#update-patch-pat) for a more complete explanation of PATCH.

**Request Headers:**
```
Content-Type: application/json-patch+json
```

**Request Body:**


<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
[
  { "op": "replace", "path": "/note/0/text", "value": "Important notes" },
]
```
  </div>
</details>

<a name="update-patch-observation"/>
### PATCH `[base]/Observation/[:id]`

**NOTE:** See the [Patient PATCH documentation](#update-patch-pat) for a more complete explanation of PATCH.

**Request Headers:**
```
Content-Type: application/json-patch+json
```

**Request Body:**


<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
[
  { "op": "replace", "path": "/valueCodeableConcept/coding/0", "value":  { "system": "http://snomed.info/sct", "code": "260385009" }}
]
```
  </div>
</details>


<a name="search"/>

## Searching

The API supports searching for monitorees.

<a name="search-get"/>

### GET `[base]/Patient?parameter(s)`

The current parameters allowed are: `given`, `family`, `telecom`, `email`, `active`, `subject`, and `_id`. Search results will be paginated by default (see: <https://www.hl7.org/fhir/http.html#paging>), although you can request a different page size using the `_count` param (defaults to 10, but will allow up to 500). Utilize the `page` param to navigate through the results, as demonstrated in the `[base]/Patient?_count=2` example below under the `link` entry.

GET `[base]/Patient?given=john&family=doe`

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "id": "aa7c4d39-a256-4c77-b7f9-6b0931134449",
  "meta": {
    "lastUpdated": "2021-07-22T15:11:17-04:00"
  },
  "type": "searchset",
  "total": 1,
  "entry": [
    {
      "fullUrl": "http://localhost:3000/fhir/r4/Patient/43",
      "resource": {
        "id": 43,
        "meta": {
          "lastUpdated": "2021-07-22T18:18:28+00:00"
        },
        "contained": [
          {
            "target": [
              {
                "reference": "/fhir/r4/Patient/43"
              }
            ],
            "recorded": "2021-06-23T09:03:19+00:00",
            "activity": {
              "coding": [
                {
                  "system": "http://terminology.hl7.org/CodeSystem/v3-DataOperation",
                  "code": "CREATE",
                  "display": "create"
                }
              ]
            },
            "agent": [
              {
                "who": {
                  "identifier": {
                    "value": 6
                  },
                  "display": "locals2c4_enroller@example.com"
                }
              }
            ],
            "resourceType": "Provenance"
          }
        ],
        "extension": [
          {
            "extension": [
              {
                "url": "ombCategory",
                "valueCoding": {
                  "system": "urn:oid:2.16.840.1.113883.6.238",
                  "code": "2106-3",
                  "display": "White"
                }
              },
              {
                "url": "ombCategory",
                "valueCoding": {
                  "system": "urn:oid:2.16.840.1.113883.6.238",
                  "code": "1002-5",
                  "display": "American Indian or Alaska Native"
                }
              },
              {
                "url": "ombCategory",
                "valueCoding": {
                  "system": "urn:oid:2.16.840.1.113883.6.238",
                  "code": "2076-8",
                  "display": "Native Hawaiian or Other Pacific Islander"
                }
              },
              {
                "url": "detailed",
                "valueCoding": {
                  "system": "urn:oid:2.16.840.1.113883.6.238",
                  "code": "2131-1",
                  "display": "Other Race"
                }
              },
              {
                "url": "text",
                "valueString": "White, American Indian or Alaska Native, Native Hawaiian or Other Pacific Islander, Other"
              }
            ],
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race"
          },
          {
            "extension": [
              {
                "url": "ombCategory",
                "valueCoding": {
                  "system": "urn:oid:2.16.840.1.113883.6.238",
                  "code": "2186-5",
                  "display": "Not Hispanic or Latino"
                }
              },
              {
                "url": "text",
                "valueString": "Not Hispanic or Latino"
              }
            ],
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity"
          },
          {
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex",
            "valueCode": "M"
          },
          {
            "extension": [
              {
                "url": "id",
                "valuePositiveInt": 18
              },
              {
                "url": "updated-at",
                "valueDateTime": "2021-06-26T11:12:46+00:00"
              },
              {
                "url": "created-at",
                "valueDateTime": "2021-06-26T11:12:46+00:00"
              },
              {
                "url": "who-initiated-transfer",
                "valueString": "state1_epi@example.com"
              },
              {
                "url": "from-jurisdiction",
                "valueString": "USA, State 1, County 1"
              },
              {
                "url": "to-jurisdiction",
                "valueString": "USA, State 2"
              }
            ],
            "url": "http://saraalert.org/StructureDefinition/transfer"
          },
          {
            "extension": [
              {
                "url": "id",
                "valuePositiveInt": 211
              },
              {
                "url": "updated-at",
                "valueDateTime": "2021-07-04T19:11:57+00:00"
              },
              {
                "url": "created-at",
                "valueDateTime": "2021-07-04T19:11:57+00:00"
              },
              {
                "url": "who-initiated-transfer",
                "valueString": "state2_epi@example.com"
              },
              {
                "url": "from-jurisdiction",
                "valueString": "USA, State 2"
              },
              {
                "url": "to-jurisdiction",
                "valueString": "USA, State 1"
              }
            ],
            "url": "http://saraalert.org/StructureDefinition/transfer"
          },
          {
            "extension": [
              {
                "extension": [
                  {
                    "url": "contact-of-known-case",
                    "valueBoolean": true
                  },
                  {
                    "url": "contact-of-known-case-id",
                    "valueString": "00929074, 01304440, 00162388"
                  }
                ],
                "url": "http://saraalert.org/StructureDefinition/contact-of-known-case"
              },
              {
                "extension": [
                  {
                    "url": "was-in-health-care-facility-with-known-cases",
                    "valueBoolean": true
                  },
                  {
                    "url": "was-in-health-care-facility-with-known-cases-facility-name",
                    "valueString": "Facility123"
                  }
                ],
                "url": "http://saraalert.org/StructureDefinition/was-in-health-care-facility-with-known-cases"
              },
              {
                "extension": [
                  {
                    "url": "laboratory-personnel",
                    "valueBoolean": true
                  },
                  {
                    "url": "laboratory-personnel-facility-name",
                    "valueString": "Facility123"
                  }
                ],
                "url": "http://saraalert.org/StructureDefinition/laboratory-personnel"
              },
              {
                "extension": [
                  {
                    "url": "healthcare-personnel",
                    "valueBoolean": true
                  },
                  {
                    "url": "healthcare-personnel-facility-name",
                    "valueString": "Facility123"
                  }
                ],
                "url": "http://saraalert.org/StructureDefinition/healthcare-personnel"
              },
              {
                "extension": [
                  {
                    "url": "member-of-a-common-exposure-cohort",
                    "valueBoolean": true
                  },
                  {
                    "url": "member-of-a-common-exposure-cohort-type",
                    "valueString": "Cruiseline cohort"
                  }
                ],
                "url": "http://saraalert.org/StructureDefinition/member-of-a-common-exposure-cohort"
              },
              {
                "url": "http://saraalert.org/StructureDefinition/travel-from-affected-country-or-area",
                "valueBoolean": false
              },
              {
                "url": "http://saraalert.org/StructureDefinition/crew-on-passenger-or-cargo-flight",
                "valueBoolean": false
              }
            ],
            "url": "http://saraalert.org/StructureDefinition/exposure-risk-factors"
          },
          {
            "extension": [
              {
                "url": "source-of-report",
                "valueString": "Surveillance Screening"
              }
            ],
            "url": "http://saraalert.org/StructureDefinition/source-of-report"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/preferred-contact-method",
            "valueString": "E-mailed Web Link"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/symptom-onset-date",
            "valueDate": "2021-06-24"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/isolation",
            "valueBoolean": false
          },
          {
            "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
            "valueString": "USA, State 1"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/monitoring-plan",
            "valueString": "Daily active monitoring"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/assigned-user",
            "valuePositiveInt": 205610
          },
          {
            "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-start-date",
            "valueDate": "2021-06-24"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-end-date",
            "valueDate": "2021-06-25"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/port-of-origin",
            "valueString": "New Charleyhaven"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/port-of-entry-into-usa",
            "valueString": "South Anamaria"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/date-of-departure",
            "valueDate": "2021-06-23"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/flight-or-vessel-number",
            "valueString": "V595"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/flight-or-vessel-carrier",
            "valueString": "Clora Airlines"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/date-of-arrival",
            "valueDate": "2021-06-23"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/travel-related-notes",
            "valueString": "Pleasure in the job puts perfection in the work."
          },
          {
            "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-notes",
            "valueString": "Chuck Norris hosting is 101% uptime guaranteed."
          },
          {
            "url": "http://saraalert.org/StructureDefinition/continuous-exposure",
            "valueBoolean": true
          },
          {
            "url": "http://saraalert.org/StructureDefinition/end-of-monitoring",
            "valueString": "Continuous Exposure"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/exposure-risk-assessment",
            "valueString": "No Identified Risk"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/public-health-action",
            "valueString": "None"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/potential-exposure-location",
            "valueString": "Arronton"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/potential-exposure-country",
            "valueString": "Brazil"
          },
          {
            "url": "http://hl7.org/fhir/StructureDefinition/patient-interpreterRequired",
            "valueBoolean": false
          },
          {
            "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-destination",
            "valueString": "Pourosside"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-destination-state",
            "valueString": "District of Columbia"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-port-of-departure",
            "valueString": "New Natalia"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-type",
            "valueString": "Domestic"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/case-status",
            "valueString": "Confirmed"
          },
          {
            "url": "http://hl7.org/fhir/StructureDefinition/patient-genderIdentity",
            "valueCodeableConcept": {
              "coding": [
                {
                  "system": "http://hl7.org/fhir/gender-identity",
                  "code": "transgender-female"
                }
              ],
              "text": "Transgender Female (Male-to-Female [MTF])"
            }
          },
          {
            "url": "http://saraalert.org/StructureDefinition/head-of-household",
            "valueBoolean": true
          },
          {
            "url": "http://saraalert.org/StructureDefinition/id-of-reporter",
            "valuePositiveInt": 43
          },
          {
            "url": "http://saraalert.org/StructureDefinition/last-assessment-reminder-sent",
            "valueDateTime": "2021-06-20T04:00:00+00:00"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/paused-notifications",
            "valueBoolean": false
          },
          {
            "url": "http://saraalert.org/StructureDefinition/status",
            "valueString": "symptomatic"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/user-defined-symptom-onset",
            "valueBoolean": false
          }
        ],
        "identifier": [
          {
            "system": "http://saraalert.org/SaraAlert/cdc-id",
            "value": "0952379687"
          }
        ],
        "active": true,
        "name": [
          {
            "family": "Johns78",
            "given": ["Gerardo58", "Reinger57"]
          }
        ],
        "telecom": [
          {
            "system": "email",
            "value": "3822316898fake@example.com",
            "rank": 1
          }
        ],
        "birthDate": "1981-10-15",
        "address": [
          {
            "line": ["8181 Diana Lodge"],
            "district": "Royal Creek",
            "state": "New Jersey",
            "postalCode": "94336"
          },
          {
            "extension": [
              {
                "url": "http://saraalert.org/StructureDefinition/address-type",
                "valueString": "Monitored"
              }
            ],
            "line": ["8181 Diana Lodge"],
            "district": "Royal Creek",
            "state": "New Jersey",
            "postalCode": "94336"
          }
        ],
        "communication": [
          {
            "language": {
              "coding": [
                {
                  "system": "urn:ietf:bcp:47",
                  "code": "en",
                  "display": "English"
                }
              ]
            },
            "preferred": true
          },
          {
            "language": {
              "coding": [
                {
                  "system": "urn:ietf:bcp:47",
                  "code": "bho",
                  "display": "Bhojpuri"
                }
              ]
            },
            "preferred": false
          }
        ],
        "resourceType": "Patient"
      }
    }
  ],
  "resourceType": "Bundle"
}
```
  </div>
</details>

### GET `[base]/QuestionnaireResponse?subject=Patient/[:id]`
You can use search to find Monitoree daily reports by using the `subject` parameter.

<a name="search-questionnaire-subj"/>

GET `[base]/QuestionnaireResponse?subject=Patient/[:id]`

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "id": "1b4158ff-d68c-4bbc-b808-3a395cbaef3a",
  "meta": {
    "lastUpdated": "2021-07-22T15:22:46-04:00"
  },
  "type": "searchset",
  "total": 1,
  "entry": [
    {
      "fullUrl": "http://localhost:3000/fhir/r4/QuestionnaireResponse/1",
      "resource": {
        "id": 1,
        "meta": {
          "lastUpdated": "2021-06-27T20:51:51+00:00"
        },
        "extension": [
          {
            "url": "http://saraalert.org/StructureDefinition/symptomatic",
            "valueBoolean": false
          },
          {
            "url": "http://saraalert.org/StructureDefinition/created-at",
            "valueDateTime": "2021-06-23T13:34:09+00:00"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/who-reported",
            "valueString": "Monitoree"
          }
        ],
        "status": "completed",
        "subject": {
          "reference": "Patient/20"
        },
        "item": [
          {
            "linkId": "0",
            "text": "cough",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "1",
            "text": "difficulty-breathing",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "2",
            "text": "new-loss-of-smell",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "3",
            "text": "new-loss-of-taste",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "4",
            "text": "shortness-of-breath",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "5",
            "text": "fever",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "6",
            "text": "used-a-fever-reducer",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "7",
            "text": "chills",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "8",
            "text": "repeated-shaking-with-chills",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "9",
            "text": "muscle-pain",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "10",
            "text": "headache",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "11",
            "text": "sore-throat",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "12",
            "text": "nausea-or-vomiting",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "13",
            "text": "diarrhea",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "14",
            "text": "fatigue",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          },
          {
            "linkId": "15",
            "text": "congestion-or-runny-nose",
            "answer": [
              {
                "valueBoolean": false
              }
            ]
          }
        ],
        "resourceType": "QuestionnaireResponse"
      }
    }
  ],
  "resourceType": "Bundle"
}
```
  </div>
</details>

### GET `[base]/Observation?subject=Patient/[:id]`

You can also use search to find Monitoree laboratory results by using the `subject` parameter.

<a name="search-observation-subj"/>

GET `[base]/Observation?subject=Patient/[:id]`

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "id": "eb4abf5e-7c66-40be-875a-e42359202dc2",
  "meta": {
    "lastUpdated": "2021-07-22T15:19:00-04:00"
  },
  "type": "searchset",
  "total": 1,
  "entry": [
    {
      "fullUrl": "http://localhost:3000/fhir/r4/Observation/34",
      "resource": {
        "id": 34,
        "meta": {
          "lastUpdated": "2021-06-23T13:25:48+00:00"
        },
        "extension": [
          {
            "url": "http://saraalert.org/StructureDefinition/created-at",
            "valueDateTime": "2021-06-23T13:25:48+00:00"
          }
        ],
        "status": "final",
        "category": [
          {
            "coding": [
              {
                "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                "code": "laboratory"
              }
            ]
          }
        ],
        "code": {
          "coding": [
            {
              "system": "http://terminology.hl7.org/CodeSystem/v3-NullFlavor",
              "code": "OTH"
            }
          ],
          "text": "Other"
        },
        "subject": {
          "reference": "Patient/12"
        },
        "effectiveDateTime": "2021-06-19",
        "issued": "2021-06-23T00:00:00+00:00",
        "valueCodeableConcept": {
          "coding": [
            {
              "system": "http://snomed.info/sct",
              "code": "10828004"
            }
          ],
          "text": "positive"
        },
        "resourceType": "Observation"
      }
    }
  ],
  "resourceType": "Bundle"
}
```
  </div>
</details>

### GET `[base]/RelatedPerson?patient=Patient/[:id]`

You can also use search to find Monitoree close contacts by using the `patient` parameter.

<a name="search-related-patient"/>

GET `[base]/RelatedPerson?patient=Patient/[:id]`

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "id": "667f6d14-0abb-405e-8a28-04310bfae922",
  "meta": {
    "lastUpdated": "2021-07-22T15:15:40-04:00"
  },
  "type": "searchset",
  "total": 1,
  "entry": [
    {
      "fullUrl": "http://localhost:3000/fhir/r4/RelatedPerson/7",
      "resource": {
        "id": 7,
        "meta": {
          "lastUpdated": "2021-06-23T21:11:57+00:00"
        },
        "extension": [
          {
            "url": "http://saraalert.org/StructureDefinition/contact-attempts",
            "valueUnsignedInt": 2
          },
          {
            "url": "http://saraalert.org/StructureDefinition/notes",
            "valueString": "You can't back up the alarm without parsing the cross-platform SSL capacitor!"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/created-at",
            "valueDateTime": "2021-06-23T21:11:57+00:00"
          }
        ],
        "patient": {
          "reference": "Patient/9"
        },
        "name": [
          {
            "family": "Heller03",
            "given": ["Betsy81"]
          }
        ],
        "telecom": [
          {
            "system": "email",
            "value": "8089736791fake@example.com",
            "rank": 1
          }
        ],
        "resourceType": "RelatedPerson"
      }
    }
  ],
  "resourceType": "Bundle"
}
```
  </div>
</details>

### GET `[base]/Immunization?patient=Patient/[:id]`

You can also use search to find Monitoree vaccinations by using the `patient` parameter.

<a name="search-immunization-patient"/>

GET `[base]/Immunization?patient=Patient/[:id]`

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "id": "59a223a8-1724-4217-8c15-c02fdc3838ec",
  "meta": {
    "lastUpdated": "2021-07-22T15:17:16-04:00"
  },
  "type": "searchset",
  "total": 1,
  "entry": [
    {
      "fullUrl": "http://localhost:3000/fhir/r4/Immunization/1",
      "resource": {
        "id": 1,
        "meta": {
          "lastUpdated": "2021-06-23T10:40:04+00:00"
        },
        "extension": [
          {
            "url": "http://saraalert.org/StructureDefinition/created-at",
            "valueDateTime": "2021-06-23T10:40:04+00:00"
          }
        ],
        "status": "completed",
        "vaccineCode": [
          {
            "coding": [
              {
                "system": "http://hl7.org/fhir/sid/cvx",
                "code": "212"
              }
            ],
            "text": "Janssen (J&J) COVID-19 Vaccine"
          }
        ],
        "patient": {
          "reference": "Patient/6"
        },
        "occurrenceDateTime": "2021-06-19",
        "note": [
          {
            "text": "Defy Noxus and taste your own blood."
          }
        ],
        "protocolApplied": [
          {
            "targetDisease": [
              {
                "coding": [
                  {
                    "system": "http://hl7.org/fhir/sid/cvx",
                    "code": "213"
                  }
                ],
                "text": "COVID-19"
              }
            ]
          }
        ],
        "resourceType": "Immunization"
      }
    }
  ],
  "resourceType": "Bundle"
}
```
  </div>
</details>

### GET `[base]/Provenance?patient=Patient/[:id]`

You can also use search to find Monitoree histories by using the `patient` parameter.

<a name="search-history-patient"/>

GET `[base]/Provenance?patient=Patient/[:id]`

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "id": "6004987d-775b-4d4b-9f9a-7c19bd432e4a",
  "meta": {
    "lastUpdated": "2021-07-22T15:20:57-04:00"
  },
  "type": "searchset",
  "total": 1,
  "entry": [
    {
      "fullUrl": "http://localhost:3000/fhir/r4/Provenance/326",
      "resource": {
        "id": 326,
        "meta": {
          "lastUpdated": "2021-06-24T23:17:02+00:00"
        },
        "extension": [
          {
            "url": "http://saraalert.org/StructureDefinition/comment",
            "valueString": "User enrolled monitoree."
          },
          {
            "url": "http://saraalert.org/StructureDefinition/history-type",
            "valueString": "Enrollment"
          }
        ],
        "target": [
          {
            "reference": "Patient/82"
          }
        ],
        "recorded": "2021-06-24T23:17:02+00:00",
        "agent": [
          {
            "who": {
              "identifier": {
                "value": "state2_enroller@example.com"
              }
            },
            "onBehalfOf": {
              "reference": "Patient/82"
            }
          }
        ],
        "resourceType": "Provenance"
      }
    }
  ],
  "resourceType": "Bundle"
}
```
  </div>
</details>

### GET `[base]/Patient`

By not specifying any search parameters, you can request all resources of the specified type.

<a name="search-all"/>

GET `[base]/Patient?_count=2`

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "id": "e4d8973c-2e50-4416-84e0-6c4930048654",
  "meta": {
    "lastUpdated": "2021-07-22T15:12:34-04:00"
  },
  "type": "searchset",
  "total": 1048,
  "link": [
    {
      "relation": "next",
      "url": "http://localhost:3000/fhir/r4/Patient?_count=2&page=2"
    },
    {
      "relation": "last",
      "url": "http://localhost:3000/fhir/r4/Patient?_count=2&page=524"
    }
  ],
  "entry": [
    {
      "fullUrl": "http://localhost:3000/fhir/r4/Patient/1",
      "resource": {
        "id": 1,
        "meta": {
          "lastUpdated": "2021-07-20T21:53:24+00:00"
        },
        "contained": [
          {
            "target": [
              {
                "reference": "/fhir/r4/Patient/1"
              }
            ],
            "recorded": "2021-06-22T21:47:14+00:00",
            "activity": {
              "coding": [
                {
                  "system": "http://terminology.hl7.org/CodeSystem/v3-DataOperation",
                  "code": "CREATE",
                  "display": "create"
                }
              ]
            },
            "agent": [
              {
                "who": {
                  "identifier": {
                    "value": 6
                  },
                  "display": "locals2c4_enroller@example.com"
                }
              }
            ],
            "resourceType": "Provenance"
          }
        ],
        "extension": [
          {
            "extension": [
              {
                "url": "http://hl7.org/fhir/StructureDefinition/data-absent-reason",
                "valueCode": "asked-declined"
              },
              {
                "url": "text",
                "valueString": "Refused to Answer"
              }
            ],
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race"
          },
          {
            "extension": [
              {
                "url": "ombCategory",
                "valueCoding": {
                  "system": "urn:oid:2.16.840.1.113883.6.238",
                  "code": "2135-2",
                  "display": "Hispanic or Latino"
                }
              },
              {
                "url": "text",
                "valueString": "Hispanic or Latino"
              }
            ],
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity"
          },
          {
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex",
            "valueCode": "F"
          },
          {
            "extension": [
              {
                "url": "id",
                "valuePositiveInt": 30
              },
              {
                "url": "updated-at",
                "valueDateTime": "2021-06-27T12:35:55+00:00"
              },
              {
                "url": "created-at",
                "valueDateTime": "2021-06-27T12:35:55+00:00"
              },
              {
                "url": "who-initiated-transfer",
                "valueString": "locals2c4_epi@example.com"
              },
              {
                "url": "from-jurisdiction",
                "valueString": "USA, State 2"
              },
              {
                "url": "to-jurisdiction",
                "valueString": "USA, State 1"
              }
            ],
            "url": "http://saraalert.org/StructureDefinition/transfer"
          },
          {
            "extension": [
              {
                "extension": [
                  {
                    "url": "contact-of-known-case",
                    "valueBoolean": true
                  },
                  {
                    "url": "contact-of-known-case-id",
                    "valueString": "08716266, 07336309"
                  }
                ],
                "url": "http://saraalert.org/StructureDefinition/contact-of-known-case"
              },
              {
                "extension": [
                  {
                    "url": "was-in-health-care-facility-with-known-cases",
                    "valueBoolean": true
                  }
                ],
                "url": "http://saraalert.org/StructureDefinition/was-in-health-care-facility-with-known-cases"
              },
              {
                "extension": [
                  {
                    "url": "laboratory-personnel",
                    "valueBoolean": false
                  }
                ],
                "url": "http://saraalert.org/StructureDefinition/laboratory-personnel"
              },
              {
                "extension": [
                  {
                    "url": "healthcare-personnel",
                    "valueBoolean": false
                  }
                ],
                "url": "http://saraalert.org/StructureDefinition/healthcare-personnel"
              },
              {
                "extension": [
                  {
                    "url": "member-of-a-common-exposure-cohort",
                    "valueBoolean": false
                  }
                ],
                "url": "http://saraalert.org/StructureDefinition/member-of-a-common-exposure-cohort"
              },
              {
                "url": "http://saraalert.org/StructureDefinition/travel-from-affected-country-or-area",
                "valueBoolean": false
              },
              {
                "url": "http://saraalert.org/StructureDefinition/crew-on-passenger-or-cargo-flight",
                "valueBoolean": false
              }
            ],
            "url": "http://saraalert.org/StructureDefinition/exposure-risk-factors"
          },
          {
            "extension": [
              {
                "url": "source-of-report",
                "valueString": "Other"
              },
              {
                "url": "specify",
                "valueString": "Audacious"
              }
            ],
            "url": "http://saraalert.org/StructureDefinition/source-of-report"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/preferred-contact-method",
            "valueString": "Telephone call"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/preferred-contact-time",
            "valueString": "Evening"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/isolation",
            "valueBoolean": true
          },
          {
            "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
            "valueString": "USA, State 2"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/assigned-user",
            "valuePositiveInt": 976134
          },
          {
            "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-start-date",
            "valueDate": "2021-06-26"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-end-date",
            "valueDate": "2021-06-27"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/port-of-origin",
            "valueString": "Eufemiamouth"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/port-of-entry-into-usa",
            "valueString": "Murazikfurt"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/date-of-departure",
            "valueDate": "2021-06-22"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/flight-or-vessel-number",
            "valueString": "H420"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/flight-or-vessel-carrier",
            "valueString": "Frances Airlines"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/date-of-arrival",
            "valueDate": "2021-06-22"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/travel-related-notes",
            "valueString": "The mind is not a vessel to be filled but a fire to be kindled."
          },
          {
            "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-notes",
            "valueString": "Chuck Norris' beard is immutable."
          },
          {
            "url": "http://saraalert.org/StructureDefinition/continuous-exposure",
            "valueBoolean": false
          },
          {
            "url": "http://saraalert.org/StructureDefinition/end-of-monitoring",
            "valueString": "2021-07-06"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/exposure-risk-assessment",
            "valueString": "High"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/public-health-action",
            "valueString": "None"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/potential-exposure-location",
            "valueString": "Huelville"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/potential-exposure-country",
            "valueString": "United Arab Emirates"
          },
          {
            "url": "http://hl7.org/fhir/StructureDefinition/patient-interpreterRequired",
            "valueBoolean": false
          },
          {
            "url": "http://saraalert.org/StructureDefinition/follow-up-reason",
            "valueString": "Deceased"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-destination",
            "valueString": "West Raymundo"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-destination-country",
            "valueString": "Marshall Islands"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-port-of-departure",
            "valueString": "Gradychester"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/additional-planned-travel-type",
            "valueString": "International"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/case-status",
            "valueString": "Probable"
          },
          {
            "url": "http://hl7.org/fhir/StructureDefinition/patient-genderIdentity",
            "valueCodeableConcept": {
              "coding": [
                {
                  "system": "http://hl7.org/fhir/gender-identity",
                  "code": "transgender-female"
                }
              ],
              "text": "Transgender Female (Male-to-Female [MTF])"
            }
          },
          {
            "url": "http://saraalert.org/StructureDefinition/sexual-orientation",
            "valueCodeableConcept": {
              "coding": [
                {
                  "system": "http://snomed.info/sct",
                  "code": "38628009"
                }
              ],
              "text": "Lesbian, Gay, or Homosexual"
            }
          },
          {
            "url": "http://saraalert.org/StructureDefinition/id-of-reporter",
            "valuePositiveInt": 1
          },
          {
            "url": "http://saraalert.org/StructureDefinition/paused-notifications",
            "valueBoolean": false
          },
          {
            "url": "http://saraalert.org/StructureDefinition/status",
            "valueString": "asymp non test based"
          }
        ],
        "identifier": [
          {
            "system": "http://saraalert.org/SaraAlert/state-local-id",
            "value": "EX-773460"
          }
        ],
        "active": true,
        "name": [
          {
            "family": "McCullough24",
            "given": ["Eulah20"]
          }
        ],
        "telecom": [
          {
            "system": "phone",
            "value": "+15555550162",
            "rank": 1
          }
        ],
        "birthDate": "1969-09-19",
        "address": [
          {
            "extension": [
              {
                "url": "http://saraalert.org/StructureDefinition/address-type",
                "valueString": "Foreign"
              }
            ],
            "line": ["2224 Jerrod Extension", "Suite 257"],
            "city": "Bishkek",
            "postalCode": "03602-0784",
            "country": "Hungary"
          },
          {
            "extension": [
              {
                "url": "http://saraalert.org/StructureDefinition/address-type",
                "valueString": "ForeignMonitored"
              }
            ],
            "line": ["97299 Schroeder Loop"],
            "city": "Praia Bangui",
            "district": "Vernon",
            "state": "Wisconsin",
            "postalCode": "72075"
          }
        ],
        "communication": [
          {
            "language": {
              "coding": [
                {
                  "system": "urn:ietf:bcp:47",
                  "code": "en",
                  "display": "English"
                }
              ]
            },
            "preferred": true
          }
        ],
        "resourceType": "Patient"
      }
    },
    {
      "fullUrl": "http://localhost:3000/fhir/r4/Patient/2",
      "resource": {
        "id": 2,
        "meta": {
          "lastUpdated": "2021-07-06T16:10:55+00:00"
        },
        "contained": [
          {
            "target": [
              {
                "reference": "/fhir/r4/Patient/2"
              }
            ],
            "recorded": "2021-06-22T22:24:58+00:00",
            "activity": {
              "coding": [
                {
                  "system": "http://terminology.hl7.org/CodeSystem/v3-DataOperation",
                  "code": "CREATE",
                  "display": "create"
                }
              ]
            },
            "agent": [
              {
                "who": {
                  "identifier": {
                    "value": 5
                  },
                  "display": "locals2c3_enroller@example.com"
                }
              }
            ],
            "resourceType": "Provenance"
          }
        ],
        "extension": [
          {
            "extension": [
              {
                "url": "http://hl7.org/fhir/StructureDefinition/data-absent-reason",
                "valueCode": "asked-declined"
              },
              {
                "url": "text",
                "valueString": "Refused to Answer"
              }
            ],
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race"
          },
          {
            "extension": [
              {
                "url": "ombCategory",
                "valueCoding": {
                  "system": "urn:oid:2.16.840.1.113883.6.238",
                  "code": "2186-5",
                  "display": "Not Hispanic or Latino"
                }
              },
              {
                "url": "text",
                "valueString": "Not Hispanic or Latino"
              }
            ],
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity"
          },
          {
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex",
            "valueCode": "UNK"
          },
          {
            "extension": [
              {
                "url": "id",
                "valuePositiveInt": 186
              },
              {
                "url": "updated-at",
                "valueDateTime": "2021-07-04T02:04:33+00:00"
              },
              {
                "url": "created-at",
                "valueDateTime": "2021-07-04T02:04:33+00:00"
              },
              {
                "url": "who-initiated-transfer",
                "valueString": "locals2c3_epi@example.com"
              },
              {
                "url": "from-jurisdiction",
                "valueString": "USA"
              },
              {
                "url": "to-jurisdiction",
                "valueString": "USA, State 1, County 1"
              }
            ],
            "url": "http://saraalert.org/StructureDefinition/transfer"
          },
          {
            "extension": [
              {
                "extension": [
                  {
                    "url": "contact-of-known-case",
                    "valueBoolean": false
                  }
                ],
                "url": "http://saraalert.org/StructureDefinition/contact-of-known-case"
              },
              {
                "extension": [
                  {
                    "url": "was-in-health-care-facility-with-known-cases",
                    "valueBoolean": false
                  }
                ],
                "url": "http://saraalert.org/StructureDefinition/was-in-health-care-facility-with-known-cases"
              },
              {
                "extension": [
                  {
                    "url": "laboratory-personnel",
                    "valueBoolean": false
                  }
                ],
                "url": "http://saraalert.org/StructureDefinition/laboratory-personnel"
              },
              {
                "extension": [
                  {
                    "url": "healthcare-personnel",
                    "valueBoolean": false
                  }
                ],
                "url": "http://saraalert.org/StructureDefinition/healthcare-personnel"
              },
              {
                "extension": [
                  {
                    "url": "member-of-a-common-exposure-cohort",
                    "valueBoolean": false
                  }
                ],
                "url": "http://saraalert.org/StructureDefinition/member-of-a-common-exposure-cohort"
              },
              {
                "url": "http://saraalert.org/StructureDefinition/travel-from-affected-country-or-area",
                "valueBoolean": false
              },
              {
                "url": "http://saraalert.org/StructureDefinition/crew-on-passenger-or-cargo-flight",
                "valueBoolean": false
              }
            ],
            "url": "http://saraalert.org/StructureDefinition/exposure-risk-factors"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/preferred-contact-time",
            "valueString": "Afternoon"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/symptom-onset-date",
            "valueDate": "2021-07-03"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/isolation",
            "valueBoolean": true
          },
          {
            "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
            "valueString": "USA, State 1, County 1"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/assigned-user",
            "valuePositiveInt": 232046
          },
          {
            "url": "http://saraalert.org/StructureDefinition/port-of-origin",
            "valueString": "North Pearliechester"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/port-of-entry-into-usa",
            "valueString": "Januaryfurt"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/date-of-departure",
            "valueDate": "2021-06-22"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/flight-or-vessel-number",
            "valueString": "I280"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/flight-or-vessel-carrier",
            "valueString": "Emery Airlines"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/date-of-arrival",
            "valueDate": "2021-06-22"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/exposure-notes",
            "valueString": "Tonight we hunt!"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/travel-related-notes",
            "valueString": "Most people would rather give than get affection."
          },
          {
            "url": "http://saraalert.org/StructureDefinition/continuous-exposure",
            "valueBoolean": false
          },
          {
            "url": "http://saraalert.org/StructureDefinition/end-of-monitoring",
            "valueString": "2021-07-06"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/exposure-risk-assessment",
            "valueString": "Low"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/public-health-action",
            "valueString": "None"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/potential-exposure-location",
            "valueString": "Port Edisonberg"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/potential-exposure-country",
            "valueString": "Guinea"
          },
          {
            "url": "http://hl7.org/fhir/StructureDefinition/patient-interpreterRequired",
            "valueBoolean": false
          },
          {
            "url": "http://saraalert.org/StructureDefinition/follow-up-reason",
            "valueString": "In Need of Follow-up"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/follow-up-note",
            "valueString": "Most people would rather give than get affection."
          },
          {
            "url": "http://saraalert.org/StructureDefinition/case-status",
            "valueString": "Confirmed"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/sexual-orientation",
            "valueCodeableConcept": {
              "coding": [
                {
                  "system": "http://snomed.info/sct",
                  "code": "38628009"
                }
              ],
              "text": "Lesbian, Gay, or Homosexual"
            }
          },
          {
            "url": "http://saraalert.org/StructureDefinition/id-of-reporter",
            "valuePositiveInt": 2
          },
          {
            "url": "http://saraalert.org/StructureDefinition/paused-notifications",
            "valueBoolean": false
          },
          {
            "url": "http://saraalert.org/StructureDefinition/status",
            "valueString": "symp non test based"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/user-defined-symptom-onset",
            "valueBoolean": true
          }
        ],
        "identifier": [
          {
            "system": "http://saraalert.org/SaraAlert/state-local-id",
            "value": "EX-066922"
          }
        ],
        "active": true,
        "name": [
          {
            "family": "Konopelski65",
            "given": ["Kirby47", "Batz46"]
          }
        ],
        "telecom": [
          {
            "extension": [
              {
                "url": "http://saraalert.org/StructureDefinition/phone-type",
                "valueString": "Plain Cell"
              }
            ],
            "system": "phone",
            "value": "+15555550172",
            "rank": 1
          },
          {
            "system": "phone",
            "value": "+15555550182",
            "rank": 2
          }
        ],
        "birthDate": "2008-09-12",
        "address": [
          {
            "line": ["78342 Howell View"],
            "city": "Wildermanmouth",
            "district": "Paradise Place",
            "state": "Vermont",
            "postalCode": "58562"
          },
          {
            "extension": [
              {
                "url": "http://saraalert.org/StructureDefinition/address-type",
                "valueString": "Monitored"
              }
            ],
            "line": ["78342 Howell View"],
            "city": "Wildermanmouth",
            "district": "Paradise Place",
            "state": "Vermont",
            "postalCode": "58562"
          }
        ],
        "communication": [
          {
            "language": {
              "coding": [
                {
                  "system": "urn:ietf:bcp:47",
                  "code": "en",
                  "display": "English"
                }
              ]
            },
            "preferred": true
          }
        ],
        "resourceType": "Patient"
      }
    }
  ],
  "resourceType": "Bundle"
}
```
  </div>
</details>

## Transactions
The API supports performing several actions as a single atomic "transaction" for which all of the individual changes succeed or fail together.

<a name="transaction-post"/>

### POST `[base]`
To perform a transaction, POST a FHIR [Bundle](https://www.hl7.org/fhir/bundle.html) resource to `[base]`. The Bundle must have `Bundle.type` set to `transaction`. There is a limit of 50 resources per transaction. Currently a transaction may only be used to create monitorees and lab results via the FHIR Patient and Observations resources, respectively. The transaction does not need to include Observation resources, and can be used to enroll monitorees in bulk. If a transaction is used to create an Observation, that Observation must reference a Patient being created by the same transaction. The transaction Bundle can contain at most 50 elements in the `Bundle.entry` array. Each entry in the `Bundle.entry` array should contain the following fields:

* `fullUrl` - Must be an identifier for the resource. Since the resources are being created, they do not have a server assigned ID yet. To uniquely identify a resource, generate a UUID, for example: `urn:uuid:9c94a2bc-1929-4666-8099-9e8566b7d9ad`. An Observation should use the `fullUrl` of its corresponding Patient in `Observation.subject.reference`.
* `resource` - Must contain the content of the Observation or Patient that is being created.
* `request.method` - Must be `POST` as this is the only supported operation.
* `request.url` - Must be `Patient` or `Observation`, depending on which resource is being created.

See the FHIR [transaction](https://www.hl7.org/fhir/http.html#transaction) documentation for more details. An example request and response is shown below.

**Request Body:**

<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "resourceType": "Bundle",
  "type": "transaction",
  "entry": [
    {
      "fullUrl": "urn:uuid:17b6896d-9fd1-437f-a7bd-6ef7a66116ab",
      "request": {
        "method": "POST",
        "url": "Observation"
      },
      "resource": {
        "status": "final",
        "category": [
          {
            "coding": [
              {
                "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                "code": "laboratory"
              }
            ]
          }
        ],
        "code": {
          "coding": [
            {
              "system": "http://loinc.org",
              "code": "94564-2"
            }
          ],
          "text": "IgM Antibody"
        },
        "valueCodeableConcept": {
          "coding": [
            {
              "system": "http://snomed.info/sct",
              "code": "10828004"
            }
          ]
        },
        "subject": {
          "reference": "urn:uuid:9c94a2bc-1929-4666-8099-9e8566b7d9ad"
        },
        "effectiveDateTime": "2021-05-06",
        "issued": "2021-05-07T00:00:00+00:00",
        "resourceType": "Observation"
      }
    },
    {
      "fullUrl": "urn:uuid:9c94a2bc-1929-4666-8099-9e8566b7d9ad",
      "request": {
        "method": "POST",
        "url": "Patient"
      },
      "resource": {
        "extension": [
          {
            "extension": [
              {
                "url": "ombCategory",
                "valueCoding": {
                  "system": "urn:oid:2.16.840.1.113883.6.238",
                  "code": "2054-5",
                  "display": "Black or African American"
                }
              },
              {
                "url": "text",
                "valueString": "Black or African American"
              }
            ],
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race"
          },
          {
            "extension": [
              {
                "url": "ombCategory",
                "valueCoding": {
                  "system": "urn:oid:2.16.840.1.113883.6.238",
                  "code": "2186-5",
                  "display": "Not Hispanic or Latino"
                }
              },
              {
                "url": "text",
                "valueString": "Not Hispanic or Latino"
              }
            ],
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity"
          },
          {
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex",
            "valueCode": "M"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/preferred-contact-method",
            "valueString": "Telephone call"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/last-date-of-exposure",
            "valueDate": "2020-05-18"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/isolation",
            "valueBoolean": true
          },
          {
            "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
            "valueString": "USA, State 1"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/continuous-exposure",
            "valueBoolean": false
          }
        ],
        "active": true,
        "name": [
          {
            "family": "Smith82",
            "given": ["Malcolm94", "Bogan39"]
          }
        ],
        "telecom": [
          {
            "system": "phone",
            "value": "+13333333333",
            "rank": 1
          },
          {
            "system": "phone",
            "value": "+13333333333",
            "rank": 2
          },
          {
            "system": "email",
            "value": "22222222323222@example.com",
            "rank": 1
          }
        ],
        "birthDate": "1981-03-30",
        "address": [
          {
            "line": ["22424 Daphne Key"],
            "city": "West Gabrielmouth",
            "state": "Maine",
            "postalCode": "24683"
          }
        ],
        "communication": [
          {
            "language": {
              "coding": [
                {
                  "system": "urn:ietf:bcp:47",
                  "display": "eng"
                }
              ]
            }
          }
        ],
        "resourceType": "Patient"
      }
    }
  ]
}
```
  </div>
</details>

**Response:**


<details>
  <summary>Click to expand JSON snippet</summary>
  <div markdown="1">

```json
{
  "id": "ea19333b-2b23-4150-be6d-5c666e8f4414",
  "meta": {
    "lastUpdated": "2021-05-07T14:03:24-04:00"
  },
  "type": "transaction-response",
  "entry": [
    {
      "fullUrl": "http://localhost:3000/fhir/r4/Patient/30",
      "resource": {
        "id": 30,
        "meta": {
          "lastUpdated": "2021-05-07T18:03:24+00:00"
        },
        "contained": [
          {
            "target": [
              {
                "reference": "/fhir/r4/Patient/30"
              }
            ],
            "recorded": "2021-05-07T18:03:24+00:00",
            "activity": {
              "coding": [
                {
                  "system": "http://terminology.hl7.org/CodeSystem/v3-DataOperation",
                  "code": "CREATE",
                  "display": "create"
                }
              ]
            },
            "agent": [
              {
                "who": {
                  "identifier": {
                    "value": "ogsaC3PrRzsMZYa1LOXRdu6eJaCc7yWJViGudzNNHBc"
                  },
                  "display": "test-m2m-app"
                }
              }
            ],
            "resourceType": "Provenance"
          }
        ],
        "extension": [
          {
            "extension": [
              {
                "url": "ombCategory",
                "valueCoding": {
                  "system": "urn:oid:2.16.840.1.113883.6.238",
                  "code": "2054-5",
                  "display": "Black or African American"
                }
              },
              {
                "url": "text",
                "valueString": "Black or African American"
              }
            ],
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race"
          },
          {
            "extension": [
              {
                "url": "ombCategory",
                "valueCoding": {
                  "system": "urn:oid:2.16.840.1.113883.6.238",
                  "code": "2186-5",
                  "display": "Not Hispanic or Latino"
                }
              },
              {
                "url": "text",
                "valueString": "Not Hispanic or Latino"
              }
            ],
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity"
          },
          {
            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex",
            "valueCode": "M"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/preferred-contact-method",
            "valueString": "Telephone call"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/last-date-of-exposure",
            "valueDate": "2020-05-18"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/isolation",
            "valueBoolean": true
          },
          {
            "url": "http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path",
            "valueString": "USA, State 1"
          },
          {
            "url": "http://saraalert.org/StructureDefinition/continuous-exposure",
            "valueBoolean": false
          }
        ],
        "active": true,
        "name": [
          {
            "family": "Smith82",
            "given": ["Malcolm94", "Bogan39"]
          }
        ],
        "telecom": [
          {
            "system": "phone",
            "value": "+13333333333",
            "rank": 1
          },
          {
            "system": "phone",
            "value": "+13333333333",
            "rank": 2
          },
          {
            "system": "email",
            "value": "22222222323222@example.com",
            "rank": 1
          }
        ],
        "birthDate": "1981-03-30",
        "address": [
          {
            "line": ["22424 Daphne Key"],
            "city": "West Gabrielmouth",
            "state": "Maine",
            "postalCode": "24683"
          }
        ],
        "communication": [
          {
            "language": {
              "coding": [
                {
                  "system": "urn:ietf:bcp:47",
                  "code": "en",
                  "display": "English"
                }
              ]
            }
          }
        ],
        "resourceType": "Patient"
      },
      "response": {
        "status": "201 Created"
      }
    },
    {
      "fullUrl": "http://localhost:3000/fhir/r4/Observation/36",
      "resource": {
        "id": 36,
        "meta": {
          "lastUpdated": "2021-05-07T18:03:24+00:00"
        },
        "status": "final",
        "category": [
          {
            "coding": [
              {
                "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                "code": "laboratory"
              }
            ]
          }
        ],
        "code": {
          "coding": [
            {
              "system": "http://loinc.org",
              "code": "94564-2"
            }
          ],
          "text": "IgM Antibody"
        },
        "subject": {
          "reference": "Patient/30"
        },
        "effectiveDateTime": "2021-05-06",
        "issued": "2021-05-07T00:00:00+00:00",
        "valueCodeableConcept": {
          "coding": [
            {
              "system": "http://snomed.info/sct",
              "code": "10828004"
            }
          ],
          "text": "positive"
        },
        "resourceType": "Observation"
      },
      "response": {
        "status": "201 Created"
      }
    }
  ],
  "resourceType": "Bundle"
}
```
  </div>
</details>


## Bulk Data Export
The API supports exporting monitoree data in bulk according the the [FHIR Bulk Data Access](https://hl7.org/fhir/uv/bulkdata/export/index.html) specification. Instead of making individual requests to gather information, bulk data export supports exporting all available monitoree data at once. The bulk data request flow includes a kick-off request, status requests, and file requests, all of which are described in subsequent sections. This documentation focuses on how bulk data export works in Sara Alert, and for details not included here, please see the
[specification](https://hl7.org/fhir/uv/bulkdata/export/index.html).
<a name="bulk-data-kick-off"/>

### Kick-off Request - GET `[base]/Patient/$export`
This request begins the asynchronous generation of bulk data. The generated bulk data will include all monitorees for which the client has access, along with the lab results, daily reports, close contacts, immunizations, and history items of those monitorees. Since the client is requesting access to all this data, they must have the correct read scopes for Patient, Observation, QuestionnaireResponse, RelatedPerson, Immunization, and Provenance. A client can begin one bulk data export every 15 minutes. Additionally, kicking off a new request will delete the content of old requests, so a new request should not be started until the content of an old request is no longer needed.

#### Request Headers
* The `Accept` header must be set to `application/fhir+json`.
* The `Prefer` header must be set to `respond-async`.

#### Parameters
* The API supports only the `_since` parameter. If this parameter is specified, only resources for which `meta.lastUpdated` is later than the `_since` time will be included in the response. This parameter should have a [FHIR instant](https://www.hl7.org/fhir/datatypes.html#instant) as its value.
  * **Example:** Get only resources changed since 2021 began: `[base]/Patient/$export?_since=2021-01-01T00:00:00Z`

#### Response on Success
* `202 Accepted` status
* The `Content-Location` header will contain a URL of the form `[base]/ExportStatus/[:id]` which can be used to request the status of the bulk data export.

#### Response on Error
* Error status
  * `403 Forbidden` - The client does not have access to all of the required read scopes, or there is some other issue with their token.
  * `406 Not Acceptable` - Incorrect value for `Accept` header.
  * `422 Unprocessable Entity` - Incorrect format for `_since` parameter, or incorrect value for `Prefer` header.
  * `401 Unauthorized` - The client's API application is not registered for us in the backend services workflow.
  * `429 Too Many Requests` - The client already initiated an export within the last 15 minutes.
* The body of the response will include a FHIR OperationOutcome with an error message indicating the issue.


<a name="bulk-data-status">

### Status Request - GET `[base]/ExportStatus/[:id]`
After a bulk data request has successfully started, the client can use the polling URL returned in the `Content-Location` header of the response to the kick-off request. The `[:id]` in this URL uniquely identifies the client's request. The response will indicate the current status of the export.

#### In Progress
If the generation of data is still in progress, the export will return a `202 Accepted` status.

#### Error
If an error prevents the bulk data export for completing, a `500 Internal Server Error` will indicate this.

#### Complete
Once the export is complete, the status request will return a `200 OK` response. The body of the response will follow the JSON format described in [section 5.3.4](https://hl7.org/fhir/uv/bulkdata/export/index.html#response---complete-status) of the bulk data access specification. An example response is shown below:

```json
{
    "transactionTime": "2021-07-07T21:08:19+00:00",
    "request": "https://demo.saraalert.org/fhir/r4/Patient/$export?_since=2021-07-05T12:02:02Z",
    "requiresAccessToken": true,
    "output": [
        {
            "type": "Patient",
            "url": "https://demo.saraalert.org/fhir/r4/ExportFiles/60/Patient.ndjson"
        },
        {
            "type": "QuestionnaireResponse",
            "url": "https://demo.saraalert.org/fhir/r4/ExportFiles/60/QuestionnaireResponse.ndjson"
        },
        {
            "type": "Provenance",
            "url": "https://demo.saraalert.org/fhir/r4/ExportFiles/60/Provenance.ndjson"
        },
        {
            "type": "Observation",
            "url": "https://demo.saraalert.org/fhir/r4/ExportFiles/60/Observation.ndjson"
        },
        {
            "type": "Immunization",
            "url": "https://demo.saraalert.org/fhir/r4/ExportFiles/60/Immunization.ndjson"
        },
        {
            "type": "RelatedPerson",
            "url": "https://demo.saraalert.org/fhir/r4/ExportFiles/60/RelatedPerson.ndjson"
        }
    ]
}
```
The `url` values listed on each element of the `output` array can be used to access the generated exports.


<a name="bulk-data-files">

### File Request - GET `[base]/ExportFiles/[:id]/[:filename]`
Once a client's export is complete, the completed files will be available at this endpoint, where the `[:id]` is the same unique identifier used in the status requests, and the `[:filename]` is of the form `<resourceType>.ndjson`. A valid authorization token with read access to the type of resource being requested is required.

#### Response on Success
The response will have a `200 OK` status, and the body will include the requested resources as a [newline delimited JSON](http://ndjson.org/) file. The example below shows the format of an ndjson file:
```
{"id":1,"name":[{"family":"McCullough24","given":["Eulah20"]}],"resourceType":"Patient"}
{"id":4,"name":[{"family":"Konopelski65","given":["Kirby47"]}],"resourceType":"Patient"}
{"id":6,"name":[{"family":"Herman26","given":["Barton43"]}],"resourceType":"Patient"}
```
Note that the Patients shown in this example are not valid Sara Alert Patients, most elements have been removed for brevity.

#### Response on Error
The response will have a `404 Not Found` status, indicating that either the `[:filename]` parameter does not correspond to a supported FHIR Resource, or that no file of the type indicated by `[:filename]` exists for that `[:id]`.
